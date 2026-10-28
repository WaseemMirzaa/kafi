import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';

/// The subset of a family doc that decides contact entitlement.
export interface ContactEntitlementInput {
  subscription?: { status?: string; endDate?: unknown; graceEndsAt?: unknown } | null;
  viewedProfiles?: unknown;
  activeTrialNannyIds?: unknown;
}

function endDateMs(endDate: unknown): number | null {
  const ts = endDate as { toMillis?: () => number } | null | undefined;
  return typeof ts?.toMillis === 'function' ? ts.toMillis() : null;
}

/// A family may see a nanny's contact if it (a) has an active or cancelled
/// subscription still inside its period (or is in its payment grace window), (b) has an active trial with that
/// nanny, or (c) is on the FREE tier and has already spent a free contact on
/// them (the nanny is in `viewedProfiles`). Mirrors the Firestore rules'
/// `familyCanChatWith`: an expired / payment-failed family no longer gets (c),
/// otherwise a lapsed plan would keep every previously unlocked phone. The
/// period check covers the lag before the hourly enforcer flips the status.
/// Pure — no Firestore — so the security-critical decision can be unit tested.
/// Non-array history fields are treated as empty.
export function isContactEntitled(
  fam: ContactEntitlementInput,
  nannyId: string,
  nowMs: number = Date.now(),
): boolean {
  const status = fam.subscription?.status;
  const end = endDateMs(fam.subscription?.endDate);
  const inPeriod = end === null || end > nowMs;
  // Grace (failed payment being retried) keeps access until graceEndsAt; a
  // paymentFailed doc with no grace window is treated as lapsed.
  const graceEnd = endDateMs(fam.subscription?.graceEndsAt);
  const inGrace = status === 'paymentFailed' && graceEnd !== null && graceEnd > nowMs;
  const subscribed = ((status === 'active' || status === 'cancelled') && inPeriod) || inGrace;
  const freeTier = status === undefined || status === null || status === 'free';
  const viewed =
    Array.isArray(fam.viewedProfiles) && (fam.viewedProfiles as string[]).includes(nannyId);
  const activeTrial =
    Array.isArray(fam.activeTrialNannyIds) &&
    (fam.activeTrialNannyIds as string[]).includes(nannyId);
  return subscribed || (freeTier && viewed) || activeTrial;
}

/// True when the subscription has fully lapsed. Grace (`paymentFailed`) is NOT
/// lapsed: access continues until the enforcer flips it to `expired`.
export function isContactLockedOut(status: unknown): boolean {
  return status === 'expired';
}

/// Which already-revealed contacts to take back from a lapsed family: every
/// reveal except nannies it still has a live trial with. A reveal doc keeps the
/// phone number the family can read, so denying *new* reveals is not enough.
export function revealsToRevoke(
  revealNannyIds: string[],
  activeTrialNannyIds: unknown,
): string[] {
  const keep = new Set(
    Array.isArray(activeTrialNannyIds) ? (activeTrialNannyIds as string[]) : [],
  );
  return revealNannyIds.filter((id) => !keep.has(id));
}

/// Deletes `contactReveals` docs (which hold the phone) the family is no longer
/// entitled to. Called when its plan lapses or a live trial ends while lapsed.
export async function revokeContactReveals(
  familyId: string,
  activeTrialNannyIds: unknown,
): Promise<number> {
  const db = admin.firestore();
  const snap = await db.collection('contactReveals').where('familyId', '==', familyId).get();
  if (snap.empty) return 0;
  const doomed = new Set(
    revealsToRevoke(
      snap.docs.map((d) => d.data().nannyId as string),
      activeTrialNannyIds,
    ),
  );
  const docs = snap.docs.filter((d) => doomed.has(d.data().nannyId as string));
  for (let i = 0; i < docs.length; i += 450) {
    const batch = db.batch();
    docs.slice(i, i + 450).forEach((d) => batch.delete(d.ref));
    await batch.commit();
  }
  return docs.length;
}

/// Privacy-gated contact reveal. A family requests a nanny's phone by creating
/// `contactReveals/{familyId}_{nannyId}` (it cannot read the nanny's `users` doc
/// directly — the rules forbid it). This trigger checks the family is entitled
/// (see [isContactEntitled]) and, only then, writes back JUST the phone. Nothing else from the nanny's user doc is exposed.
export const onContactRevealRequested = onDocumentCreated(
  'contactReveals/{revealId}',
  async (event) => {
    const req = event.data?.data();
    const familyId = req?.familyId as string | undefined;
    const nannyId = req?.nannyId as string | undefined;
    if (!familyId || !nannyId) return;

    const db = admin.firestore();
    const ref = event.data!.ref;

    const fam = (await db.collection('families').doc(familyId).get()).data() ?? {};
    if (!isContactEntitled(fam, nannyId)) {
      await ref.set({ status: 'denied', reason: 'paywall' }, { merge: true });
      return;
    }

    const nannyUser = (await db.collection('users').doc(nannyId).get()).data() ?? {};
    const phone = (nannyUser.phone as string) || '';
    await ref.set({ status: 'revealed', phone }, { merge: true });
  },
);
