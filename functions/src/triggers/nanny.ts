import { onDocumentUpdated, onDocumentCreated } from 'firebase-functions/v2/firestore';
import { sendNotification, getUser } from '../utils/notifications';

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

    if (changed.length === 0 && before.status === after.status) return;

    // Only notify when the user has FCM tokens. Tokens live on the user doc.
    const user = await getUser(event.params.nannyId);
    if (!user.fcmTokens?.length) return;

    // 1. Per-document approved / rejected pushes.
    for (const d of changed) {
      const payload =
        d.status === 'approved'
          ? {
              title: '✅ Document approved',
              body: `${d.type} verified — keep going!`,
            }
          : d.status === 'rejected'
          ? {
              title: '❌ Action needed',
              body: `${d.type} rejected: ${d.rejectionReason || 'Please re-upload'}`,
            }
          : null;
      if (!payload) continue;
      await sendNotification(user.fcmTokens, {
        ...payload,
        data: { type: `documents_${d.status}`, docType: d.type ?? '' },
      });
    }

    // 2. Overall onboarding status push (pending → approved / rejected).
    if (before.status !== after.status && (after.status === 'approved' || after.status === 'rejected')) {
      const payload =
        after.status === 'approved'
          ? {
              title: '🎉 Profile approved!',
              body: 'Your profile is now visible to families.',
            }
          : {
              title: '❌ Profile rejected',
              body: after.rejectionReason || 'Please review the feedback and re-submit.',
            };
      await sendNotification(user.fcmTokens, {
        ...payload,
        data: { type: `profile_${after.status}` },
      });
    }
  },
);

export const onNannySubmitted = onDocumentCreated('nannies/{nannyId}', async (event) => {
  const nanny = event.data?.data();
  // Flutter writes `status: NannyOnboardingStatus.pending.name === 'pending'`.
  if (!nanny || nanny.status !== 'pending') return;

  const user = await getUser(event.params.nannyId);
  if (!user.fcmTokens?.length) return;

  await sendNotification(user.fcmTokens, {
    title: '📋 Profile submitted',
    body: 'Admin is reviewing your profile (1-24 hours)',
    data: { type: 'profile_submitted' },
  });
});
