import { useEffect, useMemo, useState } from 'react';
import {
  BarRow,
  PageContent,
  PageHeader,
  PageShell,
  Row,
  StatusBadge,
  TableCard,
  TopStat,
} from '../../components/ui/AdminUI';
import { FilterBar, FilterSelect } from '../../components/ui/ListControls';
import RevenueTrendChart from '../../components/charts/RevenueTrendChart';
import { RevenueService, RevenueTransaction } from '../../services/firestore';
import { exportCsv } from '../../utils/csv';

const txVariant: Record<RevenueTransaction['status'], string> = {
  paid: 'verified',
  refunded: 'pending',
  failed: 'rejected',
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
    while (cursor <= endMonth) {
      const label = cursor.toLocaleString('en', { month: 'short' }) + ' ' + cursor.getFullYear();
      buckets.set(label, 0);
      cursor.setMonth(cursor.getMonth() + 1);
    }
    paid.forEach((t) => {
      const ts = t.createdAt.getTime();
      if (ts < fromMs || ts > toMs) return;
      const d = t.createdAt;
      const label = d.toLocaleString('en', { month: 'short' }) + ' ' + d.getFullYear();
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

/** Bucket granularity for a given inclusive range (mirrors buildRangeTrend). */
function trendMode(from: string, to: string): 'daily' | 'monthly' {
  if (!from || !to) return 'monthly';
  const fromMs = new Date(from).getTime();
  const toMs = new Date(to).getTime() + 86400000 - 1;
  const spanDays = Math.max(1, Math.round((toMs - fromMs) / 86400000));
  return spanDays <= 31 ? 'daily' : 'monthly';
}

export default function Revenue() {
  const defaultRange = presetRange('monthly');
  const [txns, setTxns] = useState<RevenueTransaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [preset, setPreset] = useState<Preset>('monthly');
  const [from, setFrom] = useState(defaultRange.from);
  const [to, setTo] = useState(defaultRange.to);
  const [txnQuery, setTxnQuery] = useState('');

  useEffect(() => {
    RevenueService.allTransactions()
      .then(setTxns)
      .catch((e: unknown) => setError((e as Error).message || 'Failed to load revenue'))
      .finally(() => setLoading(false));
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
    const vat = Math.round(total * 0.05);

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
    const mode = trendMode(from, to);

    return { paid, total, vat, byPlan, trend, hasTrendData, mode };
  }, [inRange, from, to]);

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
        <PageHeader title="Revenue" subtitle="Loading…" />
      </PageShell>
    );
  }

  return (
    <PageShell>
      <PageHeader
        title="Revenue"
        subtitle="Financial overview & VAT"
        actions={
          <button type="button" className="qa-btn qa-g" onClick={onExport}>
            Export CSV
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
          searchPlaceholder="Search transactions…"
          dateLabel="Date"
        >
          <FilterSelect
            label="Period"
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
              { value: 'weekly', label: 'Weekly (7 days)' },
              { value: 'monthly', label: 'Monthly (30 days)' },
              { value: 'yearly', label: 'Yearly (12 months)' },
              { value: 'custom', label: 'Custom range' },
            ]}
          />
        </FilterBar>

        <div className="grid grid-cols-2 lg:grid-cols-4 gap-2 mb-3">
          <TopStat
            num={`AED ${derived.total.toLocaleString()}`}
            label="Revenue in range"
            change="↑ Live"
            numClass="!text-[13px]"
          />
          <TopStat
            num={String(derived.paid.length)}
            label="Paid transactions"
            change="↑ Paid"
          />
          <TopStat
            num={`AED ${derived.vat.toLocaleString()}`}
            label="VAT 5%"
            change="→ FTA"
            numClass="!text-[13px]"
          />
          <TopStat
            num={`AED ${derived.paid.length ? Math.round(derived.total / derived.paid.length).toLocaleString() : '0'}`}
            label="Avg / transaction"
            change="↑ Avg"
            numClass="!text-[13px]"
          />
        </div>

        <TableCard title="Revenue trend">
          <div className="px-[11px] py-4">
            {!derived.hasTrendData ? (
              <div className="text-[10px] text-[#8090B0]">No data for selected period.</div>
            ) : (
              <RevenueTrendChart data={derived.trend} mode={derived.mode} />
            )}
          </div>
        </TableCard>

        <TableCard title="Plan revenue split">
          {derived.byPlan.length === 0 && (
            <div className="px-3 py-4 text-[10px] text-[#8090B0]">No paid transactions in selected period.</div>
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

        <TableCard title="Recent transactions">
          {inRange.length === 0 && (
            <div className="px-3 py-4 text-[10px] text-[#8090B0]">No transactions in selected period.</div>
          )}
          {visibleTxns.map((t) => (
            <Row key={t.id}>
              <div className="flex-1 min-w-0">
                <div className="text-[10.5px] font-extrabold text-navy truncate">{t.familyName}</div>
                <div className="text-[8.5px] font-semibold text-[#8090B0]">
                  {t.plan} · {t.createdAt.toLocaleDateString()}
                </div>
              </div>
              <div className="text-[10.5px] font-extrabold text-navy">AED {t.amount.toLocaleString()}</div>
              <StatusBadge variant={txVariant[t.status]}>{t.status}</StatusBadge>
            </Row>
          ))}
          {inRange.length > 50 && (
            <Row>
              <div className="flex-1 text-[9px] font-semibold text-[#8090B0]">
                Showing latest 50 of {inRange.length} transactions
              </div>
            </Row>
          )}
        </TableCard>
      </PageContent>
    </PageShell>
  );
}
