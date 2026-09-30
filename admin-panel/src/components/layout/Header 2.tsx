import { useAuthStore } from '../../hooks/useAuth';
import { useLocale } from '../../context/LocaleContext';
import { Locale } from '../../locales/t';

export default function Header() {
  const { user, logout } = useAuthStore();
  const { t, locale, setLocale } = useLocale();

  const toggleLocale = () => {
    const next: Locale = locale === 'en' ? 'ar' : 'en';
    setLocale(next);
  };

  return (
    <header className="h-14 bg-white border-b border-gray-200 flex items-center justify-between px-6">
      <h1 className="text-lg font-bold text-td">{t('header.title')}</h1>
      <div className="flex items-center gap-4">
        <button
          type="button"
          onClick={toggleLocale}
          aria-label={t('header.locale')}
          className="text-sm font-semibold text-navy border border-gray-200 rounded-md px-2.5 py-1 hover:bg-gray-50"
        >
          {locale === 'en' ? t('header.localeArabic') : t('header.localeEnglish')}
        </button>
        <span className="text-sm text-tm">{user?.email}</span>
        <button
          onClick={logout}
          className="text-sm text-rose-dark hover:underline"
        >
          {t('header.logout')}
        </button>
      </div>
    </header>
  );
}
