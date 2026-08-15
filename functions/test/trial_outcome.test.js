'use strict';
const { test } = require('node:test');
const assert = require('node:assert');
const { resolveMutualOutcome } = require('../lib/triggers/trial.js');
const { isTrialDueForOutcome } = require('../lib/triggers/scheduled.js');

// resolveMutualOutcome backs onTrialOutcomeResolved — the mutual-confirm truth
// table (plan §2.3). notHired on EITHER side wins outright (the mismatch
// case), both sides must say hired for a match, and anything else (a side
// hasn't responded yet) stays pending.

test('both hired resolves to hired', () => {
  assert.strictEqual(resolveMutualOutcome('hired', 'hired'), 'hired');
});

test('family hired + nanny notHired resolves to notHired', () => {
  assert.strictEqual(resolveMutualOutcome('hired', 'notHired'), 'notHired');
});

test('family notHired + nanny hired resolves to notHired (the mismatch case)', () => {
  assert.strictEqual(resolveMutualOutcome('notHired', 'hired'), 'notHired');
});

test('both notHired resolves to notHired', () => {
  assert.strictEqual(resolveMutualOutcome('notHired', 'notHired'), 'notHired');
});

test('family hired, nanny silent stays pending', () => {
  assert.strictEqual(resolveMutualOutcome('hired', undefined), 'pending');
});

test('nanny hired, family silent stays pending', () => {
  assert.strictEqual(resolveMutualOutcome(undefined, 'hired'), 'pending');
});

test('both silent stays pending', () => {
  assert.strictEqual(resolveMutualOutcome(undefined, undefined), 'pending');
});

// isTrialDueForOutcome backs the trialOutcomeDetector scheduled function —
// due only when the trial is active, its endDate has passed, and it hasn't
// already been prompted (outcomePromptSent idempotency flag, mirrors
// trialStartingReminder's reminderSent). endDate is exercised as a
// Timestamp-shaped object (`{ toMillis }`) since that's what a real Firestore
// read hands back; a plain Date is covered separately since the signature
// explicitly accepts either.

const NOW_MS = Date.parse('2024-01-15T12:00:00.000Z');
const timestamp = (ms) => ({ toMillis: () => ms });

test('due when active, endDate in the past, and not yet prompted', () => {
  const trial = { status: 'active', endDate: timestamp(NOW_MS - 1000) };
  assert.strictEqual(isTrialDueForOutcome(trial, NOW_MS), true);
});

test('not due when status is not active', () => {
  const trial = { status: 'awaitingOutcome', endDate: timestamp(NOW_MS - 1000) };
  assert.strictEqual(isTrialDueForOutcome(trial, NOW_MS), false);
});

test('not due when endDate is in the future', () => {
  const trial = { status: 'active', endDate: timestamp(NOW_MS + 1000) };
  assert.strictEqual(isTrialDueForOutcome(trial, NOW_MS), false);
});

test('not due when outcomePromptSent is already true', () => {
  const trial = {
    status: 'active',
    endDate: timestamp(NOW_MS - 1000),
    outcomePromptSent: true,
  };
  assert.strictEqual(isTrialDueForOutcome(trial, NOW_MS), false);
});

test('boundary: due when endDate is exactly now', () => {
  const trial = { status: 'active', endDate: timestamp(NOW_MS) };
  assert.strictEqual(isTrialDueForOutcome(trial, NOW_MS), true);
});

test('boundary: due when endDate is one ms past', () => {
  const trial = { status: 'active', endDate: timestamp(NOW_MS - 1) };
  assert.strictEqual(isTrialDueForOutcome(trial, NOW_MS), true);
});

test('accepts a native Date for endDate too', () => {
  const trial = { status: 'active', endDate: new Date(NOW_MS - 1000) };
  assert.strictEqual(isTrialDueForOutcome(trial, NOW_MS), true);
});

test('not due when endDate is missing', () => {
  const trial = { status: 'active' };
  assert.strictEqual(isTrialDueForOutcome(trial, NOW_MS), false);
});
