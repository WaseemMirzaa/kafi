'use strict';
const { test } = require('node:test');
const assert = require('node:assert');
const { isContactEntitled } = require('../lib/triggers/contact.js');

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
