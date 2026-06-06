import { useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
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
import { FamilyService, FamilyRow, RevenueService, RevenueSummary } from '../../services/firestore';
import { exportCsv } from '../../utils/csv';

const planPrice: Record<string, number> = { weekly: 89, monthly: 239, twoMonths: 369 };

export default function Subscriptions() {
  const [families, setFamilies] = useState<FamilyRow[]>([]);
  const [revenue, setRevenue] = useState<RevenueSummary | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([FamilyService.list(), RevenueService.summary()]).then(([f, r]) => {
      setFamilies(f);
      setRevenue(r);
      setLoading(false);
    });
  }, []);

  const subscribed = families.filter((f) => f.subscription.status === 'active').length;
  const expiringSoon = families.filter((f) => {
    if (!f.subscription.endDate || f.subscription.status !== 'active') return false;
    const days = (f.subscription.endDate.getTime() - Date.now()) / 86400000;
    return days >= 0 && days <= 3;
  }).length;

  const planCounts = useMemo(() => {
    const c: Record<string, number> = { weekly: 0, monthly: 0, twoMonths: 0 };
    families.forEach((f) => {
      if (f.subscription.status === 'active' && f.subscription.plan) {
        c[f.subscription.plan] = (c[f.subscription.plan] ?? 0) + 1;
      }
    });
    return c;
  }, [families]);

  const free = families.filter((f) => f.subscription.status === 'free').length;
  const monthly = revenue?.monthly ?? 0;

  const onExport = () => {
    exportCsv('subscriptions.csv', families, [
      { header: 'ID', value: (r) => r.id },
      { header: 'Name', value: (r) => r.fullName },
      { header: 'Status', value: (r) => r.subscription.status },
      { header: 'Plan', value: (r) => r.subscription.plan ?? '' },
      { header: 'EndDate', value: (r) => r.subscription.endDate?.toISOString() ?? '' },
    ]);
  };

  return (
    <PageShell>
      <PageHeader
        title="Subscriptions"
        subtitle={`${subscribed} active · View plans & billing`}
        actions={
          <button type="button" className="qa-btn qa-g" onClick={onExport}>
            Export CSV
          </button>
        }
      />
      <PageContent>
        <div className="grid grid-cols-2 lg:grid-cols-3 gap-2 mb-3">
          <TopStat num={String(subscribed)} label="Active subs" change="↑ Live" />
          <TopStat num={`AED ${monthly.toLocaleString()}`} label="Monthly revenue" change="↑ Live" numClass="!text-[13px]" />
          <TopStat num={String(expiringSoon)} label="Expiring (3d)" change="⚠ Watch" numClass="!text-[#FFB347]" />
        </div>

        {loading && <div className="px-3 py-4 text-[10px] text-[#8090B0]">Loading…</div>}

        <TableCard title="Plan breakdown">
          {Object.entries(planCounts).map(([plan, count]) => {
            const total = subscribed || 1;
            return (
              <Row key={plan}>
                <div className="flex-1 text-[10.5px] font-extrabold text-navy">
                  {plan} · AED {planPrice[plan]}
                </div>
                <BarRow
                  pct={Math.min(100, (count / total) * 100)}
                  label={`${count} subs`}
                  color={plan === 'weekly' ? '#FFB347' : plan === 'monthly' ? '#9B6EDB' : '#6DBF8A'}
                />
              </Row>
            );
          })}
          <Row highlight>
            <div className="flex-1 text-[10.5px] font-extrabold text-[#8090B0]">Not subscribed (free)</div>
            <BarRow pct={Math.min(100, (free / (families.length || 1)) * 100)} label={`${free} users`} color="#FFD8E8" />
          </Row>
        </TableCard>

        <TableCard title="Active subscribers">
          {families
            .filter((f) => f.subscription.status === 'active')
            .map((f) => (
              <Row key={f.id}>
                <div className="flex-1 min-w-0">
                  <div className="text-[10.5px] font-extrabold text-navy">{f.fullName}</div>
                  <div className="text-[8.5px] font-semibold text-[#8090B0]">
                    {f.subscription.plan} · ends {f.subscription.endDate?.toLocaleDateString() ?? '—'}
                  </div>
                </div>
                <StatusBadge variant="sub">Active</StatusBadge>
                <Link to={`/families/${f.id}`} className="text-[9px] font-bold text-purple font-fredoka no-underline ml-1">
                  View →
                </Link>
              </Row>
            ))}
        </TableCard>
      </PageContent>
    </PageShell>
  );
}
