'use strict';
const { test } = require('node:test');
const assert = require('node:assert');
const { flooredCount, nextAverage, revieweeCollection } = require('../lib/triggers/stats.js');

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

// nextAverage folds a new rating into a nanny's running review average.
test('nextAverage: first review seeds the average', () => {
  assert.deepStrictEqual(nextAverage(undefined, undefined, 4), {
    averageRating: 4,
    reviewsCount: 1,
  });
});

test('nextAverage: folds into an existing average and rounds to 2dp', () => {
  // (4.5*2 + 3) / 3 = 4.0
  assert.deepStrictEqual(nextAverage(4.5, 2, 3), { averageRating: 4, reviewsCount: 3 });
  // (5*1 + 4) / 2 = 4.5
  assert.deepStrictEqual(nextAverage(5, 1, 4), { averageRating: 4.5, reviewsCount: 2 });
});

test('nextAverage: tolerates garbage current values', () => {
  assert.deepStrictEqual(nextAverage(null, 'x', 5), { averageRating: 5, reviewsCount: 1 });
});

// revieweeCollection routes two-way reviews to the right aggregate doc.
test('revieweeCollection maps nanny/family to their collections', () => {
  assert.strictEqual(revieweeCollection('nanny'), 'nannies');
  assert.strictEqual(revieweeCollection('family'), 'families');
});

test('revieweeCollection returns undefined for unknown types', () => {
  assert.strictEqual(revieweeCollection('admin'), undefined);
  assert.strictEqual(revieweeCollection(undefined), undefined);
  assert.strictEqual(revieweeCollection(''), undefined);
});
