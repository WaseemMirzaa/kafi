import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { sendNotification, writeInbox, getUser } from '../utils/notifications';
import { tn } from '../i18n/notifications';

/// When admin replies in a dispute's support chat, notify the reporter (inbox +
/// push). User→admin messages surface in the admin panel; admins have no FCM
/// tokens, so only the admin→user direction pushes. Mirrors onNewTicketMessage.
export const onNewDisputeMessage = onDocumentCreated(
  'disputes/{disputeId}/messages/{messageId}',
  async (event) => {
    const message = event.data?.data();
    if (!message || message.senderType !== 'admin') return;

    const disputeSnap = await admin
      .firestore()
      .collection('disputes')
      .doc(event.params.disputeId)
      .get();
    const dispute = disputeSnap.data();
    if (!dispute) return;

    const reporterId = dispute.reporterId as string | undefined;
    if (!reporterId) return;
    const reporter = await getUser(reporterId);
    const locale = reporter.locale ?? 'en';

    const title = tn('dispute.reply.title', locale);
    const body = (message.content || '').toString().substring(0, 90);
    const data = { type: 'dispute_reply', disputeId: event.params.disputeId };

    await writeInbox(reporterId, 'systemAnnouncement', title, body, data);
    await sendNotification((reporter.fcmTokens as string[]) ?? [], { title, body, data });
  },
);

/// When admin resolves or dismisses a dispute, notify the reporter of the
/// outcome (inbox + push) so they don't have to poll. Fires only on the
/// status transition into a terminal state.
export const onDisputeResolved = onDocumentUpdated(
  'disputes/{disputeId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const becameTerminal =
      before.status !== after.status &&
      (after.status === 'resolved' || after.status === 'dismissed');
    if (!becameTerminal) return;

    const reporterId = after.reporterId as string | undefined;
    if (!reporterId) return;
    const reporter = await getUser(reporterId);
    const locale = reporter.locale ?? 'en';

    const resolved = after.status === 'resolved';
    const title = tn(resolved ? 'dispute.resolved.title' : 'dispute.dismissed.title', locale);
    const body =
      (after.resolution as string) ||
      tn(resolved ? 'dispute.resolved.defaultBody' : 'dispute.dismissed.defaultBody', locale);
    const data = { type: `dispute_${after.status}`, disputeId: event.params.disputeId };

    await writeInbox(reporterId, 'systemAnnouncement', title, body, data);
    await sendNotification((reporter.fcmTokens as string[]) ?? [], { title, body, data });
  },
);
