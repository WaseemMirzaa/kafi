import { useEffect, useState } from 'react';
import { DetailCard, PageContent, PageHeader, PageShell } from '../components/ui/AdminUI';
import { SettingsService } from '../services/firestore';

/**
 * App-wide settings. Writes the `settings/global` doc that both the admin panel
 * and the Kafi app read. Currently: the "hide inactive nannies" listing toggle.
 */
export default function Settings() {
  const [hideInactive, setHideInactive] = useState(false);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [ok, setOk] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    SettingsService.get()
      .then((s) => {
        if (!cancelled) setHideInactive(s.hideInactiveNannies === true);
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

  const toggle = async () => {
    if (loading || busy) return;
    const next = !hideInactive;
    setBusy(true);
    setOk(null);
    setError(null);
    setHideInactive(next); // optimistic
    try {
      await SettingsService.update({ hideInactiveNannies: next });
      setOk('Saved');
    } catch (e) {
      setHideInactive(!next); // revert on failure
      setError((e as Error).message || 'Failed to save');
    } finally {
      setBusy(false);
    }
  };

  return (
    <PageShell>
      <PageHeader title="Settings" subtitle="App-wide configuration" />
      <PageContent>
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
              disabled={loading || busy}
              onClick={toggle}
              className={`relative w-11 h-6 rounded-full flex-shrink-0 transition-colors ${
                hideInactive ? 'bg-rose-dark' : 'bg-[#D5DAE6]'
              } ${loading || busy ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}`}
            >
              <span
                className={`absolute top-0.5 left-0.5 w-5 h-5 rounded-full bg-white shadow transition-transform ${
                  hideInactive ? 'translate-x-5' : ''
                }`}
              />
            </button>
          </div>
          <div className="mt-3 flex items-center gap-2 h-4">
            {loading && <span className="text-[9px] font-bold text-[#8090B0]">Loading…</span>}
            {ok && <span className="text-[10px] font-bold text-[#2A8A50]">{ok}</span>}
            {error && <span className="text-[10px] font-bold text-rose-dark">{error}</span>}
          </div>
        </DetailCard>
      </PageContent>
    </PageShell>
  );
}
