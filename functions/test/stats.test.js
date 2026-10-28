'use strict';
const { test } = require('node:test');
const assert = require('node:assert');
const { flooredCount, decideProfileView } = require('../lib/triggers/stats.js');

// flooredCount backs the onShortlistDeleted decrement — it must never let a
// server-owned counter go negative, even on out-of-order or duplicate events.
test('decrements a positive counter', () => {
  assert.strictEqual(flooredCount(3, -1), 2);
});

test('floors at zero instead of going negative', () => {
  assert.strictEqual(flooredCount(0, -1), 0);
  assert.strictEqual(flooredCount(-5, -1), 0);
});

test('treats a missing / non-numeric current as zero', () => {
  assert.strictEqual(flooredCount(undefined, -1), 0);
  assert.strictEqual(flooredCount(null, 1), 1);
  assert.strictEqual(flooredCount('nope', 1), 1);
});

test('increments as well', () => {
  assert.strictEqual(flooredCount(2, 1), 3);
});

// decideProfileView is the server-side cap on free unlocks — the app's own
// counter can't be trusted.
test('free family under the cap records a new view', () => {
  assert.strictEqual(decideProfileView({}, 'n1'), 'record');
  assert.strictEqual(
    decideProfileView({ subscription: { status: 'free' }, viewedProfiles: ['a', 'b'] }, 'n1'),
    'record',
  );
});

test('free family at the cap of 3 is refused a 4th unlock', () => {
  assert.strictEqual(decideProfileView({ viewedProfiles: ['a', 'b', 'c'] }, 'n1'), 'limit');
});

test('re-viewing an unlocked nanny is a no-op even at the cap', () => {
  assert.strictEqual(decideProfileView({ viewedProfiles: ['a', 'b', 'c'] }, 'a'), 'already');
});

test('an expired family is never granted unlocks', () => {
  assert.strictEqual(decideProfileView({ subscription: { status: 'expired' } }, 'n1'), 'locked');
});

test('a family in payment grace keeps access and spends nothing', () => {
  assert.strictEqual(
    decideProfileView({ subscription: { status: 'paymentFailed' } }, 'n1'),
    'subscribed',
  );
});

test('subscribers do not spend free unlocks', () => {
  assert.strictEqual(decideProfileView({ subscription: { status: 'active' } }, 'n1'), 'subscribed');
  assert.strictEqual(
    decideProfileView({ subscription: { status: 'cancelled' } }, 'n1'),
    'subscribed',
  );
});

test('non-array viewedProfiles is treated as empty', () => {
  assert.strictEqual(decideProfileView({ viewedProfiles: 'nope' }, 'n1'), 'record');
});
