import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { sendNotification, getUser, getNanny, getFamily } from '../utils/notifications';

export const onNewApplication = onDocumentCreated(
  'applications/{appId}',
  async (event) => {
    const app = event.data?.data();
    if (!app) return;

    const family = await getFamily(app.familyId);
    const nanny = await getNanny(app.nannyId);

    if (!family.fcmTokens?.length) return;

    await sendNotification(family.fcmTokens, {
      title: '📝 New application',
      body: `${nanny.fullName || 'A nanny'} applied - ${app.matchScore || 0}% match`,
      data: {
        type: 'new_application',
        applicationId: event.params.appId,
      },
    });
  }
);

export const onTrialOffered = onDocumentCreated('trials/{trialId}', async (event) => {
  const trial = event.data?.data();
  if (!trial || trial.status !== 'pending') return;

  const nanny = await getUser(trial.nannyId);
  const family = await getFamily(trial.familyId);

  if (!nanny.fcmTokens?.length) return;

  await sendNotification(nanny.fcmTokens, {
    title: '🎉 Trial offer received!',
    body: `${family.fullName || 'A family'} sent ${trial.durationDays}-day trial @ AED ${trial.dailyRate}/day`,
    data: {
      type: 'trial_offer_received',
      trialId: event.params.trialId,
    },
  });
});

export const onTrialResponse = onDocumentUpdated('trials/{trialId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after || before.status === after.status) return;

  const family = await getFamily(after.familyId);
  const nanny = await getUser(after.nannyId);

  if (!family.fcmTokens?.length) return;

  let payload: { title: string; body: string } | null = null;
  switch (after.status) {
    case 'accepted':
      payload = {
        title: '✅ Trial accepted',
        body: `${nanny.fullName || 'Nanny'} accepted your offer!`,
      };
      break;
    case 'declined':
      payload = {
        title: 'Trial declined',
        body: `${nanny.fullName || 'Nanny'} declined your offer`,
      };
      break;
    case 'countered':
      payload = {
        title: '🔄 Counter offer',
        body: `${nanny.fullName || 'Nanny'} sent a counter offer`,
      };
      break;
  }

  if (payload) {
    await sendNotification(family.fcmTokens, {
      ...payload,
      data: { type: `trial_${after.status}`, trialId: event.params.trialId },
    });
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
    if (family.fcmTokens?.length) {
      await sendNotification(family.fcmTokens, {
        title: 'Trial completed',
        body: 'Evaluate the nanny in your trial.',
        data: { type: 'trial_completed', trialId: event.params.trialId },
      });
    }
  }
});
