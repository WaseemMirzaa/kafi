import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { sendNotification, writeInbox, getUser } from '../utils/notifications';
import { tn } from '../i18n/notifications';

export const onNewMessage = onDocumentCreated(
  'chatThreads/{threadId}/messages/{messageId}',
  async (event) => {
    const message = event.data?.data();
    if (!message) return;

    // Trial/system bubbles (offer, accept, decline, counter, system) each have
    // their own dedicated trial notification; without this guard the recipient
    // gets a second, redundant "New message" push for the same event.
    const messageType = (message.type as string | undefined) ?? 'text';
    if (messageType !== 'text' && messageType !== 'image') return;

    const threadSnap = await admin
      .firestore()
      .collection('chatThreads')
      .doc(event.params.threadId)
      .get();
    const thread = threadSnap.data();
    if (!thread) return;

    const recipientId =
      message.senderId === thread.familyId ? thread.nannyId : thread.familyId;
    const recipient = await getUser(recipientId);
    const sender = await getUser(message.senderId);
    const locale = recipient.locale ?? 'en';

    const title = tn('chat.newMessage.title', locale);
    const body = tn('chat.newMessage.body', locale, {
      senderName: (sender.fullName as string) || tn('chat.defaultSenderName', locale),
      content: ((message.content as string) || '').substring(0, 80),
    });
    const data = {
      type: 'new_message',
      threadId: event.params.threadId,
      senderId: String(message.senderId ?? ''),
      familyId: String(thread.familyId ?? ''),
      nannyId: String(thread.nannyId ?? ''),
      route: '/chat',
    };

    await writeInbox(recipientId, 'newMessage', title, body, data);
    await sendNotification((recipient.fcmTokens as string[]) ?? [], { title, body, data });
  }
);
