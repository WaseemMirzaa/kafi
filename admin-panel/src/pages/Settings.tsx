import { useEffect, useState } from 'react';
import {
  DetailCard,
  PageContent,
  PageHeader,
  PageShell,
  PageLoader,
} from '../components/ui/AdminUI';
import { SettingsService } from '../services/firestore';
import { useLocale } from '../context/LocaleContext';
import { Locale } from '../locales/t';

/**
 * App-wide settings. Reads and writes the `settings/global` doc that both the
 * admin panel (Dashboard/Revenue/Subscriptions) and the Kafi app consume:
 * plan prices, VAT rate, free-contact limit, job-post visibility window, and the
 * "hide inactive nannies" listing toggle. This page is the single source that
 * drives those values everywhere.
 */

/** Percent string for display, e.g. 0.05 -> "5" (trims float noise). */
function pctFromRate(rate: number): string {
  return String(+(rate * 100).toFixed(2));
}

function NumField({
  label,
  value,
  onChange,
  suffix,
  hint,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  suffix?: string;
  hint?: string;
}) {
  return (
    <div>
      <div className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide mb-1.5">{label}</div>
      <div className="flex items-center gap-1.5">
        <input
          type="number"
          inputMode="decimal"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          className="w-full admin-card text-[10px] font-semibold text-navy px-3 py-2 border-[#EBEEF8] focus:outline-none focus:ring-1 focus:ring-rose-dark/30"
        />
        {suffix && <span className="text-[9px] font-bold text-[#8090B0] flex-shrink-0 w-8">{suffix}</span>}
      </div>
      {hint && <div className="text-[8px] text-[#8090B0] mt-1 leading-relaxed">{hint}</div>}
    </div>
  );
}

