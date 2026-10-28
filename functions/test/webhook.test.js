'use strict';
const { test } = require('node:test');
const assert = require('node:assert');
const { buildWebhookOutcome } = require('../lib/triggers/webhook.js');
const {
  decideSync,
  snapshotFromSubscriber,
  pickTransferableSubscription,
} = require('../lib/utils/subscriptionSync.js');

const DAY = 24 * 60 * 60 * 1000;
const NOW = 1_800_000_000_000;
const apply = (event, fam = {}) => buildWebhookOutcome(event, fam, NOW);

test('non-renewing purchase grants the plan duration, not a flat 30 days', () => {
  const weekly = apply({ type: 'NON_RENEWING_PURCHASE', product_id: 'kafi_weekly', purchased_at_ms: NOW });
  assert.strictEqual(weekly.kind, 'apply');
  assert.strictEqual(weekly.update['subscription.status'], 'active');
  assert.strictEqual(weekly.update['subscription.plan'], 'weekly');
  assert.strictEqual(weekly.update['subscription.endDate'].getTime(), NOW + 7 * DAY);
  const bi = apply({ type: 'NON_RENEWING_PURCHASE', product_id: 'kafi_bimonthly', purchased_at_ms: NOW });
  assert.strictEqual(bi.update['subscription.endDate'].getTime(), NOW + 60 * DAY);
});

test('a refund (CANCELLATION / CUSTOMER_SUPPORT) expires immediately', () => {
  const o = apply({ type: 'CANCELLATION', cancel_reason: 'CUSTOMER_SUPPORT' });
  assert.strictEqual(o.update['subscription.status'], 'expired');
  assert.strictEqual(o.update['subscription.contactsHidden'], true);
  assert.strictEqual(o.update['subscription.chatLocked'], true);
});

test('an ordinary cancellation keeps access until the period ends', () => {
  const o = apply({ type: 'CANCELLATION', cancel_reason: 'UNSUBSCRIBE' });
  assert.strictEqual(o.update['subscription.status'], 'cancelled');
  assert.strictEqual(o.update['subscription.chatLocked'], undefined);
});

test('EXPIRATION locks contacts and chat', () => {
  const o = apply({ type: 'EXPIRATION' });
  assert.strictEqual(o.update['subscription.status'], 'expired');
  assert.strictEqual(o.update['subscription.chatLocked'], true);
});

test('a replayed event id is skipped', () => {
  const fam = { subscription: { lastEventId: 'evt1', lastEventAtMs: NOW } };
  assert.strictEqual(apply({ id: 'evt1', type: 'EXPIRATION', event_timestamp_ms: NOW }, fam).kind, 'skip');
});

test('an out-of-order older event cannot undo a newer one', () => {
  const fam = { subscription: { status: 'expired', lastEventId: 'evt2', lastEventAtMs: NOW } };
  const stale = apply(
    { id: 'evt1', type: 'INITIAL_PURCHASE', product_id: 'kafi_monthly', event_timestamp_ms: NOW - 1000 },
    fam,
  );
  assert.strictEqual(stale.kind, 'skip');
  const fresh = apply(
    { id: 'evt3', type: 'INITIAL_PURCHASE', product_id: 'kafi_monthly', event_timestamp_ms: NOW + 1000 },
    fam,
  );
  assert.strictEqual(fresh.kind, 'apply');
  assert.strictEqual(fresh.update['subscription.lastEventId'], 'evt3');
});

test('PRODUCT_CHANGE maps to a plan id and never invents an end date', () => {
  const o = apply({ type: 'PRODUCT_CHANGE', new_product_id: 'kafi_bimonthly' });
  assert.strictEqual(o.update['subscription.plan'], 'bimonthly');
  assert.strictEqual('subscription.endDate' in o.update, false);
  const withEnd = apply({ type: 'PRODUCT_CHANGE', product_id: 'kafi_weekly', expiration_at_ms: NOW + DAY });
  assert.strictEqual(withEnd.update['subscription.endDate'].getTime(), NOW + DAY);
});

