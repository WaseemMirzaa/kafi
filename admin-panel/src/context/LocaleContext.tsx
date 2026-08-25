import { createContext, useContext, useSyncExternalStore } from 'react';
import { getDirection, getLocale, Locale, setLocale, subscribeLocale, t } from '../locales/t';

interface LocaleContextValue {
  locale: Locale;
  setLocale: (locale: Locale) => void;
  t: typeof t;
}

const LocaleContext = createContext<LocaleContextValue | null>(null);

/**
 * Wraps the app so any EN|AR toggle (see Header) re-renders every consumer.
 * Uses useSyncExternalStore against the plain-module locale store in
 * `locales/t.ts` so non-React code (utils/nannyLabels, utils/trials) can call
 * `t()` directly while React components stay in sync via this provider.
 */
export function LocaleProvider({ children }: { children: React.ReactNode }) {
  const locale = useSyncExternalStore(subscribeLocale, getLocale);

  return (
    <LocaleContext.Provider value={{ locale, setLocale, t }}>
      <div dir={getDirection(locale)}>{children}</div>
    </LocaleContext.Provider>
  );
}

export function useLocale(): LocaleContextValue {
  const ctx = useContext(LocaleContext);
  if (!ctx) throw new Error('useLocale must be used within a LocaleProvider');
  return ctx;
}
