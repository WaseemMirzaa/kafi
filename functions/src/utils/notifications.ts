import * as admin from 'firebase-admin';

interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

/// A Firestore document that (may) carry cached FCM tokens. The named
/// `fcmTokens` field lets trigger call sites do `user.fcmTokens?.length` and
/// pass `user.fcmTokens` straight to `sendNotification`; the index signature
/// keeps every other document field accessible.
export interface TokenBearer {
  fcmTokens?: string[];
  [key: string]: unknown;
}

/// Sends a multicast push and prunes dead tokens.
///
/// Flutter writes FCM tokens to `users/{uid}.fcmTokens` (see
/// `firestore_user_service` + `fcm_notification_service`). When Firebase
/// reports `messaging/registration-token-not-registered` (or any "invalid")
/// for a token we remove it from every user that has it cached.
export async function sendNotification(
  fcmTokens: string[],
  payload: NotificationPayload,
): Promise<void> {
  if (!fcmTokens.length) return;

  const message: admin.messaging.MulticastMessage = {
    tokens: fcmTokens,
    notification: { title: payload.title, body: payload.body },
    data: payload.data,
  };

  try {
    const result = await admin.messaging().sendEachForMulticast(message);
    if (result.failureCount === 0) return;

    const dead: string[] = [];
    result.responses.forEach((r, i) => {
      if (r.success) return;
      const code = r.error?.code ?? '';
      if (
        code === 'messaging/registration-token-not-registered' ||
        code === 'messaging/invalid-registration-token' ||
        code === 'messaging/invalid-argument'
      ) {
        dead.push(fcmTokens[i]);
      } else {
        console.warn('FCM partial failure:', code, r.error?.message);
      }
    });

    if (dead.length === 0) return;
    // Best-effort prune across any user that still has these tokens cached.
    const db = admin.firestore();
    const users = await db.collection('users').where('fcmTokens', 'array-contains-any', dead.slice(0, 10)).get();
    await Promise.all(
      users.docs.map((d) => d.ref.update({ fcmTokens: admin.firestore.FieldValue.arrayRemove(...dead) })),
    );
  } catch (error) {
    console.error('FCM send error:', error);
  }
}

/// Notification-inbox `type` values — mirror the Flutter `NotificationType`
/// enum names (kafi_app/lib/models/notification_model.dart). The in-app inbox
/// queries `notifications` where `userId == me` ordered by `createdAt`, and maps
/// this exact string back to the enum (an unknown value → systemAnnouncement).
export type InboxType =
  | 'newMessage'
  | 'newApplication'
  | 'applicationViewed'
  | 'applicationDeclined'
  | 'trialOfferReceived'
  | 'trialAccepted'
  | 'trialDeclined'
  | 'trialCountered'
  | 'trialStartingSoon'
  | 'trialEndingSoon'
  | 'trialOutcomePending'
  | 'trialCompleted'
  | 'hired'
  | 'profileViewed'
  | 'documentsApproved'
  | 'documentsRejected'
  | 'profileVerified'
  | 'subscriptionExpiring'
  | 'subscriptionRenewed'
  | 'subscriptionExpired'
  | 'freeContactsLow'
  | 'systemAnnouncement';

/// The stored inbox document, minus the server-set `createdAt`. Kept pure (no
/// FieldValue sentinel / admin dependency) so the shape can be unit-tested and
/// stays in lockstep with the app's `AppNotification.fromMap` reader.
export interface InboxDoc {
  userId: string;
  type: InboxType;
  title: string;
  body: string;
  data: Record<string, string>;
  read: boolean;
}

export function buildInboxDoc(
  userId: string,
  type: InboxType,
  title: string,
  body: string,
  data: Record<string, string> = {},
): InboxDoc {
  return { userId, type, title, body, data, read: false };
}

/// Persists an in-app notification so it appears in the recipient's inbox even
/// when they have no FCM token or the push is never delivered. The companion to
/// [sendNotification]: call `writeInbox` for the durable record, then
/// `sendNotification` for the live push. Best-effort — never throws.
export async function writeInbox(
  userId: string | undefined,
  type: InboxType,
  title: string,
  body: string,
  data: Record<string, string> = {},
): Promise<void> {
  if (!userId) return;
  try {
    await admin.firestore().collection('notifications').add({
      ...buildInboxDoc(userId, type, title, body, data),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error('writeInbox error:', error);
  }
}

/// Returns the user document (where FCM tokens live).
export async function getUser(userId: string): Promise<TokenBearer> {
  const snap = await admin.firestore().collection('users').doc(userId).get();
  return (snap.data() as TokenBearer) ?? {};
}

/// Returns the nanny profile + FCM tokens (merged from `users/{uid}` since
/// the nanny doc itself does not carry tokens).
export async function getNanny(nannyId: string): Promise<TokenBearer> {
  const [n, u] = await Promise.all([
    admin.firestore().collection('nannies').doc(nannyId).get(),
    admin.firestore().collection('users').doc(nannyId).get(),
  ]);
  return {
    ...((n.data() as Record<string, unknown>) ?? {}),
    fcmTokens: ((u.data() as Record<string, unknown> | undefined)?.fcmTokens as string[]) ?? [],
  };
}

/// Returns the family profile + FCM tokens (merged from `users/{uid}`).
export async function getFamily(familyId: string): Promise<TokenBearer> {
  const [f, u] = await Promise.all([
    admin.firestore().collection('families').doc(familyId).get(),
    admin.firestore().collection('users').doc(familyId).get(),
  ]);
  return {
    ...((f.data() as Record<string, unknown>) ?? {}),
    fcmTokens: ((u.data() as Record<string, unknown> | undefined)?.fcmTokens as string[]) ?? [],
  };
}