test('unhandled event types are skipped, not errors', () => {
  assert.strictEqual(apply({ type: 'TEST' }).kind, 'skip');
});

test('BILLING_ISSUE starts grace: keeps access, bounded window, nothing locked', () => {
  const o = apply({ type: 'BILLING_ISSUE' });
  assert.strictEqual(o.update['subscription.status'], 'paymentFailed');
  assert.strictEqual(o.update['subscription.graceEndsAt'].getTime(), NOW + 7 * DAY);
  assert.strictEqual(o.update['subscription.chatLocked'], undefined);
  assert.strictEqual(o.update['subscription.contactsHidden'], undefined);
  const withExp = apply({ type: 'BILLING_ISSUE', grace_period_expiration_at_ms: NOW + 3 * DAY });
  assert.strictEqual(withExp.update['subscription.graceEndsAt'].getTime(), NOW + 3 * DAY);
});

// ── store reconciliation ──
const iso = (ms) => new Date(ms).toISOString();

test('snapshotFromSubscriber reads the family entitlement', () => {
  const sub = { entitlements: { family_premium: {
    product_identifier: 'kafi_monthly', purchase_date: iso(NOW), expires_date: iso(NOW + 30 * DAY) } } };
  const s = snapshotFromSubscriber(sub, NOW);
  assert.strictEqual(s.active, true);
  assert.strictEqual(s.expiresMs, NOW + 30 * DAY);
});

test('snapshotFromSubscriber: expired / missing / lifetime', () => {
  const lapsed = { entitlements: { family_premium: { expires_date: iso(NOW - DAY) } } };
  assert.strictEqual(snapshotFromSubscriber(lapsed, NOW).active, false);
  assert.strictEqual(snapshotFromSubscriber({}, NOW).active, false);
  assert.strictEqual(snapshotFromSubscriber(null, NOW).active, false);
  const lifetime = { entitlements: { family_premium: { product_identifier: 'kafi_weekly', expires_date: null } } };
  const s = snapshotFromSubscriber(lifetime, NOW);
  assert.strictEqual(s.active, true);
  assert.strictEqual(s.expiresMs, null);
});

test('decideSync grants, keeps cancelled, expires, or does nothing', () => {
  const active = { active: true, productId: 'kafi_weekly', expiresMs: NOW + DAY, purchasedMs: NOW };
  assert.deepStrictEqual(decideSync('free', active, NOW),
    { kind: 'activate', status: 'active', plan: 'weekly', endMs: NOW + DAY });
  assert.strictEqual(decideSync('cancelled', active, NOW).status, 'cancelled');
  const none = { active: false, expiresMs: null, purchasedMs: null };
  assert.deepStrictEqual(decideSync('active', none, NOW), { kind: 'expire' });
  assert.deepStrictEqual(decideSync('paymentFailed', none, NOW), { kind: 'expire' });
  assert.deepStrictEqual(decideSync('free', none, NOW), { kind: 'none' });
  assert.deepStrictEqual(decideSync(undefined, none, NOW), { kind: 'none' });
  assert.deepStrictEqual(decideSync('expired', none, NOW), { kind: 'none' });
});

test('a lifetime-style grant still gets a plan-length end date', () => {
  const grant = { active: true, productId: 'kafi_bimonthly', expiresMs: null, purchasedMs: NOW };
  assert.strictEqual(decideSync('free', grant, NOW).endMs, NOW + 60 * DAY);
});

test('pickTransferableSubscription carries the longest live plan', () => {
  const subs = [
    { status: 'active', plan: 'weekly', endMs: NOW + 2 * DAY },
    { status: 'cancelled', plan: 'monthly', endMs: NOW + 20 * DAY },
    { status: 'active', plan: 'weekly', endMs: NOW - DAY },
    { status: 'expired', plan: 'monthly', endMs: NOW + 40 * DAY },
  ];
  assert.deepStrictEqual(pickTransferableSubscription(subs, NOW), { plan: 'monthly', endMs: NOW + 20 * DAY });
  assert.strictEqual(pickTransferableSubscription([], NOW), null);
});
