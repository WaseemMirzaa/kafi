import { useEffect, useState } from 'react';
import { DetailCard, PageContent, PageHeader, PageShell } from '../components/ui/AdminUI';
import { SettingsService } from '../services/firestore';

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
        if (!cancelled) setError((e as Error).message || 'Failed to load settings');
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
      setError('Enter valid numbers in every field.');
      return;
    }
    if (fcl < 0 || jpv < 1 || wk <= 0 || mo <= 0 || tm <= 0) {
      setError('Prices and days must be positive; free contacts cannot be negative.');
      return;
    }
    if (vp < 0 || vp > 100) {
      setError('VAT rate must be between 0 and 100%.');
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
      setOk('Saved');
    } catch (e) {
      setError((e as Error).message || 'Failed to save');
    } finally {
      setBusy(false);
    }
  };

  return (
    <PageShell>
      <PageHeader
        title="Settings"
        subtitle="App-wide configuration"
        actions={
          <button type="button" className="qa-btn qa-r" onClick={save} disabled={loading || busy}>
            {busy ? 'Saving…' : 'Save changes'}
          </button>
        }
      />
      <PageContent>
        {loading ? (
          <div className="text-[10px] font-bold text-[#8090B0]">Loading…</div>
        ) : (
          <div className="flex flex-col gap-3">
            {/* Plans & billing — the single source for prices/VAT used by the
                Dashboard, Revenue and Subscriptions pages. */}
            <DetailCard>
              <div className="text-[11px] font-extrabold text-navy">Plans &amp; billing</div>
              <div className="text-[9px] font-semibold text-[#8090B0] mt-1 mb-3 leading-relaxed">
                Plan prices and VAT rate. These drive revenue figures and the plan labels across the panel.
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <NumField label="Weekly plan" value={weekly} onChange={setWeekly} suffix="AED" />
                <NumField label="Monthly plan" value={monthly} onChange={setMonthly} suffix="AED" />
                <NumField label="2-month plan" value={twoMonths} onChange={setTwoMonths} suffix="AED" />
                <NumField label="VAT rate" value={vatPct} onChange={setVatPct} suffix="%" hint="UAE standard is 5%." />
              </div>
            </DetailCard>

            {/* Limits */}
            <DetailCard>
              <div className="text-[11px] font-extrabold text-navy">Limits</div>
              <div className="text-[9px] font-semibold text-[#8090B0] mt-1 mb-3 leading-relaxed">
                Free contact reveals per family before a subscription is required, and how long a job post stays visible.
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <NumField
                  label="Free contacts / family"
                  value={freeContactLimit}
                  onChange={setFreeContactLimit}
                  hint="Contact reveals allowed before subscribing."
                />
                <NumField
                  label="Job post visibility"
                  value={jobPostVisibilityDays}
                  onChange={setJobPostVisibilityDays}
                  suffix="days"
                />
              </div>
            </DetailCard>

            {/* Listing — hide inactive nannies toggle (unchanged behavior). */}
            <DetailCard>
              <div className="flex items-start justify-between gap-4">
                <div className="flex-1 min-w-0">
                  <div className="text-[11px] font-extrabold text-navy">Hide inactive nannies</div>
                  <div className="text-[9px] font-semibold text-[#8090B0] mt-1 leading-relaxed">
                    When enabled, nannies who have not opened the app in the last 2 weeks are hidden
                    from family listings. When disabled, all approved nannies are shown normally.
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