export default function Settings() {
  const { t, locale, setLocale } = useLocale();
  const [freeContactLimit, setFreeContactLimit] = useState('');
  const [jobPostVisibilityDays, setJobPostVisibilityDays] = useState('');
  const [weekly, setWeekly] = useState('');
  const [monthly, setMonthly] = useState('');
  const [twoMonths, setTwoMonths] = useState('');
  const [vatPct, setVatPct] = useState('');
  const [hideInactive, setHideInactive] = useState(false);

  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [ok, setOk] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    SettingsService.get()
      .then((s) => {
        if (cancelled) return;
        setFreeContactLimit(String(s.freeContactLimit));
        setJobPostVisibilityDays(String(s.jobPostVisibilityDays));
        setWeekly(String(s.plans.weekly));
        setMonthly(String(s.plans.monthly));
        setTwoMonths(String(s.plans.twoMonths));
        setVatPct(pctFromRate(s.vatRate));
        setHideInactive(s.hideInactiveNannies === true);
      })
      .catch((e) => {
        if (!cancelled) setError((e as Error).message || t('settings.failedToLoad'));
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  const save = async () => {
    if (loading || busy) return;
    setOk(null);
    setError(null);

    // Validate before writing — these values drive billing math and app-wide
    // limits, so a bad entry must never reach `settings/global`.
    const fcl = parseInt(freeContactLimit, 10);
    const jpv = parseInt(jobPostVisibilityDays, 10);
    const wk = parseInt(weekly, 10);
    const mo = parseInt(monthly, 10);
    const tm = parseInt(twoMonths, 10);
    const vp = parseFloat(vatPct);

    if ([fcl, jpv, wk, mo, tm].some((n) => !Number.isFinite(n)) || !Number.isFinite(vp)) {
      setError(t('settings.enterValidNumbers'));
      return;
    }
    if (fcl < 0 || jpv < 1 || wk <= 0 || mo <= 0 || tm <= 0) {
      setError(t('settings.positiveValuesRequired'));
      return;
    }
    if (vp < 0 || vp > 100) {
      setError(t('settings.vatRange'));
      return;
    }

    setBusy(true);
    try {
      await SettingsService.update({
        freeContactLimit: fcl,
        jobPostVisibilityDays: jpv,
        plans: { weekly: wk, monthly: mo, twoMonths: tm },
        vatRate: +(vp / 100).toFixed(4),
        hideInactiveNannies: hideInactive,
      });
      setOk(t('common.saved'));
    } catch (e) {
      setError((e as Error).message || t('settings.failedToSave'));
    } finally {
      setBusy(false);
    }
  };

  return (
    <PageShell>
      <PageHeader
        title={t('settings.title')}
        subtitle={t('settings.subtitle')}
        actions={
          <button type="button" className="qa-btn qa-r" onClick={save} disabled={loading || busy}>
            {busy ? t('common.saving') : t('settings.saveChanges')}
          </button>
        }
      />
      <PageContent>
        {loading ? (
          <PageLoader />
        ) : (
          <div className="flex flex-col gap-3">
            {/* Plans & billing — the single source for prices/VAT used by the
                Dashboard, Revenue and Subscriptions pages. */}
            <DetailCard>
              <div className="text-[11px] font-extrabold text-navy">{t('settings.plansAndBilling')}</div>
              <div className="text-[9px] font-semibold text-[#8090B0] mt-1 mb-3 leading-relaxed">
                {t('settings.plansAndBillingDesc')}
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <NumField label={t('settings.weeklyPlan')} value={weekly} onChange={setWeekly} suffix="AED" />
                <NumField label={t('settings.monthlyPlan')} value={monthly} onChange={setMonthly} suffix="AED" />
                <NumField label={t('settings.twoMonthPlan')} value={twoMonths} onChange={setTwoMonths} suffix="AED" />
                <NumField label={t('settings.vatRate')} value={vatPct} onChange={setVatPct} suffix="%" hint={t('settings.vatHint')} />
              </div>
            </DetailCard>

            {/* Limits */}
            <DetailCard>
              <div className="text-[11px] font-extrabold text-navy">{t('settings.limits')}</div>
              <div className="text-[9px] font-semibold text-[#8090B0] mt-1 mb-3 leading-relaxed">
                {t('settings.limitsDesc')}
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <NumField
                  label={t('settings.freeContactsPerFamily')}
                  value={freeContactLimit}
                  onChange={setFreeContactLimit}
                  hint={t('settings.freeContactsHint')}
                />
                <NumField
                  label={t('settings.jobPostVisibility')}
                  value={jobPostVisibilityDays}
                  onChange={setJobPostVisibilityDays}
                  suffix={t('settings.jobPostVisibilityDays')}
                />
              </div>
            </DetailCard>

            {/* Listing — hide inactive nannies toggle (unchanged behavior). */}
            <DetailCard>
              <div className="flex items-start justify-between gap-4">
                <div className="flex-1 min-w-0">
                  <div className="text-[11px] font-extrabold text-navy">{t('settings.hideInactiveNannies')}</div>
                  <div className="text-[9px] font-semibold text-[#8090B0] mt-1 leading-relaxed">
                    {t('settings.hideInactiveNanniesDesc')}
                  </div>
                </div>
                <button
                  type="button"
                  role="switch"
                  aria-checked={hideInactive}
                  disabled={busy}
                  onClick={() => setHideInactive((v) => !v)}
                  className={`relative w-11 h-6 rounded-full flex-shrink-0 transition-colors ${
                    hideInactive ? 'bg-rose-dark' : 'bg-[#D5DAE6]'
                  } ${busy ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}`}
                >
                  <span
                    className={`absolute top-0.5 left-0.5 w-5 h-5 rounded-full bg-white shadow transition-transform ${
                      hideInactive ? 'translate-x-5' : ''
                    }`}
                  />
                </button>
              </div>
            </DetailCard>

            {/* Language — EN|AR admin panel locale toggle. */}
            <DetailCard>
              <div className="flex items-start justify-between gap-4">
                <div className="flex-1 min-w-0">
                  <div className="text-[11px] font-extrabold text-navy">{t('header.locale')}</div>
                </div>
                <div className="flex gap-1.5 flex-shrink-0">
                  {(['en', 'ar'] as Locale[]).map((l) => (
                    <button
                      key={l}
                      type="button"
                      onClick={() => setLocale(l)}
                      className={`qa-btn ${locale === l ? 'qa-r' : 'qa-n'}`}
                    >
                      {l === 'en' ? t('header.localeEnglish') : t('header.localeArabic')}
                    </button>
                  ))}
                </div>
              </div>
            </DetailCard>

            <div className="flex items-center gap-2 h-4">
              {ok && <span className="text-[10px] font-bold text-[#2A8A50]">{ok}</span>}
              {error && <span className="text-[10px] font-bold text-rose-dark">{error}</span>}
            </div>
          </div>
        )}
      </PageContent>
    </PageShell>
  );
}
