import { en, TranslationKey } from './en';
import { ar } from './ar';

export type { TranslationKey };

export type Locale = 'en' | 'ar';

const dictionaries: Record<Locale, Record<TranslationKey, string>> = { en, ar };

const STORAGE_KEY = 'kafi_admin_locale';

function readStoredLocale(): Locale {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw === 'ar' ? 'ar' : 'en';
  } catch {
    return 'en';
  }
}

let currentLocale: Locale = readStoredLocale();
const listeners = new Set<() => void>();

export function getLocale(): Locale {
  return currentLocale;
}

/** Text direction for the current locale — Arabic renders right-to-left. */
export function getDirection(locale: Locale = currentLocale): 'ltr' | 'rtl' {
  return locale === 'ar' ? 'rtl' : 'ltr';
}

export function setLocale(locale: Locale): void {
  if (locale === currentLocale) return;
  currentLocale = locale;
  try {
    localStorage.setItem(STORAGE_KEY, locale);
  } catch {
    // Storage unavailable (private mode / disabled) — locale still applies
    // for this session via the in-memory listeners below.
  }
  document.documentElement.lang = locale;
  document.documentElement.dir = getDirection(locale);
  listeners.forEach((cb) => cb());
}

/** Used by LocaleContext to re-render on locale change (React 18 store). */
export function subscribeLocale(cb: () => void): () => void {
  listeners.add(cb);
  return () => listeners.delete(cb);
}

/** Interpolates `{param}` placeholders with the given values. */
function interpolate(template: string, params?: Record<string, string | number>): string {
  if (!params) return template;
  return template.replace(/\{(\w+)\}/g, (match, key) => {
    const value = params[key];
    return value === undefined ? match : String(value);
  });
}

/** Translates `key` in the current locale, falling back to English then the
 *  raw key itself if missing. Safe to call outside React (utils, services). */
export function t(key: TranslationKey, params?: Record<string, string | number>): string {
  const dict = dictionaries[currentLocale];
  const template = dict[key] ?? dictionaries.en[key] ?? key;
  return interpolate(template, params);
}
