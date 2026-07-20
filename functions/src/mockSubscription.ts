import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

function mockSubscriptionAllowed(): boolean {
  const projectId = process.env.GCLOUD_PROJECT ?? process.env.GCP_PROJECT ?? '';
  return projectId.includes('testing') || process.env.ALLOW_MOCK_SUBSCRIPTION === 'true';
}

/// Dev-only: mirrors [MockSubscriptionService] state into the family doc so
/// Firestore rules and onContactRevealRequested see the same entitlement as the app.
export const syncMockSubscription = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  if (!mockSubscriptionAllowed()) {
    throw new HttpsError('permission-denied', 'Mock subscription sync is disabled.');
  }

  const familyId = request.auth.uid;
  const state = request.data?.state as string | undefined;
  const planId = request.data?.planId as string | undefined;

  if (!state) {
    throw new HttpsError('invalid-argument', 'state is required.');
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
