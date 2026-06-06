import { useEffect, useState } from 'react';
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
import { RevenueService, RevenueSummary, RevenueTransaction } from '../../services/firestore';
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

export default function Revenue() {
  const [data, setData] = useState<RevenueSummary | null>(null);
  const [txns, setTxns] = useState<RevenueTransaction[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([RevenueService.summary(), RevenueService.recentTransactions()]).then(([d, t]) => {
      setData(d);
      setTxns(t);
      setLoading(false);
    });
  }, []);

  const onExport = () => {
    if (!data) return;
    exportCsv('revenue.csv', data.byPlan, [
      { header: 'Plan', value: (r) => r.plan },
      { header: 'Subs', value: (r) => String(r.subs) },
      { header: 'Revenue (AED)', value: (r) => String(r.revenue) },
    ]);
  };

  if (loading || !data) {
    return (
      <PageShell>
        <PageHeader title="Revenue" subtitle="Loading…" />
      </PageShell>
    );
  }

  const lastThreeMonths = data.trend.slice(-3).reduce((s, m) => s + m.amount, 0);
  const hasTrendData = data.trend.some((m) => m.amount > 0);

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
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-2 mb-3">
          <TopStat num={`AED ${data.monthly.toLocaleString()}`} label="This month" change="↑ Live" numClass="!text-[13px]" />
          <TopStat
            num={`AED ${lastThreeMonths.toLocaleString()}`}
            label="Last 3 months"
            change="↑ Paid transactions"
            numClass="!text-[13px]"
          />
          <TopStat num={`AED ${data.vat.toLocaleString()}`} label="VAT 5%" change="→ FTA" numClass="!text-[13px]" />
          <TopStat num={`${data.byPlan.reduce((s, p) => s + p.subs, 0)}`} label="Active subs" change="↑ Subs" />
        </div>

        <TableCard title="Monthly trend (paid transactions, last 6 months)">
          <div className="px-[11px] py-4">
            {!hasTrendData && (
              <div className="text-[10px] text-[#8090B0] mb-2">No paid transactions in the last 6 months.</div>
            )}
            <div className="flex items-end gap-2">
              {data.trend.map((m) => (
                <div
                  key={m.label}
                  className="flex-1 flex flex-col items-center gap-1"
                  title={`${m.label}: AED ${m.amount.toLocaleString()}`}
                >
                  <span className="text-[8px] font-bold text-navy">
                    {m.amount > 0 ? `AED ${m.amount.toLocaleString()}` : '—'}
                  </span>
                  <div className="w-full h-32 flex items-end">
                    <div
                      className={`w-full rounded-t ${m.amount > 0 ? 'bg-gradient-to-t from-rose-dark to-rose' : 'bg-[#F0F1FA]'}`}
                      style={{ height: `${Math.max(2, m.pct)}%` }}
                    />
                  </div>
                  <span className="text-[8px] font-bold text-[#8090B0]">{m.label}</span>
                </div>
              ))}
            </div>
          </div>
        </TableCard>

        <TableCard title="Plan revenue split">
          {data.byPlan.map((p) => (
            <Row key={p.plan}>
              <div className="flex-1 text-[10.5px] font-extrabold text-navy">{p.plan}</div>
              <BarRow
                pct={Math.min(100, (p.revenue / Math.max(1, data.monthly)) * 100)}
                label={`AED ${p.revenue.toLocaleString()}`}
                color={planColor[p.plan] ?? '#9B6EDB'}
              />
            </Row>
          ))}
        </TableCard>

        <TableCard title="Recent transactions">
          {txns.length === 0 && (
            <div className="px-3 py-4 text-[10px] text-[#8090B0]">No transactions yet.</div>
          )}
          {txns.map((t) => (
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
        </TableCard>
      </PageContent>
    </PageShell>
  );
}
