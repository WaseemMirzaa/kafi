'use strict';
const { test } = require('node:test');
const assert = require('node:assert');
const { buildInboxDoc } = require('../lib/utils/notifications.js');

// buildInboxDoc is the pure shape behind writeInbox — it must stay in lockstep
// with the app's AppNotification.fromMap reader (userId / type / title / body /
// data / read). createdAt is added by writeInbox as a server sentinel.
test('buildInboxDoc carries the fields the inbox reader expects', () => {
  const doc = buildInboxDoc('u1', 'newApplication', 'Title', 'Body', {
    type: 'new_application',
    applicationId: 'a1',
  });
  assert.strictEqual(doc.userId, 'u1');
  assert.strictEqual(doc.type, 'newApplication');
  assert.strictEqual(doc.title, 'Title');
  assert.strictEqual(doc.body, 'Body');
  assert.deepStrictEqual(doc.data, { type: 'new_application', applicationId: 'a1' });
});

test('buildInboxDoc starts unread', () => {
  const doc = buildInboxDoc('u1', 'newMessage', 'T', 'B');
  assert.strictEqual(doc.read, false);
});

test('buildInboxDoc defaults data to an empty object', () => {
  const doc = buildInboxDoc('u1', 'trialCompleted', 'T', 'B');
  assert.deepStrictEqual(doc.data, {});
});
