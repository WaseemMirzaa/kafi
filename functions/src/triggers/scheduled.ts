import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import { sendNotification, writeInbox, getFamily, getUser } from '../utils/notifications';

export const trialStartingReminder = onSchedule('every 1 hours', async () => {
  const now = new Date();
  const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
  const db = admin.firestore();

  const trials = await db
    .collection('trials')
    .where('status', '==', 'accepted')
    .where('startDate', '<=', admin.firestore.Timestamp.fromDate(tomorrow))
    .where('startDate', '>', admin.firestore.Timestamp.fromDate(now))
    .limit(200)
    .get();

  await Promise.all(
    trials.docs.map(async (doc) => {
      const trial = doc.data();
      if (trial.reminderSent) return;

      const [family, nannyUser] = await Promise.all([
        getFamily(trial.familyId as string),
        getUser(trial.nannyId as string),
      ]);

      const tokens = [
        ...((family.fcmTokens as string[]) ?? []),
        ...((nannyUser.fcmTokens as string[]) ?? []),
      ];

      const title = '⏰ Trial starts tomorrow!';
      const body = `Trial starts at ${trial.startTime || 'scheduled time'}`;
      const data = { type: 'trial_starting_soon', trialId: doc.id };
      await writeInbox(trial.familyId as string, 'trialStartingSoon', title, body, data);
      await writeInbox(trial.nannyId as string, 'trialStartingSoon', title, body, data);
      await sendNotification(tokens, { title, body, data });
      await doc.ref.update({ reminderSent: true });
    }),
  );
});

export const subscriptionExpiringReminder = onSchedule('every day 09:00', async () => {
  const in3Days = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000);
  const families = await admin
    .firestore()
    .collection('families')
    .where('subscription.status', '==', 'active')
    .where('subscription.endDate', '<=', admin.firestore.Timestamp.fromDate(in3Days))
    .limit(200)
    .get();

  await Promise.all(
    families.docs.map(async (doc) => {
      const family = await getFamily(doc.id);
      const tokens = (family.fcmTokens as string[]) ?? [];

      const title = '💳 Expiring soon';
      const body = 'Your subscription renews in 3 days';
      const data = { type: 'subscription_expiring' };
      await writeInbox(doc.id, 'subscriptionExpiring', title, body, data);
      await sendNotification(tokens, { title, body, data });
    }),
  );
});

export const subscriptionExpiredEnforcer = onSchedule('every 1 hours', async () => {
  const now = admin.firestore.Timestamp.now();
  const db = admin.firestore();
  const families = await db
    .collection('families')
    .where('subscription.status', 'in', ['active', 'cancelled'])
    .where('subscription.endDate', '<=', now)
    .limit(450)
    .get();

  // Chunk into batches of ≤450 writes (Firestore limit 500).
  for (let i = 0; i < families.docs.length; i += 450) {
    const batch = db.batch();
    families.docs.slice(i, i + 450).forEach((doc) => {
      batch.update(doc.ref, {
        'subscription.status': 'expired',
        'subscription.expiredAt': now,
        'subscription.contactsHidden': true,
        'subscription.chatLocked': true,
      });
    });
    await batch.commit();
  }

  await Promise.all(
    families.docs.map(async (doc) => {
      const family = await getFamily(doc.id);
      const tokens = (family.fcmTokens as string[]) ?? [];

      const title = '⚠️ Subscription expired';
      const body = 'Renew to access your chats and contacts';
      const data = { type: 'subscription_expired' };
      await writeInbox(doc.id, 'subscriptionExpired', title, body, data);
      await sendNotification(tokens, { title, body, data });
    }),
  );
});
