import { onDocumentCreated } from 'firebase-functions/v2/firestore';
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
