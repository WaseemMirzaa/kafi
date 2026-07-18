import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { sendNotification } from '../utils/notifications';

/// Per System Spec §12.3 — when an admin creates a broadcast doc, resolve the
/// audience tokens and dispatch FCM, then write deliveryStats back to the doc.
export const onBroadcastCreated = onDocumentCreated(
  'broadcasts/{broadcastId}',
  async (event) => {
    const broadcast = event.data?.data();
    if (!broadcast) return;

    // Status must start as 'queued' for the function to act.
    if (broadcast.status !== 'queued') return;

    const ref = event.data!.ref;
    const db = admin.firestore();

    try {
      await ref.update({ status: 'sending' });

    const audience: string = broadcast.audience || 'all';
    const tokens: string[] = [];
    // Recipient user ids — every targeted user gets a durable inbox doc, even
    // those without an FCM token (who would otherwise never see the broadcast).
    const recipientIds: string[] = [];

    if (audience === 'subscribers') {
      // Subscribers = families with an active subscription. Resolve via the
      // `families` collection, then join to user fcmTokens.
      const famSnap = await db
        .collection('families')
        .where('subscription.status', '==', 'active')
        .get();
      const userIds = famSnap.docs.map((d) => (d.data().userId as string) || d.id);
      // Firestore `in` queries cap at 30 ids — batch them.
      for (let i = 0; i < userIds.length; i += 30) {
        const batch = userIds.slice(i, i + 30);
        if (batch.length === 0) continue;
        const userSnap = await db
          .collection('users')
          .where(admin.firestore.FieldPath.documentId(), 'in', batch)
          .get();
        userSnap.forEach((d) => {
          recipientIds.push(d.id);
          const t = d.data().fcmTokens as string[] | undefined;
          if (t?.length) tokens.push(...t);
        });
      }
    } else {
      let usersQuery: FirebaseFirestore.Query = db.collection('users');
      if (audience === 'nannies') {
        usersQuery = usersQuery.where('type', '==', 'nanny');
      } else if (audience === 'families') {
        usersQuery = usersQuery.where('type', '==', 'family');
      }
      const snap = await usersQuery.get();
      snap.forEach((d) => {
        recipientIds.push(d.id);
        const t = d.data().fcmTokens as string[] | undefined;
        if (t?.length) tokens.push(...t);
      });
    }

    // Fan the broadcast into every recipient's inbox (batched; Firestore caps
    // at 500 writes/commit).
    for (let i = 0; i < recipientIds.length; i += 450) {
      const inboxBatch = db.batch();
      for (const uid of recipientIds.slice(i, i + 450)) {
        inboxBatch.set(db.collection('notifications').doc(), {
          userId: uid,
          type: 'systemAnnouncement',
          title: broadcast.title || 'Kafi',
          body: broadcast.message || '',
          data: { type: 'broadcast', broadcastId: event.params.broadcastId },
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
      await inboxBatch.commit();
    }

    let sent = 0;
    let delivered = 0;

    if (tokens.length) {
      const batches: string[][] = [];
      // FCM accepts up to 500 tokens per multicast.
      for (let i = 0; i < tokens.length; i += 500) {
        batches.push(tokens.slice(i, i + 500));
      }
      for (const batch of batches) {
        try {
          await sendNotification(batch, {
            title: broadcast.title || 'Kafi',
            body: broadcast.message || '',
            data: { type: 'broadcast', broadcastId: event.params.broadcastId },
          });
          sent += batch.length;
          delivered += batch.length;
        } catch {
          // Continue with other batches even if one fails.
        }
      }
    }

      await ref.update({
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        deliveryStats: {
          sent,
          delivered,
          opened: 0,
          audienceSize: tokens.length,
        },
      });
    } catch (err) {
      await ref.update({
        status: 'failed',
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
        errorMessage: (err as Error).message || 'unknown_error',
      });
      throw err;
    }
  }
);
