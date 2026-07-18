'use strict';
const { test } = require('node:test');
const assert = require('node:assert');
const { flooredCount } = require('../lib/triggers/stats.js');

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
