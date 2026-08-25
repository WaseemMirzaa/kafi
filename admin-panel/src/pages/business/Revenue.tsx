import { useEffect, useMemo, useState } from 'react';
import {
  BarRow,
  PageContent,
  PageHeader,
  PageLoader,
  PageShell,
  Row,
  StatusBadge,
  TableCard,
  TopStat,
} from '../../components/ui/AdminUI';
import { FilterBar, FilterSelect } from '../../components/ui/ListControls';
import { RevenueService, RevenueTransaction, SettingsService, DEFAULT_VAT_RATE } from '../../services/firestore';
import { exportCsv } from '../../utils/csv';
import { useLocale } from '../../context/LocaleContext';
import { getLocale, TranslationKey } from '../../locales/t';

const txVariant: Record<RevenueTransaction['status'], string> = {
  paid: 'verified',
  refunded: 'pending',
  failed: 'rejected',
};

const txStatusLabelKeys: Record<RevenueTransaction['status'], TranslationKey> = {
  paid: 'revenue.status.paid',
  refunded: 'revenue.status.refunded',
  failed: 'revenue.status.failed',
};

const planColor: Record<string, string> = {
  weekly: '#FFB347',
  monthly: '#9B6EDB',
  twoMonths: '#2E9A58',
};

type Preset = 'weekly' | 'monthly' | 'yearly' | 'custom';

/** Maps a preset name to an inclusive YYYY-MM-DD from/to range. */
function presetRange(preset: 'weekly' | 'monthly' | 'yearly'): { from: string; to: string } {
  const now = new Date();
  const toDate = now;
  const fromDate = new Date(now);
  if (preset === 'weekly') fromDate.setDate(now.getDate() - 6);
  else if (preset === 'monthly') fromDate.setMonth(now.getMonth() - 1);
  else fromDate.setFullYear(now.getFullYear() - 1);
  const iso = (d: Date) => d.toISOString().slice(0, 10);
  return { from: iso(fromDate), to: iso(toDate) };
}

/** Bucket paid transactions into time buckets for the trend chart.
 *  span <= 31 days → daily (DD/MM); else → monthly (MMM YYYY or MMM). */
function buildRangeTrend(
  paid: RevenueTransaction[],
  from: string,
  to: string,
): { label: string; amount: number; pct: number }[] {
  if (!from || !to) return [];

  const fromMs = new Date(from).getTime();
  const toMs = new Date(to).getTime() + 86400000 - 1;
  const spanDays = Math.max(1, Math.round((toMs - fromMs) / 86400000));

  const buckets: Map<string, number> = new Map();

  if (spanDays <= 31) {
    // Daily buckets
    const cursor = new Date(from);
    while (cursor.getTime() <= toMs) {
      const label = `${String(cursor.getDate()).padStart(2, '0')}/${String(cursor.getMonth() + 1).padStart(2, '0')}`;
      buckets.set(label, 0);
      cursor.setDate(cursor.getDate() + 1);
    }
    paid.forEach((t) => {
      const ts = t.createdAt.getTime();
      if (ts < fromMs || ts > toMs) return;
      const d = t.createdAt;
      const label = `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}`;
      buckets.set(label, (buckets.get(label) ?? 0) + t.amount);
    });
  } else {
    // Monthly buckets
    const cursor = new Date(from);
    cursor.setDate(1);
    const endMonth = new Date(to);
    endMonth.setDate(1);
    const monthLocale = getLocale() === 'ar' ? 'ar-AE' : 'en';
    while (cursor <= endMonth) {
      const label = cursor.toLocaleString(monthLocale, { month: 'short' }) + ' ' + cursor.getFullYear();
      buckets.set(label, 0);
      cursor.setMonth(cursor.getMonth() + 1);
    }
    paid.forEach((t) => {
      const ts = t.createdAt.getTime();
      if (ts < fromMs || ts > toMs) return;
      const d = t.createdAt;
      const label = d.toLocaleString(monthLocale, { month: 'short' }) + ' ' + d.getFullYear();
      buckets.set(label, (buckets.get(label) ?? 0) + t.amount);
    });
  }

  const values = Array.from(buckets.values());
  const maxAmount = Math.max(...values, 1);

  return Array.from(buckets.entries()).map(([label, amount]) => ({
    label,
    amount,
    pct: Math.round((amount / maxAmount) * 100),
  }));
}

