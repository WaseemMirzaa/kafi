'use strict';
const { test } = require('node:test');
const assert = require('node:assert');
const { availabilityKey } = require('../lib/utils/nannyBrowseVisibility.js');

// Same cases as kafi_app/test/utils/nanny_listing_activity_test.dart — the app
// and this function must compute an identical availability fingerprint.
const cases = [
  [{}, 'availableNow|'],
  [{ availability: 'availableNow' }, 'availableNow|'],
  [{ availability: 'onTrial' }, 'onTrial|'],
  [{ availability: 'availableNow', availableFrom: '2026-01-01' }, 'availableNow|'],
  [{ availability: 'availableFrom', availableFrom: '2026-12-01T00:00:00.000' }, 'availableFrom|2026-12-01'],
  [{ availability: 'availableFrom', availableFrom: '2026-12-01T23:59:59.000Z' }, 'availableFrom|2026-12-01'],
  [{ availability: 'availableFrom' }, 'availableFrom|'],
];

for (const [input, expected] of cases) {
  test(`${JSON.stringify(input)} -> ${expected}`, () => {
    assert.strictEqual(availabilityKey(input), expected);
  });
}

test('a Firestore Timestamp is read as its UTC calendar date', () => {
  const ts = { toDate: () => new Date(Date.UTC(2026, 11, 1, 8)) };
  assert.strictEqual(
    availabilityKey({ availability: 'availableFrom', availableFrom: ts }),
    'availableFrom|2026-12-01',
  );
});

const { nannyIdsToReconcile } = require('../lib/utils/nannyBrowseVisibility.js');

test('reconcile set = active-hire nannies + still-flagged nannies, de-duplicated', () => {
  assert.deepStrictEqual(
    nannyIdsToReconcile(['a', 'b', 'a'], ['b', 'c']).sort(),
    ['a', 'b', 'c'],
  );
});

test('reconcile set ignores missing ids', () => {
  assert.deepStrictEqual(nannyIdsToReconcile([undefined, null, '', 'x'], []), ['x']);
  assert.deepStrictEqual(nannyIdsToReconcile([], []), []);
});
