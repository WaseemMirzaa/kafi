'use strict';
const { test } = require('node:test');
const assert = require('node:assert');
const {
  isContactEntitled,
  isContactLockedOut,
  revealsToRevoke,
} = require('../lib/triggers/contact.js');

// isContactEntitled is the pure gate behind onContactRevealRequested — the
// security-critical decision that lets a family see a nanny's real phone. It
// must match §8: active/cancelled subscription, an active trial with THAT
// nanny, or a spent free contact (nanny already in viewedProfiles).

test('active subscription is entitled', () => {
  assert.strictEqual(isContactEntitled({ subscription: { status: 'active' } }, 'n1'), true);
});

test('cancelled (still-in-period) subscription is entitled', () => {
  assert.strictEqual(isContactEntitled({ subscription: { status: 'cancelled' } }, 'n1'), true);
});

test('expired subscription alone is denied', () => {
  assert.strictEqual(isContactEntitled({ subscription: { status: 'expired' } }, 'n1'), false);
});

test('missing subscription status is denied', () => {
  assert.strictEqual(isContactEntitled({ subscription: {} }, 'n1'), false);
});

test('no subscription and no history is denied', () => {
  assert.strictEqual(isContactEntitled({}, 'n1'), false);
});

test('a spent free contact (viewedProfiles) entitles that nanny only', () => {
  const fam = { viewedProfiles: ['n1', 'n2'] };
  assert.strictEqual(isContactEntitled(fam, 'n1'), true);
  assert.strictEqual(isContactEntitled(fam, 'n3'), false);
});

test('an active trial entitles that nanny only', () => {
  const fam = { activeTrialNannyIds: ['n5'] };
  assert.strictEqual(isContactEntitled(fam, 'n5'), true);
  assert.strictEqual(isContactEntitled(fam, 'n6'), false);
});

test('non-array history fields are handled safely', () => {
  assert.strictEqual(
    isContactEntitled({ viewedProfiles: 'nope', activeTrialNannyIds: 42 }, 'n1'),
    false,
  );
});

// A lapsed plan must not keep previously unlocked phones (Firestore rules'
// familyCanChatWith only honours viewedProfiles on the free tier).
test('expired family does NOT keep a nanny from a spent free contact', () => {
  const fam = { subscription: { status: 'expired' }, viewedProfiles: ['n1'] };
  assert.strictEqual(isContactEntitled(fam, 'n1'), false);
});

test('payment-failed family does NOT keep a spent free contact either', () => {
  const fam = { subscription: { status: 'paymentFailed' }, viewedProfiles: ['n1'] };
  assert.strictEqual(isContactEntitled(fam, 'n1'), false);
});

test('explicit free-tier status still honours a spent free contact', () => {
  const fam = { subscription: { status: 'free' }, viewedProfiles: ['n1'] };
  assert.strictEqual(isContactEntitled(fam, 'n1'), true);
});

test('expired family keeps a nanny it has a live trial with', () => {
  const fam = { subscription: { status: 'expired' }, activeTrialNannyIds: ['n5'] };
  assert.strictEqual(isContactEntitled(fam, 'n5'), true);
});

test('active subscription past its endDate is denied before the enforcer runs', () => {
  const now = 1_000_000;
  const past = { toMillis: () => now - 1 };
  const future = { toMillis: () => now + 1 };
  assert.strictEqual(
    isContactEntitled({ subscription: { status: 'active', endDate: past } }, 'n1', now),
    false,
  );
  assert.strictEqual(
    isContactEntitled({ subscription: { status: 'active', endDate: future } }, 'n1', now),
    true,
  );
});

test('isContactLockedOut flags only a fully expired plan (grace is not lapsed)', () => {
  assert.strictEqual(isContactLockedOut('expired'), true);
  for (const s of ['active', 'cancelled', 'free', 'paymentFailed', undefined]) {
    assert.strictEqual(isContactLockedOut(s), false);
  }
});

test('payment grace keeps contact access until graceEndsAt', () => {
  const now = 5_000_000;
  const open = { subscription: { status: 'paymentFailed', graceEndsAt: { toMillis: () => now + 1 } } };
  const over = { subscription: { status: 'paymentFailed', graceEndsAt: { toMillis: () => now - 1 } } };
  assert.strictEqual(isContactEntitled(open, 'n1', now), true);
  assert.strictEqual(isContactEntitled(over, 'n1', now), false);
});

test('paymentFailed with no grace window is treated as lapsed', () => {
  assert.strictEqual(isContactEntitled({ subscription: { status: 'paymentFailed' } }, 'n1'), false);
});

test('revealsToRevoke takes back everything except live-trial nannies', () => {
  assert.deepStrictEqual(revealsToRevoke(['n1', 'n2', 'n3'], ['n2']), ['n1', 'n3']);
  assert.deepStrictEqual(revealsToRevoke(['n1'], undefined), ['n1']);
  assert.deepStrictEqual(revealsToRevoke([], ['n2']), []);
});
