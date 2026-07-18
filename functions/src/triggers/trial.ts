import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { sendNotification, writeInbox, getUser, getNanny, getFamily } from '../utils/notifications';

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

  const db = admin.firestore();
  const trialsSnap = await db
    .collection('trials')
    .where('familyId', '==', familyId)
    .where('status', 'in', ['active', 'accepted'])
    .get();

  const activeIds = trialsSnap.docs.map((d) => d.data().nannyId as string);
  await db.collection('families').doc(familyId).update({
    activeTrialNannyIds: activeIds,
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
