'use strict';
const { test } = require('node:test');
const assert = require('node:assert');
const {
  computeSubscriptionEndMs,
  planFromProductId,
  FREE_NANNY_UNLOCK_LIMIT,
  computeGraceEndMs,
  GRACE_PERIOD_DAYS,
} = require('../lib/utils/subscriptionPlans.js');

const DAY = 24 * 60 * 60 * 1000;
const NOW = 1_700_000_000_000;

test('free unlock limit matches the app (3)', () => {
  assert.strictEqual(FREE_NANNY_UNLOCK_LIMIT, 3);
});

test('planFromProductId maps store ids, bimonthly before monthly', () => {
  assert.strictEqual(planFromProductId('kafi_weekly'), 'weekly');
  assert.strictEqual(planFromProductId('kafi_weekly_ios'), 'weekly');
  assert.strictEqual(planFromProductId('kafi_monthly'), 'monthly');
  assert.strictEqual(planFromProductId('kafi_bimonthly'), 'bimonthly');
  assert.strictEqual(planFromProductId('something_else'), null);
  assert.strictEqual(planFromProductId(undefined), null);
});

test('without expiration_at_ms each plan gets its own duration', () => {
  const end = (productId) =>
    computeSubscriptionEndMs({ productId, purchasedAtMs: NOW, nowMs: NOW + 5 * DAY });
  assert.strictEqual(end('kafi_weekly'), NOW + 7 * DAY);
  assert.strictEqual(end('kafi_monthly'), NOW + 30 * DAY);
  assert.strictEqual(end('kafi_bimonthly'), NOW + 60 * DAY);
});

test('duration counts from the purchase time, falling back to now', () => {
  assert.strictEqual(
    computeSubscriptionEndMs({ productId: 'kafi_weekly', nowMs: NOW }),
    NOW + 7 * DAY,
  );
});

test('a real expiration_at_ms always wins', () => {
  assert.strictEqual(
    computeSubscriptionEndMs({
      expirationAtMs: NOW + 99 * DAY,
      productId: 'kafi_weekly',
      purchasedAtMs: NOW,
      nowMs: NOW,
    }),
    NOW + 99 * DAY,
  );
});

test('null / zero expiration is ignored, unknown product yields null', () => {
  assert.strictEqual(
    computeSubscriptionEndMs({ expirationAtMs: null, productId: 'kafi_weekly', nowMs: NOW }),
    NOW + 7 * DAY,
  );
  assert.strictEqual(computeSubscriptionEndMs({ productId: 'mystery', nowMs: NOW }), null);
});

test('grace window uses RevenueCat expiry when given, else 7 days', () => {
  assert.strictEqual(GRACE_PERIOD_DAYS, 7);
  assert.strictEqual(computeGraceEndMs({ nowMs: NOW }), NOW + 7 * DAY);
  assert.strictEqual(computeGraceEndMs({ graceExpirationAtMs: NOW + 3 * DAY, nowMs: NOW }), NOW + 3 * DAY);
  // a stale / past value from RevenueCat must not shorten grace to nothing
  assert.strictEqual(computeGraceEndMs({ graceExpirationAtMs: NOW - DAY, nowMs: NOW }), NOW + 7 * DAY);
});
