import { onRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { sendNotification, writeInbox, InboxType, getUser } from '../utils/notifications';
import { NotificationKey, tn } from '../i18n/notifications';
import { computeGraceEndMs, computeSubscriptionEndMs, planFromProductId } from '../utils/subscriptionPlans';
import {
  activateFields,
  expireFields,
  pickTransferableSubscription,
  reconcileFamily,
  revenueCatConfigured,
} from '../utils/subscriptionSync';

const FALLBACK_ACCESS_MS = 30 * 24 * 60 * 60 * 1000;

type Fields = Record<string, unknown>;
export interface WebhookNotification {
  keyPrefix: string;
  type: InboxType;
}
export type WebhookOutcome =
  | { kind: 'apply'; update: Fields; notification: WebhookNotification | null }
  | { kind: 'skip'; reason: string };

/// RevenueCat marks a refund (Apple/Google support) as CANCELLATION with this
/// cancel_reason. A plain cancellation keeps access to the end of the period; a
/// refund must not.
const REFUND_CANCEL_REASON = 'CUSTOMER_SUPPORT';

function isAnonymousId(id: unknown): boolean {
  return typeof id === 'string' && id.startsWith('$RCAnonymousID');
}

/// Decides what a single (non-TRANSFER) RevenueCat event does to a family doc.
/// Pure — no Firestore — so the ordering, refund and end-date rules can be unit
/// tested. `fam` is the current family doc data.
export function buildWebhookOutcome(
  event: Record<string, any>,
  fam: { subscription?: Fields | null },
  nowMs: number,
): WebhookOutcome {
  const sub = (fam.subscription ?? {}) as Fields;

  // RevenueCat retries and can deliver out of order. Ignore an event we have
  // already applied, or one older than the last applied — otherwise a late
  // INITIAL_PURCHASE could undo a newer EXPIRATION.
  if (event.id && sub.lastEventId === event.id) {
    return { kind: 'skip', reason: 'duplicate event' };
  }
  const eventTs = Number(event.event_timestamp_ms);
  const lastTs = Number(sub.lastEventAtMs);
  if (Number.isFinite(eventTs) && Number.isFinite(lastTs) && eventTs < lastTs) {
    return { kind: 'skip', reason: 'older than the last applied event' };
  }

  const now = new Date(nowMs);
  let update: Fields = {};
  let notification: WebhookNotification | null = null;

  switch (event.type) {
    // Kafi plans are non-renewing one-time purchases, which RevenueCat reports
    // as NON_RENEWING_PURCHASE.
    case 'NON_RENEWING_PURCHASE':
    case 'INITIAL_PURCHASE':
    case 'RENEWAL': {
      // Non-renewing purchases carry no reliable expiration_at_ms, so the end
      // date comes from the plan's own duration (7 / 30 / 60 days).
      let endMs = computeSubscriptionEndMs({
        expirationAtMs: event.expiration_at_ms,
        purchasedAtMs: event.purchased_at_ms,
        productId: event.product_id,
        nowMs,
      });
      if (endMs === null) {
        console.warn(
          `[revenueCatWebhook] cannot derive access end for product "${event.product_id}" ` +
            `— falling back to 30 days`,
        );
        endMs = nowMs + FALLBACK_ACCESS_MS;
      }
      update = activateFields(
        { status: 'active', plan: planFromProductId(event.product_id), endMs },
        now,
        true,
      );
      notification = { keyPrefix: 'subscription.active', type: 'subscriptionRenewed' };
      break;
    }

    case 'CANCELLATION':
      if (event.cancel_reason === REFUND_CANCEL_REASON) {
        update = expireFields(now);
        notification = { keyPrefix: 'subscription.expiredWebhook', type: 'subscriptionExpired' };
      } else {
        update = { 'subscription.status': 'cancelled', 'subscription.autoRenew': false };
        notification = { keyPrefix: 'subscription.cancelled', type: 'systemAnnouncement' };
      }
      break;

    case 'EXPIRATION':
      update = expireFields(now);
      notification = { keyPrefix: 'subscription.expiredWebhook', type: 'subscriptionExpired' };
      break;

    case 'BILLING_ISSUE':
      // Grace: the spec keeps access while the store retries the payment, so
      // nothing is locked here. The hourly enforcer expires the family if the
      // grace window closes without a recovery.
      update = {
        'subscription.status': 'paymentFailed',
        'subscription.graceEndsAt': new Date(
          computeGraceEndMs({ graceExpirationAtMs: event.grace_period_expiration_at_ms, nowMs }),
        ),
      };
      notification = { keyPrefix: 'subscription.paymentFailed', type: 'systemAnnouncement' };
      break;

    case 'UNCANCELLATION':
      update = { 'subscription.status': 'active', 'subscription.autoRenew': true };
      notification = { keyPrefix: 'subscription.resumed', type: 'subscriptionRenewed' };
      break;

    case 'PRODUCT_CHANGE': {
      // Map to a Kafi plan id like every other path, and only move the end date
      // when RevenueCat actually supplies one — never invent a default.
      const plan = planFromProductId(event.new_product_id || event.product_id);
      update = {
        'subscription.plan': plan,
        'subscription.lastRenewalAt': now,
      };
      const exp = Number(event.expiration_at_ms);
      if (Number.isFinite(exp) && exp > 0) update['subscription.endDate'] = new Date(exp);
      notification = { keyPrefix: 'subscription.planUpdated', type: 'systemAnnouncement' };
      break;
    }

    default:
      return { kind: 'skip', reason: `event type ${event.type} not handled` };
  }

  if (event.id) update['subscription.lastEventId'] = event.id;
  if (Number.isFinite(eventTs)) update['subscription.lastEventAtMs'] = eventTs;
  return { kind: 'apply', update, notification };
}

/// RevenueCat moved a purchase between app users (shared phone, restore, or an
/// anonymous → logged-in alias). The old owner must lose access and the new one
/// gain it. With a REST key we just re-verify both against the store; without
/// one we carry the old owner's still-valid plan across.
async function handleTransfer(event: Record<string, any>): Promise<void> {
  const db = admin.firestore();
  const ids = (v: unknown): string[] =>
    (Array.isArray(v) ? (v as unknown[]) : []).filter(
      (x): x is string => typeof x === 'string' && x.length > 0 && !isAnonymousId(x),
    );
  const from = ids(event.transferred_from);
  const to = ids(event.transferred_to);

  if (revenueCatConfigured()) {
    for (const id of [...from, ...to]) {
      try {
        await reconcileFamily(id);
      } catch (e) {
        console.error(`[revenueCatWebhook] TRANSFER reconcile failed for ${id}`, e);
      }
    }
    return;
  }

  const now = new Date();
  const nowMs = now.getTime();
  const donors: Array<{ status?: string; plan?: string | null; endMs: number | null }> = [];
  for (const id of from) {
    const ref = db.collection('families').doc(id);
    const snap = await ref.get();
    if (!snap.exists) continue;
    const sub = snap.data()?.subscription as
      | { status?: string; plan?: string | null; endDate?: { toMillis?: () => number } }
      | undefined;
    donors.push({
      status: sub?.status,
      plan: sub?.plan ?? null,
      endMs: typeof sub?.endDate?.toMillis === 'function' ? sub.endDate.toMillis() : null,
    });
    await ref.update(expireFields(now));
  }
  const carried = pickTransferableSubscription(donors, nowMs);
  if (!carried) return;
  for (const id of to) {
    const ref = db.collection('families').doc(id);
    if (!(await ref.get()).exists) continue;
    await ref.update(activateFields({ status: 'active', ...carried }, now, true));
  }
}

// Public at the IAM layer so RevenueCat can reach it; the shared secret below
// is the real authentication.
export const revenueCatWebhook = onRequest({ invoker: 'public' }, async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  // Per System Spec §8.3 the RevenueCat webhook MUST be authenticated.
  // Require the shared secret unconditionally — refuse to start if it isn't
  // set in the deployment environment so we never accept anonymous webhooks
  // in production.
  const sharedSecret = process.env.REVENUECAT_WEBHOOK_SECRET;
  if (!sharedSecret) {
    console.error(
      '[revenueCatWebhook] REVENUECAT_WEBHOOK_SECRET is not configured — rejecting request',
    );
    res.status(500).send('Server misconfigured');
    return;
  }
  const auth = req.headers.authorization || '';
  const token = auth.startsWith('Bearer ') ? auth.substring(7) : auth;
  if (token !== sharedSecret) {
    res.status(401).send('Unauthorized');
    return;
  }

  const event = req.body?.event;
  if (!event) {
    res.status(400).send('Missing event');
    return;
  }

  // TRANSFER names its users in transferred_from / transferred_to and carries
  // no app_user_id of its own.
  if (event.type === 'TRANSFER') {
    await handleTransfer(event);
    res.status(200).send('OK');
    return;
  }

  const familyId = event.app_user_id;
  if (!familyId) {
    res.status(400).send('Missing app_user_id');
    return;
  }

  // Anonymous RevenueCat ids and users with no family doc (e.g. a nanny, or the
  // dashboard's TEST event) can never be applied, so answer 200: RevenueCat
  // retries every non-200 and a retry would never succeed.
  const familyRef = admin.firestore().collection('families').doc(familyId);
  if (isAnonymousId(familyId)) {
    res.status(200).send('Ignored: anonymous user');
    return;
  }

  const outcome = await admin.firestore().runTransaction(async (tx): Promise<WebhookOutcome> => {
    const snap = await tx.get(familyRef);
    if (!snap.exists) return { kind: 'skip', reason: 'family not found' };
    const result = buildWebhookOutcome(event, snap.data() ?? {}, Date.now());
    if (result.kind === 'apply') tx.update(familyRef, result.update);
    return result;
  });

  if (outcome.kind === 'skip') {
    console.log(`[revenueCatWebhook] ${event.type} for ${familyId} skipped: ${outcome.reason}`);
    res.status(200).send(`Skipped: ${outcome.reason}`);
    return;
  }

  const { notification } = outcome;
  if (notification) {
    const data = { type: `subscription_${String(event.type).toLowerCase()}` };
    // The family doc never carries fcmTokens (only `users/{uid}` does — see
    // fcm_notification_service.dart), and locale lives on the user doc too,
    // so resolve both from there rather than the family snapshot.
    const user = await getUser(familyId);
    const locale = user.locale ?? 'en';
    const title = tn(`${notification.keyPrefix}.title` as NotificationKey, locale);
    const body = tn(`${notification.keyPrefix}.body` as NotificationKey, locale);
    // Durable inbox record (survives a missing FCM token), then the live push.
    await writeInbox(familyId, notification.type, title, body, data);
    if (user.fcmTokens?.length) {
      await sendNotification(user.fcmTokens, { title, body, data });
    }
  }

  res.status(200).send('OK');
});
