import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import { tn } from '../i18n/notifications';
import { reconcileFamily, revenueCatConfigured } from '../utils/subscriptionSync';

/// Minimum gap between store re-verifications for one family. The app calls on
/// every open/resume, so without this a flapping app would hammer RevenueCat.
const MIN_VERIFY_GAP_MS = 20 * 1000;
/// The daily job re-checks anyone not verified within this window, which is what
/// catches a webhook that never arrived (outage, misconfiguration, refund).
const STALE_AFTER_MS = 48 * 60 * 60 * 1000;
const RECONCILE_BATCH = 100;

/// Called by the app when a family opens/resumes it and after a purchase or
/// restore. Re-verifies the signed-in family's entitlement against RevenueCat
/// and corrects `families/{uid}.subscription`, so the rules, the contact gate
/// and every client agree without waiting for (or trusting) the webhook alone.
export const syncSubscription = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', tn('error.signInRequired', 'en'));
  }
  const familyId = request.auth.uid;

  const snap = await admin.firestore().collection('families').doc(familyId).get();
  if (!snap.exists) return { ok: true, configured: revenueCatConfigured(), status: null };

  const verifiedAt = (snap.data()?.subscription as { lastVerifiedAt?: admin.firestore.Timestamp } | undefined)
    ?.lastVerifiedAt;
  if (verifiedAt && Date.now() - verifiedAt.toMillis() < MIN_VERIFY_GAP_MS) {
    return {
      ok: true,
      configured: true,
      status: (snap.data()?.subscription as { status?: string } | undefined)?.status ?? null,
      throttled: true,
    };
  }

  try {
    const r = await reconcileFamily(familyId);
    return { ok: true, configured: r.configured, status: r.status, changed: r.changed };
  } catch (e) {
    console.error(`[syncSubscription] ${familyId}`, e);
    throw new HttpsError('unavailable', 'Could not verify the subscription right now.');
  }
});

/// Safety net: families that still show paid access but have not been verified
/// against the store recently get re-checked. Needs REVENUECAT_API_KEY.
export const subscriptionReconciler = onSchedule('every 24 hours', async () => {
  if (!revenueCatConfigured()) {
    console.warn('[subscriptionReconciler] REVENUECAT_API_KEY not set — skipping');
    return;
  }
  const cutoff = Date.now() - STALE_AFTER_MS;
  // Single-field `in` query (no composite index); the staleness filter runs here.
  const snap = await admin
    .firestore()
    .collection('families')
    .where('subscription.status', 'in', ['active', 'cancelled', 'paymentFailed'])
    .get();
  const stale = snap.docs
    .filter((d) => {
      const at = (d.data().subscription as { lastVerifiedAt?: admin.firestore.Timestamp } | undefined)
        ?.lastVerifiedAt;
      return !at || at.toMillis() < cutoff;
    })
    .slice(0, RECONCILE_BATCH);

  for (const d of stale) {
    try {
      await reconcileFamily(d.id);
    } catch (e) {
      console.error(`[subscriptionReconciler] ${d.id}`, e);
    }
  }
  console.log(`[subscriptionReconciler] re-verified ${stale.length} famil(ies)`);
});
