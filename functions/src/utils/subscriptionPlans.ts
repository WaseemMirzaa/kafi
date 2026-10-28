/// Mirror of the app's SubscriptionConstants (kafi_app/lib/utils/constants/
/// subscription_constants.dart). Keep the two in sync.

/// One-time free nanny unlocks granted to every family. Enforced server-side in
/// `onProfileViewed` — the app's own counter is only a UX convenience.
export const FREE_NANNY_UNLOCK_LIMIT = 3;

export type PlanId = 'weekly' | 'monthly' | 'bimonthly';

export const PLAN_DURATION_DAYS: Record<PlanId, number> = {
  weekly: 7,
  monthly: 30,
  bimonthly: 60,
};

const DAY_MS = 24 * 60 * 60 * 1000;

/// Maps a store product id (e.g. `kafi_weekly_ios`) to a Kafi plan id.
/// Bimonthly is checked first because 'bimonthly' also contains 'monthly'.
export function planFromProductId(productId?: string): PlanId | null {
  const id = (productId ?? '').toLowerCase();
  if (id.includes('bimonth') || id.includes('2month') || id.includes('two_month')) return 'bimonthly';
  if (id.includes('weekly')) return 'weekly';
  if (id.includes('monthly')) return 'monthly';
  return null;
}

/// When access ends for a purchase. RevenueCat's `expiration_at_ms` wins when
/// present (real subscriptions). Kafi plans are non-renewing one-time purchases
/// and that field is not reliably populated for them, so otherwise the end is
/// the purchase time plus the plan's own duration — never a flat default, which
/// would hand a 7-day buyer a month and cut a 60-day buyer short.
/// Returns null when neither the event nor the product id determines an end, so
/// the caller can decide how to degrade rather than silently guessing.
export function computeSubscriptionEndMs(input: {
  expirationAtMs?: unknown;
  purchasedAtMs?: unknown;
  productId?: string;
  nowMs: number;
}): number | null {
  const exp = Number(input.expirationAtMs);
  if (Number.isFinite(exp) && exp > 0) return exp;

  const plan = planFromProductId(input.productId);
  if (!plan) return null;

  const purchased = Number(input.purchasedAtMs);
  const startMs = Number.isFinite(purchased) && purchased > 0 ? purchased : input.nowMs;
  return startMs + PLAN_DURATION_DAYS[plan] * DAY_MS;
}

/// How long a family keeps access after a failed payment while the store
/// retries (the spec's "grace" state: access stays, a banner asks them to fix
/// payment, and only `expired` locks). RevenueCat's own grace expiry wins when
/// it supplies one.
export const GRACE_PERIOD_DAYS = 7;

export function computeGraceEndMs(input: { graceExpirationAtMs?: unknown; nowMs: number }): number {
  const g = Number(input.graceExpirationAtMs);
  if (Number.isFinite(g) && g > input.nowMs) return g;
  return input.nowMs + GRACE_PERIOD_DAYS * DAY_MS;
}
