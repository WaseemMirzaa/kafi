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
  PageLoader,
} from '../../components/ui/AdminUI';
import {
  FamilyService,
  FamilyRow,
  RevenueService,
  RevenueSummary,
  SettingsService,
  DEFAULT_PLAN_PRICES,
} from '../../services/firestore';
import { exportCsv } from '../../utils/csv';
import { useLocale } from '../../context/LocaleContext';
import { subscriptionPlanLabel, fmtDate } from '../../utils/nannyLabels';

export default function Subscriptions() {
  const { t } = useLocale();
  const [families, setFamilies] = useState<FamilyRow[]>([]);
  const [revenue, setRevenue] = useState<RevenueSummary | null>(null);
  // Plan prices come from admin settings (falls back to the shared defaults).
  const [planPrice, setPlanPrice] = useState<Record<string, number>>(DEFAULT_PLAN_PRICES);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    // Fetch families + settings once and pass families to summary() (avoids a
    // duplicate list). settings.plans drives the plan-breakdown price labels.
    Promise.all([FamilyService.list(), SettingsService.get()])
      .then(([f, s]) => RevenueService.summary(f).then((r) => {
        setFamilies(f);
        setRevenue(r);
        setPlanPrice(s.plans);
      }))
      // Without .catch/.finally the page hangs on "Loading…" on any read failure.
      .catch((e) => setError((e as Error).message || t('families.failedToLoadSubscriptions')))
      .finally(() => setLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
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
  const activeSubs = families.filter((f) => f.subscription.status === 'active');
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
        title={t('families.subscriptionsTitle')}
        subtitle={t('families.subscriptionsSubtitle', { count: subscribed })}
        actions={
          <button type="button" className="qa-btn qa-g" onClick={onExport}>
            {t('common.exportCsv')}
          </button>
        }
      />
      <PageContent>
        <div className="grid grid-cols-2 lg:grid-cols-3 gap-2 mb-3">
          <TopStat num={String(subscribed)} label={t('families.activeSubs')} change={t('families.liveChange')} />
          <TopStat num={`AED ${monthly.toLocaleString()}`} label={t('families.monthlyRevenue')} change={t('families.liveChange')} numClass="!text-[13px]" />
          <TopStat num={String(expiringSoon)} label={t('families.expiring3d')} change={t('families.watchChange')} numClass="!text-[#FFB347]" />
        </div>

        {loading && <PageLoader compact />}
        {error && <div className="px-3 py-4 text-[10px] text-rose-dark">{error}</div>}

        <TableCard title={t('families.planBreakdown')}>
          {Object.entries(planCounts).map(([plan, count]) => {
            const total = subscribed || 1;
            return (
              <Row key={plan}>
                <div className="flex-1 text-[10.5px] font-extrabold text-navy">
                  {subscriptionPlanLabel(plan)} · AED {planPrice[plan]}
                </div>
                <BarRow
                  pct={Math.min(100, (count / total) * 100)}
                  label={t('families.subsCount', { count })}
                  color={plan === 'weekly' ? '#FFB347' : plan === 'monthly' ? '#9B6EDB' : '#6DBF8A'}
                />
              </Row>
            );
          })}
          <Row highlight>
            <div className="flex-1 text-[10.5px] font-extrabold text-[#8090B0]">{t('families.notSubscribedFree')}</div>
            <BarRow pct={Math.min(100, (free / (families.length || 1)) * 100)} label={t('families.usersCount', { count: free })} color="#FFD8E8" />
          </Row>
        </TableCard>

        <TableCard title={t('families.activeSubscribers')}>
          {!loading && activeSubs.length === 0 ? (
            <div className="px-3 py-4 text-[10px] text-[#8090B0]">{t('families.noActiveSubscribersYet')}</div>
          ) : (
            activeSubs.map((f) => (
              <Row key={f.id}>
                <div className="flex-1 min-w-0">
                  <div className="text-[10.5px] font-extrabold text-navy">{f.fullName}</div>
                  <div className="text-[8.5px] font-semibold text-[#8090B0]">
                    {subscriptionPlanLabel(f.subscription.plan)} · {t('families.endsOn', { date: f.subscription.endDate ? fmtDate(f.subscription.endDate) : t('common.dash') })}
                  </div>
                </div>
                <StatusBadge variant="sub">{t('families.activeBadge')}</StatusBadge>
                <Link to={`/families/${f.id}`} className="text-[9px] font-bold text-purple font-fredoka no-underline ml-1">
                  {t('common.view')}
                </Link>
              </Row>
            ))
          )}
        </TableCard>
      </PageContent>
    </PageShell>
  );
}
