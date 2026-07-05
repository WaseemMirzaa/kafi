'use strict';
const { test } = require('node:test');
const assert = require('node:assert');
const { computeTranslationUpdates, i18nKey } = require('../lib/utils/translate.js');

// A fake provider so the loop-safety / diff logic is tested without the Cloud
// Translation API: detection always returns 'en', translation tags the target.
const cfg = { fields: ['bio'], langs: ['en', 'ar'] };
const provider = {
  detect: async () => 'en',
  translate: async (text, target) => `[${target}] ${text}`,
};

test('translates a newly-added field into every language', async () => {
  const u = await computeTranslationUpdates(undefined, { bio: 'Loves kids' }, cfg, provider);
  assert.deepStrictEqual(u, { bio_i18n: { en: 'Loves kids', ar: '[ar] Loves kids' } });
});

test('no-op when source is unchanged and the map is complete (loop-safe)', async () => {
  const complete = { bio: 'Loves kids', bio_i18n: { en: 'Loves kids', ar: '[ar] Loves kids' } };
  const u = await computeTranslationUpdates({ bio: 'Loves kids' }, complete, cfg, provider);
  assert.deepStrictEqual(u, {});
});

test('re-translates when the source text is edited', async () => {
  const before = { bio: 'Loves kids', bio_i18n: { en: 'Loves kids', ar: '[ar] Loves kids' } };
  const after = { ...before, bio: 'Great cook' };
  const u = await computeTranslationUpdates(before, after, cfg, provider);
  assert.deepStrictEqual(u, { bio_i18n: { en: 'Great cook', ar: '[ar] Great cook' } });
});

test('re-translates when the map is missing a language', async () => {
  const before = { bio: 'Loves kids', bio_i18n: { en: 'Loves kids' } };
  const u = await computeTranslationUpdates(before, { ...before }, cfg, provider);
  assert.deepStrictEqual(u, { bio_i18n: { en: 'Loves kids', ar: '[ar] Loves kids' } });
});

test('skips empty / whitespace-only source', async () => {
  const u = await computeTranslationUpdates(undefined, { bio: '   ' }, cfg, provider);
  assert.deepStrictEqual(u, {});
});

test('translates several fields independently', async () => {
  const multi = { fields: ['bio', 'houseRules'], langs: ['en', 'ar'] };
  const u = await computeTranslationUpdates(
    { bio: 'x', bio_i18n: { en: 'x', ar: '[ar] x' } }, // bio unchanged+complete → skipped
    { bio: 'x', bio_i18n: { en: 'x', ar: '[ar] x' }, houseRules: 'No smoking' },
    multi,
    provider,
  );
  assert.deepStrictEqual(u, { houseRules_i18n: { en: 'No smoking', ar: '[ar] No smoking' } });
});

test('i18nKey suffixes the field name', () => {
  assert.strictEqual(i18nKey('bio'), 'bio_i18n');
});
