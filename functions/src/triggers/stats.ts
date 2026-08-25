import {
  onDocumentCreated,
  onDocumentDeleted,
  onDocumentUpdated,
} from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { sendNotification, writeInbox, getUser } from '../utils/notifications';
import { tn } from '../i18n/notifications';

/// Clamps a counter to `>= 0` after applying a delta, tolerating a missing or
/// non-numeric current value. Pure so the floor behaviour can be unit-tested.
export function flooredCount(current: unknown, delta: number): number {
  const n = typeof current === 'number' && Number.isFinite(current) ? current : 0;
  return Math.max(0, n + delta);
}

/// Nanny aggregate stats (`nannies/{id}.stats.*`) are read on the nanny
/// dashboard but must be **server-owned**: the security rules only let a nanny
/// (or admin) write her own doc, so a family shortlisting a nanny cannot touch
/// the nanny's stats from the client. These triggers maintain the counters in
/// response to the family-owned `shortlists/{id}` docs the family *is* allowed
/// to write.

export const onShortlistCreated = onDocumentCreated('shortlists/{shortlistId}', async (event) => {
  const nannyId = event.data?.data()?.nannyId as string | undefined;
  if (!nannyId) return;
  await admin
    .firestore()
    .collection('nannies')
    .doc(nannyId)
    .set({ stats: { shortlists: admin.firestore.FieldValue.increment(1) } }, { merge: true });
});

export const onShortlistDeleted = onDocumentDeleted('shortlists/{shortlistId}', async (event) => {
  const nannyId = event.data?.data()?.nannyId as string | undefined;
  if (!nannyId) return;
  const ref = admin.firestore().collection('nannies').doc(nannyId);
  // Floor at 0 via a transaction so out-of-order events can't drive it negative.
  await admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const current = (snap.data()?.stats as { shortlists?: unknown } | undefined)?.shortlists;
    tx.set(ref, { stats: { shortlists: flooredCount(current, -1) } }, { merge: true });
  });
});

/// A family records a profile view by creating `profileViews/{familyId}_{nannyId}`
/// (deterministic id → one event per pair). The family can't write its own
/// `viewedProfiles`/`freeContactsUsed` or the nanny's stats (security rules), so
/// this trigger owns both: it burns a free contact only the FIRST time a family
/// views a given nanny, and bumps the nanny's server-owned profileViews stat.
export const onProfileViewed = onDocumentCreated('profileViews/{viewId}', async (event) => {
  const view = event.data?.data();
  const familyId = view?.familyId as string | undefined;
  const nannyId = view?.nannyId as string | undefined;
  if (!familyId || !nannyId) return;
  const db = admin.firestore();

  // Family free-contact accounting — only new views count.
  let isNew = false;
  await db.runTransaction(async (tx) => {
    const ref = db.collection('families').doc(familyId);
    const snap = await tx.get(ref);
    const viewed: string[] = Array.isArray(snap.data()?.viewedProfiles)
      ? (snap.data()!.viewedProfiles as string[])
      : [];
    if (viewed.includes(nannyId)) return;
    isNew = true;
    viewed.push(nannyId);
    tx.set(
      ref,
      { viewedProfiles: viewed, freeContactsUsed: admin.firestore.FieldValue.increment(1) },
      { merge: true },
    );
  });

  if (!isNew) return;
  await db
    .collection('nannies')
    .doc(nannyId)
    .set({ stats: { profileViews: admin.firestore.FieldValue.increment(1) } }, { merge: true });
});

/// A family creates `hires/{hireId}` when it hires a nanny. The rules forbid
/// the family from writing the nanny's doc, so this trigger owns the nanny's
/// server-side `stats.hiresCount`. It also notifies the nanny she was hired —
/// previously the hire happened entirely on the family side and the nanny got
/// no signal at all.
export const onHireCreated = onDocumentCreated('hires/{hireId}', async (event) => {
  const hire = event.data?.data();
  const nannyId = hire?.nannyId as string | undefined;
  if (!nannyId) return;

  // Server-owned nanny aggregate (rules deny cross-client nanny-doc writes).
  await admin
    .firestore()
    .collection('nannies')
    .doc(nannyId)
    .set({ stats: { hiresCount: admin.firestore.FieldValue.increment(1) } }, { merge: true });

  // Tell the nanny. The ongoing relationship lives in Messages (matching the
  // app's own convention), so route the tap there.
  const nanny = await getUser(nannyId);
  const locale = nanny.locale ?? 'en';
  const familyName = (hire?.familyName as string | undefined) || tn('hire.defaultFamilyName', locale);
  const title = tn('hire.hired.title', locale);
  const body = tn('hire.hired.body', locale, { familyName });
  const data = {
    type: 'hired',
    hireId: event.params.hireId,
    nannyId: String(nannyId),
    familyId: String(hire?.familyId ?? ''),
    route: '/chat',
  };

  // Durable inbox record first (survives a missing FCM token), then the push.
  await writeInbox(nannyId, 'hired', title, body, data);
  await sendNotification((nanny.fcmTokens as string[]) ?? [], { title, body, data });
});

/// Ending a hire (nanny resigns / family terminates / contract completes) was
/// invisible to the other party. This fires once on the transition **into** the
/// ended state (first-end-wins — a re-write of an already-ended hire never
/// re-notifies) and tells whichever side did NOT trigger the end.
export const onHireEnded = onDocumentUpdated('hires/{hireId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;
  if (before.status === 'ended' || after.status !== 'ended') return;

  const reason = after.endReason as string | undefined;
  const data = {
    type: 'hire_ended',
    hireId: event.params.hireId,
    nannyId: String(after.nannyId ?? ''),
    familyId: String(after.familyId ?? ''),
    route: '/chat',
  };

  if (reason === 'resigned') {
    // The nanny resigned → notify the family.
    const familyId = after.familyId as string | undefined;
    if (!familyId) return;
    const family = await getUser(familyId);
    const locale = family.locale ?? 'en';
    const nannyName = (after.nannyName as string | undefined) || tn('hire.defaultNannyName', locale);
    const title = tn('hire.nannyResigned.title', locale);
    const body = tn('hire.nannyResigned.body', locale, { nannyName });
    await writeInbox(familyId, 'systemAnnouncement', title, body, data);
    await sendNotification((family.fcmTokens as string[]) ?? [], { title, body, data });
  } else {
    // The family terminated, or the hire completed → notify the nanny.
    const nannyId = after.nannyId as string | undefined;
    if (!nannyId) return;
    const nanny = await getUser(nannyId);
    const locale = nanny.locale ?? 'en';
    const familyName = (after.familyName as string | undefined) || tn('hire.defaultFamilyName', locale);
    const title = tn(reason === 'completed' ? 'hire.completed.title' : 'hire.ended.title', locale);
    const body = tn(reason === 'completed' ? 'hire.completed.body' : 'hire.ended.body', locale, {
      familyName,
    });
    await writeInbox(nannyId, 'systemAnnouncement', title, body, data);
    await sendNotification((nanny.fcmTokens as string[]) ?? [], { title, body, data });
  }
});
