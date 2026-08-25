import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { sendNotification, writeInbox, getUser } from '../utils/notifications';
import { notif, tn } from '../i18n/notifications';

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
    const videoChanged = before.introVideoStatus !== after.introVideoStatus;
    if (
      changed.length === 0 &&
      before.status === after.status &&
      !blockedChanged &&
      !videoChanged
    ) {
      return;
    }

    // Tokens live on the user doc and may be empty — the inbox is written
    // regardless so the record survives a missing/rotated FCM token.
    const nannyId = event.params.nannyId;
    const user = await getUser(nannyId);
    const tokens = (user.fcmTokens as string[]) ?? [];
    const locale = user.locale ?? 'en';

    // 1. Per-document approved / rejected notifications.
    for (const d of changed) {
      const payload =
        d.status === 'approved'
          ? {
              ...notif('nanny.docApproved', locale, { docType: d.type ?? '' }),
              type: 'documentsApproved' as const,
            }
          : d.status === 'rejected'
          ? {
              ...notif('nanny.docRejected', locale, {
                docType: d.type ?? '',
                reason: d.rejectionReason || tn('nanny.docRejected.defaultReason', locale),
              }),
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
          ? { ...notif('nanny.profileApproved', locale), type: 'profileVerified' as const }
          : after.status === 'rejected'
          ? {
              title: tn('nanny.profileRejected.title', locale),
              body: after.rejectionReason || tn('nanny.profileRejected.defaultBody', locale),
              type: 'documentsRejected' as const,
            }
          : { ...notif('nanny.profileSubmitted', locale), type: 'systemAnnouncement' as const };
      const data = { type: `profile_${after.status}` };
      await writeInbox(nannyId, payload.type, payload.title, payload.body, data);
      await sendNotification(tokens, { title: payload.title, body: payload.body, data });
    }

    // 3. Block / unblock push. The mobile app also enforces the block live via
    // its `blocked` watcher, but this tells the nanny why.
    if (blockedChanged) {
      const payload =
        after.blocked === true
          ? notif('nanny.accountDisabled', locale)
          : notif('nanny.accountRestored', locale);
      const data = { type: after.blocked === true ? 'account_blocked' : 'account_unblocked' };
      await writeInbox(nannyId, 'systemAnnouncement', payload.title, payload.body, data);
      await sendNotification(tokens, { title: payload.title, body: payload.body, data });
    }

    // 4. Intro-video review push. Admin approves/rejects the intro video from
    // the nanny detail page (sets `introVideoStatus`); the nanny is told the
    // outcome so a rejection prompts a re-record.
    if (
      videoChanged &&
      (after.introVideoStatus === 'approved' || after.introVideoStatus === 'rejected')
    ) {
      const payload =
        after.introVideoStatus === 'approved'
          ? { ...notif('nanny.introVideoApproved', locale), type: 'documentsApproved' as const }
          : {
              title: tn('nanny.introVideoRejected.title', locale),
              body:
                (after.introVideoRejectionReason as string) ||
                tn('nanny.introVideoRejected.defaultBody', locale),
              type: 'documentsRejected' as const,
            };
      const data = { type: `intro_video_${after.introVideoStatus}` };
      await writeInbox(nannyId, payload.type, payload.title, payload.body, data);
      await sendNotification(tokens, { title: payload.title, body: payload.body, data });
    }
  },
);
