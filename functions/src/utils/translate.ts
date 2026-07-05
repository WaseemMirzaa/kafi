import { v2 } from '@google-cloud/translate';

/**
 * Translation-aware user content (System Spec: bilingual en/ar app).
 *
 * Free-text profile/job fields are stored as the original string plus a sibling
 * `<field>_i18n` map ({ en, ar }). The `translate*` triggers keep those maps in
 * sync whenever the source text is added or edited, using the Cloud Translation
 * API. The original field remains the source of truth (backward compatible).
 */

/** App languages we maintain translations for. */
export const APP_LANGS = ['en', 'ar'] as const;

/** The translatable free-text fields per collection (System Spec §3.2–§3.4). */
export interface TranslateConfig {
  fields: string[];
  langs: string[];
}

export const NANNY_TX: TranslateConfig = {
  fields: ['bio', 'healthConditions', 'religiousNotes'],
  langs: [...APP_LANGS],
};
export const FAMILY_TX: TranslateConfig = {
  fields: ['aboutFamily', 'houseRules'],
  langs: [...APP_LANGS],
};
export const JOB_TX: TranslateConfig = {
  fields: ['jobTitle', 'schedule', 'additionalNotes'],
  langs: [...APP_LANGS],
};

/** The `_i18n` suffix appended to a translatable field's original name. */
export const i18nKey = (field: string): string => `${field}_i18n`;

/** Abstracts the translation backend so the orchestration is unit-testable. */
export interface TranslationProvider {
  /** Detects the language code (e.g. 'en', 'ar') of `text`. */
  detect(text: string): Promise<string>;
  /** Translates `text` into `target` and returns the translated string. */
  translate(text: string, target: string): Promise<string>;
}

/**
 * Diffs a Firestore write and returns the `<field>_i18n` updates needed to keep
 * translations in sync — empty when nothing changed. Pure (no I/O beyond the
 * injected [provider]) so it can be tested without the Cloud Translation API.
 *
 * A field is (re)translated when its source text is non-empty AND either it
 * changed since the previous version OR its `_i18n` map is missing/incomplete.
 * When only the `_i18n` maps changed (our own write-back), the source is
 * unchanged and the map is complete, so nothing is produced — this is what
 * stops the trigger from looping on itself.
 */
export async function computeTranslationUpdates(
  before: Record<string, unknown> | undefined,
  after: Record<string, unknown>,
  cfg: TranslateConfig,
  provider: TranslationProvider,
): Promise<Record<string, Record<string, string>>> {
  const updates: Record<string, Record<string, string>> = {};

  for (const field of cfg.fields) {
    const src = String(after[field] ?? '').trim();
    if (!src) continue;

    const prevSrc = String(before?.[field] ?? '').trim();
    const existing = after[i18nKey(field)] as Record<string, string> | undefined;
    const complete =
      !!existing && cfg.langs.every((l) => typeof existing[l] === 'string' && existing[l].length > 0);

    // Unchanged source with a complete map → nothing to do (loop guard).
    if (src === prevSrc && complete) continue;

    const srcLang = await provider.detect(src);
    const map: Record<string, string> = { [srcLang]: src };
    for (const lang of cfg.langs) {
      if (lang === srcLang) continue;
      map[lang] = await provider.translate(src, lang);
    }
    updates[i18nKey(field)] = map;
  }

  return updates;
}

/** Lazily-created Cloud Translation client (uses the function's ADC / project). */
let _client: v2.Translate | null = null;

/** A [TranslationProvider] backed by Google Cloud Translation API v2. */
export function googleProvider(): TranslationProvider {
  const client = (_client ??= new v2.Translate());
  return {
    detect: async (text) => {
      const [result] = await client.detect(text);
      const r = Array.isArray(result) ? result[0] : result;
      return r.language;
    },
    translate: async (text, target) => {
      const [translated] = await client.translate(text, target);
      return translated;
    },
  };
}
