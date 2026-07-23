import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { sendNotification, writeInbox, getUser, getNanny, getFamily } from '../utils/notifications';

/// Recomputes `families/{familyId}.activeTrialNannyIds` from the family's trials
/// currently in an entitling state (accepted/active). This server-owned list is
/// what the security rules' `hasActiveTrialWith` reads to let a family without a
/// subscription chat with a nanny during a trial, so it must be refreshed
/// whenever a trial ENTERS that set (accept) as well as when it leaves (end) —
/// previously only the end transition recomputed it, so an accepted trial never
/// unlocked the chat for a free family.
async function recomputeActiveTrialNannyIds(familyId: string): Promise<void> {
  if (!familyId) return;
  const db = admin.firestore();
  const snap = await db
    .collection('trials')
    .where('familyId', '==', familyId)
    .where('status', 'in', ['active', 'accepted'])
    .get();
  const activeIds = Array.from(
    new Set(snap.docs.map((d) => d.data().nannyId as string).filter(Boolean)),
  );
  await db.collection('families').doc(familyId).update({ activeTrialNannyIds: activeIds });
}

export const onNewApplication = onDocumentCreated(
  'applications/{appId}',
  async (event) => {
    const app = event.data?.data();
    if (!app) return;

    const family = await getFamily(app.familyId);
    const nanny = await getNanny(app.nannyId);

    const title = '📝 New application';
    const body = `${nanny.fullName || 'A nanny'} applied - ${app.matchScore || 0}% match`;
    const data = { type: 'new_application', applicationId: event.params.appId };

    // Durable inbox record first (survives a missing FCM token), then the push.
    await writeInbox(app.familyId as string, 'newApplication', title, body, data);
    await sendNotification((family.fcmTokens as string[]) ?? [], { title, body, data });

    // Server-owned nanny aggregate (rules deny cross-client nanny-doc writes).
    if (app.nannyId) {
      await admin
        .firestore()
        .collection('nannies')
        .doc(app.nannyId as string)
        .set(
          { stats: { applicationsCount: admin.firestore.FieldValue.increment(1) } },
          { merge: true },
        );
    }
  }
);

export const onTrialOffered = onDocumentCreated('trials/{trialId}', async (event) => {
  const trial = event.data?.data();
  if (!trial || trial.status !== 'pending') return;

  const nanny = await getUser(trial.nannyId);
  const family = await getFamily(trial.familyId);

  const title = '🎉 Trial offer received!';
  const body = `${family.fullName || 'A family'} sent ${trial.durationDays}-day trial @ AED ${trial.dailyRate}/day`;
  const data = { type: 'trial_offer_received', trialId: event.params.trialId };

  await writeInbox(trial.nannyId as string, 'trialOfferReceived', title, body, data);
  await sendNotification((nanny.fcmTokens as string[]) ?? [], { title, body, data });
});

export const onTrialResponse = onDocumentUpdated('trials/{trialId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after || before.status === after.status) return;

  const family = await getFamily(after.familyId);
  const nanny = await getUser(after.nannyId);

  const byStatus = {
    accepted: {
      title: '✅ Trial accepted',
      body: `${nanny.fullName || 'Nanny'} accepted your offer!`,
      type: 'trialAccepted',
    },
    declined: {
      title: 'Trial declined',
      body: `${nanny.fullName || 'Nanny'} declined your offer`,
      type: 'trialDeclined',
    },
    countered: {
      title: '🔄 Counter offer',
      body: `${nanny.fullName || 'Nanny'} sent a counter offer`,
      type: 'trialCountered',
    },
  } as const;

  const entry = byStatus[after.status as keyof typeof byStatus];
  if (!entry) return;

  const data = { type: `trial_${after.status}`, trialId: event.params.trialId };
  await writeInbox(after.familyId as string, entry.type, entry.title, entry.body, data);
  await sendNotification((family.fcmTokens as string[]) ?? [], {
    title: entry.title,
    body: entry.body,
    data,
  });

  // Acceptance unlocks trial-chat: refresh the family's entitlement list so a
  // free family can immediately message this nanny (the gate reads it).
  if (after.status === 'accepted') {
    await recomputeActiveTrialNannyIds(after.familyId as string);
  }
});

/// Per Technical Architecture §10.2 — when a trial transitions to a terminal
/// state (completed/cancelled), recompute family.activeTrialNannyIds so the
/// subscription bypass falls back to normal lockdown rules.
export const onTrialEnded = onDocumentUpdated('trials/{trialId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;

  const terminal = ['completed', 'cancelled', 'declined'];
  const wasActive = !terminal.includes(before.status);
  const isTerminal = terminal.includes(after.status);
  if (!wasActive || !isTerminal) return;

  const familyId = after.familyId as string;
  if (!familyId) return;

  // A trial left the entitling set — recompute the list (shared with the accept
  // path) and stamp when the last trial ended.
  await recomputeActiveTrialNannyIds(familyId);
  await admin.firestore().collection('families').doc(familyId).update({
    'subscription.lastTrialEndedAt': admin.firestore.FieldValue.serverTimestamp(),
  });

  if (after.status === 'completed') {
    const family = await getFamily(familyId);
    const title = 'Trial completed';
    const body = 'Evaluate the nanny in your trial.';
    const data = { type: 'trial_completed', trialId: event.params.trialId };
    await writeInbox(familyId, 'trialCompleted', title, body, data);
    await sendNotification((family.fcmTokens as string[]) ?? [], { title, body, data });
  }
});
