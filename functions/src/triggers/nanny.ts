import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { sendNotification, writeInbox, getUser } from '../utils/notifications';

interface NannyDoc {
  type?: string;
  status?: string;
  rejectionReason?: string;
}

/// Fires whenever a nanny doc is updated. We diff the embedded `documents`
/// array (per `nanny_model.dart`) and send a per-document approved/rejected
/// notification. Also fires the "profile approved" notification on overall
/// status transition.
export const onDocumentReviewed = onDocumentUpdated(
  'nannies/{nannyId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const beforeDocs: NannyDoc[] = Array.isArray(before.documents) ? before.documents : [];
    const afterDocs: NannyDoc[] = Array.isArray(after.documents) ? after.documents : [];

    // Build a map of before-status by document type for fast lookup.
    const prevByType = new Map<string, string | undefined>();
    for (const d of beforeDocs) {
      if (d.type) prevByType.set(d.type, d.status);
    }

    const changed = afterDocs.filter((d) => d.type && d.status && prevByType.get(d.type) !== d.status);

    const blockedChanged = (before.blocked === true) !== (after.blocked === true);
    if (changed.length === 0 && before.status === after.status && !blockedChanged) return;

    // Tokens live on the user doc and may be empty — the inbox is written
    // regardless so the record survives a missing/rotated FCM token.
    const nannyId = event.params.nannyId;
    const user = await getUser(nannyId);
    const tokens = (user.fcmTokens as string[]) ?? [];

    // 1. Per-document approved / rejected notifications.
    for (const d of changed) {
      const payload =
        d.status === 'approved'
          ? {
              title: '✅ Document approved',
              body: `${d.type} verified — keep going!`,
              type: 'documentsApproved' as const,
            }
          : d.status === 'rejected'
          ? {
              title: '❌ Action needed',
              body: `${d.type} rejected: ${d.rejectionReason || 'Please re-upload'}`,
              type: 'documentsRejected' as const,
            }
          : null;
      if (!payload) continue;
      const data = { type: `documents_${d.status}`, docType: d.type ?? '' };
      await writeInbox(nannyId, payload.type, payload.title, payload.body, data);
      await sendNotification(tokens, { title: payload.title, body: payload.body, data });
    }

    // 2. Overall onboarding status push. The nanny doc is CREATED as `draft`
    // and only flips to `pending` on submit (an UPDATE), so the "submitted"
    // push must live here on the status transition — an onCreate trigger never
    // sees `pending`.
    if (
      before.status !== after.status &&
      (after.status === 'pending' || after.status === 'approved' || after.status === 'rejected')
    ) {
      const payload =
        after.status === 'approved'
          ? {
              title: '🎉 Profile approved!',
              body: 'Your profile is now visible to families.',
              type: 'profileVerified' as const,
            }
          : after.status === 'rejected'
          ? {
              title: '❌ Profile rejected',
              body: after.rejectionReason || 'Please review the feedback and re-submit.',
              type: 'documentsRejected' as const,
            }
          : {
              title: '📋 Profile submitted',
              body: 'Admin is reviewing your profile (1–24 hours).',
              type: 'systemAnnouncement' as const,
            };
      const data = { type: `profile_${after.status}` };
      await writeInbox(nannyId, payload.type, payload.title, payload.body, data);
      await sendNotification(tokens, { title: payload.title, body: payload.body, data });
    }

    // 3. Block / unblock push. The mobile app also enforces the block live via
    // its `blocked` watcher, but this tells the nanny why.
    if (blockedChanged) {
      const payload =
        after.blocked === true
          ? {
              title: '🚫 Account disabled',
              body: 'Your Kafi account has been disabled by an administrator. Please contact support.',
            }
          : {
              title: '✅ Account restored',
              body: 'Your Kafi account has been re-enabled. Welcome back!',
            };
      const data = { type: after.blocked === true ? 'account_blocked' : 'account_unblocked' };
      await writeInbox(nannyId, 'systemAnnouncement', payload.title, payload.body, data);
      await sendNotification(tokens, { title: payload.title, body: payload.body, data });
    }
  },
);
