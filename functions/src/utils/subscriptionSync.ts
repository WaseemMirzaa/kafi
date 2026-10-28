import * as admin from 'firebase-admin';
import { computeSubscriptionEndMs, planFromProductId } from './subscriptionPlans';

/// RevenueCat entitlement that unlocks family premium access (mirrors the app's
/// SubscriptionConstants.revenueCatEntitlementId).
export const ENTITLEMENT_ID = 'family_premium';

const FALLBACK_ACCESS_MS = 30 * 24 * 60 * 60 * 1000;

// ───────────────────────── RevenueCat REST ─────────────────────────

/// The secret REST key (`sk_…`) from RevenueCat → API keys. Distinct from the
/// public SDK keys embedded in the app, which must never be used server-side.
export function revenueCatConfigured(): boolean {
  return !!process.env.REVENUECAT_API_KEY;
}

/// Server-side source of truth for "does this app user hold the entitlement
/// right now". Returns null when no REST key is configured.
export async function fetchSubscriber(appUserId: string): Promise<unknown | null> {
  const key = process.env.REVENUECAT_API_KEY;
  if (!key) return null;
  const res = await fetch(
    `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserId)}`,
    { headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' } },
  );
  if (!res.ok) throw new Error(`RevenueCat subscriber lookup failed: HTTP ${res.status}`);
  return ((await res.json()) as { subscriber?: unknown }).subscriber ?? null;
}

export interface EntitlementSnapshot {
  active: boolean;
  productId?: string;
  /// null with active=true means a lifetime / non-expiring grant.
  expiresMs: number | null;
  purchasedMs: number | null;
}

interface RcEntitlement {
  expires_date?: string | null;
  purchase_date?: string | null;
  product_identifier?: string;
}

function parseMs(iso: unknown): number | null {
  if (typeof iso !== 'string') return null;
  const ms = Date.parse(iso);
  return Number.isFinite(ms) ? ms : null;
}

/// Reads the family entitlement out of a RevenueCat `subscriber` object. Falls
/// back to any other active entitlement, like the app does, in case the
/// dashboard id differs slightly. Pure.
export function snapshotFromSubscriber(
  subscriber: unknown,
  nowMs: number,
): EntitlementSnapshot {
  const ents = ((subscriber as { entitlements?: Record<string, RcEntitlement> } | null)
    ?.entitlements ?? {}) as Record<string, RcEntitlement>;
  const toSnap = (e: RcEntitlement): EntitlementSnapshot => {
    const expiresMs = parseMs(e.expires_date);
    return {
      active: expiresMs === null ? true : expiresMs > nowMs,
      productId: e.product_identifier,
      expiresMs,
      purchasedMs: parseMs(e.purchase_date),
    };
  };
  const primary = ents[ENTITLEMENT_ID];
  if (primary) {
    const s = toSnap(primary);
    if (s.active) return s;
  }
  for (const e of Object.values(ents)) {
    const s = toSnap(e);
    if (s.active) return s;
  }
  return primary ? toSnap(primary) : { active: false, expiresMs: null, purchasedMs: null };
}

// ───────────────────────── Decision (pure) ─────────────────────────

export type SyncPlan =
  | { kind: 'activate'; status: 'active' | 'cancelled'; plan: string | null; endMs: number }
  | { kind: 'expire' }
  | { kind: 'none' };

/// What to write after comparing the store's entitlement with Firestore.
/// - Store says active → grant access (a `cancelled` family stays `cancelled`;
///   that status already grants access to the end of the period).
/// - Store says not active but we still show access → expire it now.
/// - Otherwise nothing to do.
export function decideSync(
  currentStatus: string | undefined,
  snap: EntitlementSnapshot,
  nowMs: number,
): SyncPlan {
  if (snap.active) {
    const endMs =
      snap.expiresMs ??
      computeSubscriptionEndMs({
        productId: snap.productId,
        purchasedAtMs: snap.purchasedMs,
        nowMs,
      }) ??
      nowMs + FALLBACK_ACCESS_MS;
    return {
      kind: 'activate',
      status: currentStatus === 'cancelled' ? 'cancelled' : 'active',
      plan: planFromProductId(snap.productId),
      endMs,
    };
  }
  if (currentStatus === 'active' || currentStatus === 'cancelled' || currentStatus === 'paymentFailed') {
    return { kind: 'expire' };
  }
  return { kind: 'none' };
}

export interface TransferableSubscription {
  status?: string;
  plan?: string | null;
  endMs: number | null;
}

/// When RevenueCat moves a purchase between app users and no REST key is
/// available to ask who now owns it, carry the old owner's still-valid plan
/// over to the new one. Picks the latest-ending live plan. Pure.
export function pickTransferableSubscription(
  subs: TransferableSubscription[],
  nowMs: number,
): { plan: string | null; endMs: number } | null {
  let best: { plan: string | null; endMs: number } | null = null;
  for (const s of subs) {
    if (s.status !== 'active' && s.status !== 'cancelled') continue;
    if (s.endMs === null || s.endMs <= nowMs) continue;
    if (!best || s.endMs > best.endMs) best = { plan: s.plan ?? null, endMs: s.endMs };
  }
  return best;
}

// ───────────────────────── Writes ─────────────────────────

type Fields = Record<string, unknown>;

export function activateFields(
  p: { status: 'active' | 'cancelled'; plan: string | null; endMs: number },
  now: Date,
  withStart: boolean,
): Fields {
  return {
    'subscription.status': p.status,
    'subscription.plan': p.plan,
    'subscription.autoRenew': false,
    'subscription.endDate': new Date(p.endMs),
    'subscription.contactsHidden': false,
    'subscription.chatLocked': false,
    'subscription.hasEverSubscribed': true,
    'subscription.lastVerifiedAt': now,
    'subscription.graceEndsAt': admin.firestore.FieldValue.delete(),
    ...(withStart ? { 'subscription.startDate': now } : {}),
  };
}

export function expireFields(now: Date): Fields {
  return {
    'subscription.status': 'expired',
    'subscription.autoRenew': false,
    'subscription.expiredAt': now,
    'subscription.contactsHidden': true,
    'subscription.chatLocked': true,
    'subscription.lastVerifiedAt': now,
    'subscription.graceEndsAt': admin.firestore.FieldValue.delete(),
  };
}

export interface ReconcileResult {
  configured: boolean;
  status: string | null;
  changed: boolean;
}

/// Re-verifies one family against RevenueCat and corrects Firestore. Used when
/// the app opens/resumes, after a purchase or restore, after a TRANSFER, and by
/// the daily reconciler — so a missed or late webhook can never leave a paying
/// family locked or a lapsed one unlocked.
export async function reconcileFamily(familyId: string): Promise<ReconcileResult> {
  if (!revenueCatConfigured()) return { configured: false, status: null, changed: false };

  const ref = admin.firestore().collection('families').doc(familyId);
  const snap = await ref.get();
  if (!snap.exists) return { configured: true, status: null, changed: false };

  const sub = snap.data()?.subscription as
    | { status?: string; mockDev?: boolean }
    | undefined;
  // Dev-only mock entitlement (syncMockSubscription) has no store behind it.
  if (sub?.mockDev === true) return { configured: true, status: sub.status ?? null, changed: false };

  const nowMs = Date.now();
  const now = new Date(nowMs);
  const subscriber = await fetchSubscriber(familyId);
  const plan = decideSync(sub?.status, snapshotFromSubscriber(subscriber, nowMs), nowMs);

  if (plan.kind === 'activate') {
    await ref.update(activateFields(plan, now, sub?.status !== 'active' && sub?.status !== 'cancelled'));
    return { configured: true, status: plan.status, changed: sub?.status !== plan.status };
  }
  if (plan.kind === 'expire') {
    await ref.update(expireFields(now));
    return { configured: true, status: 'expired', changed: true };
  }
  // Nothing to change. Only stamp verification on a family that already has a
  // subscription status: writing a status-less `subscription` map would break
  // the rules' free-tier check (`s.status == 'free'`).
  if (sub?.status) await ref.update({ 'subscription.lastVerifiedAt': now });
  return { configured: true, status: sub?.status ?? null, changed: false };
}