export default function Revenue() {
  const { t, locale } = useLocale();
  const defaultRange = presetRange('monthly');
  const [txns, setTxns] = useState<RevenueTransaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [preset, setPreset] = useState<Preset>('monthly');
  const [from, setFrom] = useState(defaultRange.from);
  const [to, setTo] = useState(defaultRange.to);
  const [txnQuery, setTxnQuery] = useState('');
  // VAT rate from admin settings (defaults if unset/unreachable — non-critical,
  // so a settings hiccup never blocks the revenue page).
  const [vatRate, setVatRate] = useState(DEFAULT_VAT_RATE);

  useEffect(() => {
    RevenueService.allTransactions()
      .then(setTxns)
      .catch((e: unknown) => setError((e as Error).message || t('revenue.failedToLoad')))
      .finally(() => setLoading(false));
    SettingsService.get()
      .then((s) => setVatRate(s.vatRate))
      .catch(() => {
        /* keep the default rate */
      });
  }, []);

  /** All transactions whose createdAt falls within [from, to] (inclusive day). */
  const inRange = useMemo(() => {
    const fromT = from ? new Date(from).getTime() : null;
    const toT = to ? new Date(to).getTime() + 86400000 - 1 : null;
    return txns.filter((t) => {
      const ts = t.createdAt.getTime();
      if (fromT != null && ts < fromT) return false;
      if (toT != null && ts > toT) return false;
      return true;
    });
  }, [txns, from, to]);

  /** Aggregates derived exclusively from paid transactions in range. */
  const derived = useMemo(() => {
    const paid = inRange.filter((t) => t.status === 'paid');
    const total = paid.reduce((s, t) => s + t.amount, 0);
    const vat = Math.round(total * vatRate);

    // Plan revenue split from paid txns in range
    const map: Record<string, { subs: number; revenue: number }> = {};
    paid.forEach((t) => {
      map[t.plan] = {
        subs: (map[t.plan]?.subs ?? 0) + 1,
        revenue: (map[t.plan]?.revenue ?? 0) + t.amount,
      };
    });
    const byPlan = Object.entries(map).map(([plan, v]) => ({ plan, ...v }));

    const trend = buildRangeTrend(paid, from, to);
    const hasTrendData = trend.some((b) => b.amount > 0);

    return { paid, total, vat, byPlan, trend, hasTrendData };
  }, [inRange, from, to, vatRate, locale]);

  /** Recent transactions filtered by txnQuery (familyName or plan). */
  const visibleTxns = useMemo(() => {
    const q = txnQuery.trim().toLowerCase();
    const filtered = q
      ? inRange.filter(
          (t) => t.familyName.toLowerCase().includes(q) || t.plan.toLowerCase().includes(q),
        )
      : inRange;
    return filtered.slice(0, 50);
  }, [inRange, txnQuery]);

  const onExport = () => {
    exportCsv('revenue.csv', derived.byPlan, [
      { header: 'Plan', value: (r) => r.plan },
      { header: 'Subs', value: (r) => String(r.subs) },
      { header: 'Revenue (AED)', value: (r) => String(r.revenue) },
    ]);
  };

  if (loading) {
    return (
      <PageShell>
        <PageHeader title={t('revenue.title')} subtitle={t('revenue.subtitle')} />
        <PageContent>
          <PageLoader />
        </PageContent>
      </PageShell>
    );
  }

  // Every figure on this page is derived from the `transactions` collection,
  // which is written by the RevenueCat webhook. Until billing is integrated
  // that collection is empty in production, so rather than show misleading
  // "AED 0 ↑ Live" tiles and empty tables we render a clear placeholder. Once a
  // real transaction lands (billing live, or mock/demo data) the full report
  // renders automatically.
  if (!error && txns.length === 0) {
    return (
      <PageShell>
        <PageHeader title={t('revenue.title')} subtitle={t('revenue.subtitle')} />
        <PageContent>
          <TableCard title={t('revenue.title')}>
            <div className="px-3 py-6 text-center">
              <div className="text-[11px] font-extrabold text-navy">
                {t('revenue.notIntegratedTitle')}
              </div>
              <div className="mt-1.5 mx-auto max-w-md text-[10px] font-semibold text-[#8090B0] leading-relaxed">
                {t('revenue.notIntegratedDesc', { doc: 'docs/PAYMENTS.md' })}
              </div>
            </div>
          </TableCard>
        </PageContent>
      </PageShell>
    );
  }

  return (
    <PageShell>
      <PageHeader
        title={t('revenue.title')}
        subtitle={t('revenue.subtitle')}
        actions={
          <button type="button" className="qa-btn qa-g" onClick={onExport}>
            {t('common.exportCsv')}
          </button>
        }
      />
      <PageContent>
        {error && (
          <div className="mx-2 mb-2 p-2 bg-rose-pale text-rose-dark text-[10px] font-bold rounded-lg">
            {error}
          </div>
        )}

        <FilterBar
          query={txnQuery}
          setQuery={setTxnQuery}
          from={from}
          setFrom={(v) => {
            setFrom(v);
            setPreset('custom');
          }}
          to={to}
          setTo={(v) => {
            setTo(v);
            setPreset('custom');
          }}
          onClear={() => {
            setTxnQuery('');
            setPreset('monthly');
            const r = presetRange('monthly');
            setFrom(r.from);
            setTo(r.to);
          }}
          searchPlaceholder={t('revenue.searchPlaceholder')}
          dateLabel={t('revenue.date')}
        >
          <FilterSelect
            label={t('revenue.period')}
            value={preset}
            onChange={(v) => {
              const p = v as Preset;
              setPreset(p);
              if (p !== 'custom') {
                const r = presetRange(p);
                setFrom(r.from);
                setTo(r.to);
              }
            }}
            options={[
              { value: 'weekly', label: t('revenue.periodWeekly') },
              { value: 'monthly', label: t('revenue.periodMonthly') },
              { value: 'yearly', label: t('revenue.periodYearly') },
              { value: 'custom', label: t('revenue.periodCustom') },
            ]}
          />
        </FilterBar>

        <div className="grid grid-cols-2 lg:grid-cols-4 gap-2 mb-3">
          <TopStat
            num={`AED ${derived.total.toLocaleString()}`}
            label={t('revenue.revenueInRange')}
            change={t('revenue.liveChange')}
            numClass="!text-[13px]"
          />
          <TopStat
            num={String(derived.paid.length)}
            label={t('revenue.paidTransactions')}
            change={t('revenue.paidChange')}
          />
          <TopStat
            num={`AED ${derived.vat.toLocaleString()}`}
            label={t('revenue.vatPercent', { pct: Math.round(vatRate * 100) })}
            change={t('revenue.ftaChange')}
            numClass="!text-[13px]"
          />
          <TopStat
            num={`AED ${derived.paid.length ? Math.round(derived.total / derived.paid.length).toLocaleString() : '0'}`}
            label={t('revenue.avgPerTransaction')}
            change={t('revenue.avgChange')}
            numClass="!text-[13px]"
          />
        </div>

        <TableCard title={t('revenue.revenueTrend')}>
          <div className="px-[11px] py-4">
            {!derived.hasTrendData ? (
              <div className="text-[10px] text-[#8090B0]">{t('revenue.noDataForPeriod')}</div>
            ) : (
              <div className="h-40 flex items-end gap-2 overflow-x-auto">
                {derived.trend.map((m) => (
                  <div key={m.label} className="flex-1 flex flex-col items-center gap-1 min-w-[28px]">
                    <div
                      className="w-full rounded-t bg-gradient-to-t from-rose-dark to-rose"
                      style={{ height: `${m.pct}%` }}
                    />
                    <span className="text-[8px] font-bold text-[#8090B0] whitespace-nowrap">{m.label}</span>
                  </div>
                ))}
              </div>
            )}
          </div>
        </TableCard>

        <TableCard title={t('revenue.planRevenueSplit')}>
          {derived.byPlan.length === 0 && (
            <div className="px-3 py-4 text-[10px] text-[#8090B0]">{t('revenue.noPaidTransactionsInPeriod')}</div>
          )}
          {derived.byPlan.map((p) => (
            <Row key={p.plan}>
              <div className="flex-1 text-[10.5px] font-extrabold text-navy">{p.plan}</div>
              <BarRow
                pct={Math.min(100, (p.revenue / Math.max(1, derived.total)) * 100)}
                label={`AED ${p.revenue.toLocaleString()}`}
                color={planColor[p.plan] ?? '#9B6EDB'}
              />
            </Row>
          ))}
        </TableCard>

        <TableCard title={t('revenue.recentTransactions')}>
          {inRange.length === 0 && (
            <div className="px-3 py-4 text-[10px] text-[#8090B0]">{t('revenue.noTransactionsInPeriod')}</div>
          )}
          {visibleTxns.map((tx) => (
            <Row key={tx.id}>
              <div className="flex-1 min-w-0">
                <div className="text-[10.5px] font-extrabold text-navy truncate">{tx.familyName}</div>
                <div className="text-[8.5px] font-semibold text-[#8090B0]">
                  {tx.plan} · {tx.createdAt.toLocaleDateString()}
                </div>
              </div>
              <div className="text-[10.5px] font-extrabold text-navy">AED {tx.amount.toLocaleString()}</div>
              <StatusBadge variant={txVariant[tx.status]}>{t(txStatusLabelKeys[tx.status])}</StatusBadge>
            </Row>
          ))}
          {inRange.length > 50 && (
            <Row>
              <div className="flex-1 text-[9px] font-semibold text-[#8090B0]">
                {t('revenue.showingLatest', { count: inRange.length })}
              </div>
            </Row>
          )}
        </TableCard>
      </PageContent>
    </PageShell>
  );
}
