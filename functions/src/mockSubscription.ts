import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { resolveLocale, tn } from './i18n/notifications';

function mockSubscriptionAllowed(): boolean {
  const projectId = process.env.GCLOUD_PROJECT ?? process.env.GCP_PROJECT ?? '';
  return projectId.includes('testing') || process.env.ALLOW_MOCK_SUBSCRIPTION === 'true';
}

/// Dev-only: mirrors [MockSubscriptionService] state into the family doc so
/// Firestore rules and onContactRevealRequested see the same entitlement as the app.
export const syncMockSubscription = onCall(async (request) => {
  if (!request.auth) {
    // No signed-in user yet, so there's no locale preference to read — the
    // client's own locale-aware handling of this rare unauthenticated case
    // is the fallback (mirrors bootstrapAdmin's pre-auth default of 'en').
    throw new HttpsError('unauthenticated', tn('error.signInRequired', 'en'));
  }

  const userSnap = await admin.firestore().collection('users').doc(request.auth.uid).get();
  const locale = resolveLocale(userSnap.data());

  if (!mockSubscriptionAllowed()) {
    throw new HttpsError('permission-denied', tn('error.mockSubscriptionDisabled', locale));
  }

  const familyId = request.auth.uid;
  const state = request.data?.state as string | undefined;
  const planId = request.data?.planId as string | undefined;

  if (!state) {
    throw new HttpsError('invalid-argument', tn('error.stateRequired', locale));
  }

  const db = admin.firestore();
  const ref = db.collection('families').doc(familyId);
  const now = admin.firestore.Timestamp.now();

  let subscription: Record<string, unknown>;
  switch (state) {
    case 'active':
      subscription = {
        status: 'active',
        plan: planId ?? 'monthly',
        startDate: now,
        endDate: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        ),
        autoRenew: true,
        hasEverSubscribed: true,
        mockDev: true,
      };
      break;
    case 'cancelledInPeriod':
      subscription = {
        status: 'cancelled',
        plan: planId ?? 'monthly',
        endDate: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        ),
        mockDev: true,
      };
      break;
    case 'expired':
      subscription = { status: 'expired', expiredAt: now, mockDev: true };
      break;
    case 'paymentGrace':
      subscription = { status: 'paymentFailed', mockDev: true };
      break;
    default:
      subscription = { status: 'free', mockDev: true };
      break;
  }

  await ref.set({ subscription }, { merge: true });
  return { ok: true };
});
