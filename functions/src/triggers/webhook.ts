import { onRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { sendNotification } from '../utils/notifications';

export const revenueCatWebhook = onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  // Per System Spec §8.3 the RevenueCat webhook MUST be authenticated.
  // Require the shared secret unconditionally — refuse to start if it isn't
  // set in the deployment environment so we never accept anonymous webhooks
  // in production.
  const sharedSecret = process.env.REVENUECAT_WEBHOOK_SECRET;
  if (!sharedSecret) {
    console.error(
      '[revenueCatWebhook] REVENUECAT_WEBHOOK_SECRET is not configured — rejecting request',
    );
    res.status(500).send('Server misconfigured');
    return;
  }
  const auth = req.headers.authorization || '';
  const token = auth.startsWith('Bearer ') ? auth.substring(7) : auth;
  if (token !== sharedSecret) {
    res.status(401).send('Unauthorized');
    return;
  }

  const event = req.body?.event;
  if (!event) {
    res.status(400).send('Missing event');
    return;
  }

  const familyId = event.app_user_id;
  if (!familyId) {
    res.status(400).send('Missing app_user_id');
    return;
  }

  const familyRef = admin.firestore().collection('families').doc(familyId);
  const familySnap = await familyRef.get();
  if (!familySnap.exists) {
    res.status(404).send('Family not found');
    return;
  }

  const eventType = event.type;
  let update: Record<string, unknown> = {};
  let notification: { title: string; body: string } | null = null;

  switch (eventType) {
    case 'INITIAL_PURCHASE':
    case 'RENEWAL':
      update = {
        'subscription.status': 'active',
        'subscription.startDate': admin.firestore.Timestamp.now(),
        'subscription.endDate': admin.firestore.Timestamp.fromMillis(
          event.expiration_at_ms || Date.now() + 30 * 24 * 60 * 60 * 1000
        ),
        'subscription.contactsHidden': false,
        'subscription.chatLocked': false,
        'subscription.hasEverSubscribed': true,
      };
      notification = {
        title: '✅ Subscription active',
        body: 'Full access unlocked - browse, chat, and contact nannies!',
      };
      break;

    case 'CANCELLATION':
      update = {
        'subscription.status': 'cancelled',
        'subscription.autoRenew': false,
      };
      notification = {
        title: 'Subscription cancelled',
        body: 'Your access continues until the end of the current period',
      };
      break;

    case 'EXPIRATION':
      update = {
        'subscription.status': 'expired',
        'subscription.expiredAt': admin.firestore.Timestamp.now(),
        'subscription.contactsHidden': true,
        'subscription.chatLocked': true,
      };
      notification = {
        title: '⚠️ Subscription expired',
        body: 'Renew to access chats and contacts',
      };
      break;

    case 'BILLING_ISSUE':
      update = {
        'subscription.status': 'paymentFailed',
        'subscription.contactsHidden': true,
        'subscription.chatLocked': true,
      };
      notification = {
        title: '❌ Payment failed',
        body: 'Update your payment method to continue access',
      };
      break;

    case 'UNCANCELLATION':
      update = {
        'subscription.status': 'active',
        'subscription.autoRenew': true,
      };
      notification = {
        title: '🎉 Subscription resumed',
        body: 'Your plan will renew automatically',
      };
      break;

    case 'PRODUCT_CHANGE':
      update = {
        'subscription.plan': event.product_id || event.new_product_id || null,
        'subscription.endDate': admin.firestore.Timestamp.fromMillis(
          event.expiration_at_ms || Date.now() + 30 * 24 * 60 * 60 * 1000
        ),
        'subscription.lastRenewalAt': admin.firestore.Timestamp.now(),
      };
      notification = {
        title: 'Plan updated',
        body: 'Your subscription plan has changed.',
      };
      break;

    default:
      res.status(200).send('Event type not handled');
      return;
  }

  await familyRef.update(update);

  const familyData = familySnap.data();
  if (notification && familyData?.fcmTokens?.length) {
    await sendNotification(familyData.fcmTokens, {
      ...notification,
      data: { type: `subscription_${eventType.toLowerCase()}` },
    });
  }

  res.status(200).send('OK');
});
