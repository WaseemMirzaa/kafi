import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { sendNotification, writeInbox, getUser } from '../utils/notifications';

/// When admin replies to a support ticket, notify the opener (inbox + push).
/// User→admin messages are surfaced in the admin panel's ticket queue, and
/// admins have no FCM tokens, so only the admin→user direction pushes.
export const onNewTicketMessage = onDocumentCreated(
  'tickets/{ticketId}/messages/{messageId}',
  async (event) => {
    const message = event.data?.data();
    if (!message || message.senderType !== 'admin') return;

    const ticketSnap = await admin
      .firestore()
      .collection('tickets')
      .doc(event.params.ticketId)
      .get();
    const ticket = ticketSnap.data();
    if (!ticket) return;

    const openerId = ticket.openerId as string | undefined;
    if (!openerId) return;
    const opener = await getUser(openerId);

    const title = '🎧 Support replied';
    const body = (message.content || '').toString().substring(0, 90);
    const data = { type: 'support_reply', ticketId: event.params.ticketId };

    // The inbox uses the generic system type (the app maps unknown types to a
    // system announcement); the title makes the support context clear.
    await writeInbox(openerId, 'systemAnnouncement', title, body, data);
    await sendNotification((opener.fcmTokens as string[]) ?? [], { title, body, data });
  },
);

/// When admin resolves or closes a support ticket, notify the opener of the
/// outcome (inbox + push) so they don't have to keep checking. Fires only on the
/// status transition into a terminal state. Mirrors onDisputeResolved.
export const onTicketStatusChanged = onDocumentUpdated(
  'tickets/{ticketId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const becameTerminal =
      before.status !== after.status &&
      (after.status === 'resolved' || after.status === 'closed');
    if (!becameTerminal) return;

    const openerId = after.openerId as string | undefined;
    if (!openerId) return;
    const opener = await getUser(openerId);

    const resolved = after.status === 'resolved';
    const title = resolved ? '✅ Ticket resolved' : '📋 Ticket closed';
    const body =
      (after.resolution as string) ||
      (resolved
        ? 'Our team has resolved your support ticket.'
        : 'Our team has closed your support ticket.');
    const data = { type: `support_${after.status}`, ticketId: event.params.ticketId };

    await writeInbox(openerId, 'systemAnnouncement', title, body, data);
    await sendNotification((opener.fcmTokens as string[]) ?? [], { title, body, data });
  },
);
