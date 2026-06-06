import { useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  Avatar,
  ColStat,
  PageContent,
  PageHeader,
  PageShell,
  Row,
  StatusBadge,
  TableCard,
} from '../../components/ui/AdminUI';
import { FilterBar, FilterSelect, Pagination, distinctOptions } from '../../components/ui/ListControls';
import { useListControls } from '../../hooks/useListControls';
import { FamilyService, FamilyRow } from '../../services/firestore';
import { gradientFor, initials } from '../../utils/avatar';
import { exportCsv } from '../../utils/csv';

const statusVariant: Record<string, string> = {
  active: 'sub',
  cancelled: 'sub',
  free: 'unsub',
  expired: 'expired',
  paymentFailed: 'expired',
};

const statusLabel: Record<string, string> = {
  active: 'Subscribed',
  cancelled: 'Cancelled (in period)',
  free: 'Free / not subbed',
  expired: 'Expired',
  paymentFailed: 'Payment failed',
};

const SUB_STATUSES: FamilyRow['subscription']['status'][] = [
  'free',
  'active',
  'cancelled',
  'expired',
  'paymentFailed',
];

export default function AllFamilies() {
  const [items, setItems] = useState<FamilyRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [nationality, setNationality] = useState('all');
  const [city, setCity] = useState('all');
  const [subStatus, setSubStatus] = useState('all');

  useEffect(() => {
    FamilyService.list()
      .then(setItems)
      .finally(() => setLoading(false));
  }, []);

  const toggleBlock = async (f: FamilyRow) => {
    setBusyId(f.id);
    try {
      if (f.blocked) {
        await FamilyService.unblock(f.id);
      } else {
        await FamilyService.block(f.id);
      }
      setItems((prev) => prev.map((x) => x.id === f.id ? { ...x, blocked: !x.blocked } : x));
    } finally {
      setBusyId(null);
    }
  };

  const extraFilter = useMemo(
    () => (f: FamilyRow) =>
      (nationality === 'all' || f.nationality === nationality) &&
      (city === 'all' || f.city === city) &&
      (subStatus === 'all' || f.subscription.status === subStatus),
    [nationality, city, subStatus],
  );

  const lc = useListControls(items, {
    search: (f, q) => [f.fullName, f.nationality, f.city].some((s) => s?.toLowerCase().includes(q)),
    getDate: (f) => f.createdAt,
    extraFilter,
    pageSize: 8,
  });

  const nationalityOptions = useMemo(
    () => distinctOptions(items, (f) => f.nationality, 'All nationalities'),
    [items],
  );
  const cityOptions = useMemo(
    () => distinctOptions(items, (f) => f.city, 'All cities'),
    [items],
  );
  const subStatusOptions = [
    { value: 'all', label: 'All subscriptions' },
    ...SUB_STATUSES.map((s) => ({ value: s, label: statusLabel[s] ?? s })),
  ];

  const subscribed = items.filter((f) => ['active', 'cancelled'].includes(f.subscription.status)).length;
  const free = items.filter((f) => f.subscription.status === 'free').length;
  const expired = items.filter((f) => ['expired', 'paymentFailed'].includes(f.subscription.status)).length;

  const onExport = () => {
    exportCsv('families.csv', lc.filtered, [
      { header: 'ID', value: (r) => r.id },
      { header: 'Name', value: (r) => r.fullName },
      { header: 'Nationality', value: (r) => r.nationality },
      { header: 'City', value: (r) => r.city },
      { header: 'Status', value: (r) => r.subscription.status },
      { header: 'Plan', value: (r) => r.subscription.plan ?? '' },
      { header: 'EndDate', value: (r) => r.subscription.endDate?.toISOString() ?? '' },
      { header: 'FreeContactsUsed', value: (r) => String(r.freeContactsUsed ?? 0) },
    ]);
  };

  return (
    <PageShell>
      <PageHeader
        title="All families"
        subtitle={`${items.length} total · Manage accounts & subscriptions`}
        actions={
          <button type="button" className="qa-btn qa-g" onClick={onExport}>
            Export CSV
          </button>
        }
      />
      <PageContent>
        <div className="flex gap-1.5 mb-2.5">
          <ColStat num={String(subscribed)} label="Subscribed" change="↑ Active" />
          <ColStat num={String(free)} label="Free users" change="Convert" numColor="#8090B0" />
          <ColStat num={String(expired)} label="Expired" change="⚠ Reactivate" numColor="#FF5C8A" />
        </div>

        <FilterBar
          query={lc.query}
          setQuery={lc.setQuery}
          from={lc.from}
          setFrom={lc.setFrom}
          to={lc.to}
          setTo={lc.setTo}
          onClear={() => { lc.clear(); setNationality('all'); setCity('all'); setSubStatus('all'); }}
          searchPlaceholder="Search by name, nationality, city…"
          dateLabel="Joined"
        >
          <FilterSelect label="Subscription" value={subStatus} onChange={setSubStatus} options={subStatusOptions} />
          <FilterSelect label="Nationality" value={nationality} onChange={setNationality} options={nationalityOptions} />
          <FilterSelect label="City" value={city} onChange={setCity} options={cityOptions} />
        </FilterBar>

        <TableCard title="Family accounts">
          {loading && <div className="px-3 py-4 text-[10px] text-[#8090B0]">Loading…</div>}
          {!loading && lc.total === 0 && (
            <div className="px-3 py-4 text-[10px] text-[#8090B0]">No families match your filters.</div>
          )}
          {lc.pageItems.map((f) => (
            <Row key={f.id}>
              <Avatar letter={initials(f.fullName)} gradient={gradientFor(f.id)} />
              <div className="flex-1 min-w-0">
                <div className="text-[10.5px] font-extrabold text-navy">
                  {f.fullName}
                  {f.blocked && <span className="ml-1.5 text-[8px] font-bold text-rose-dark">[BLOCKED]</span>}
                </div>
                <div className="text-[8.5px] font-semibold text-[#8090B0]">
                  {f.nationality} · {f.city}
                  {f.subscription.plan ? ` · ${f.subscription.plan}` : ''}
                </div>
              </div>
              <div className="flex flex-col items-end gap-0.5">
                <StatusBadge variant={statusVariant[f.subscription.status] ?? 'pending'}>
                  {statusLabel[f.subscription.status] ?? f.subscription.status}
                </StatusBadge>
                {(f.activeTrialNannyIds?.length ?? 0) > 0 && (
                  <span className="text-[8px] font-bold text-purple">Trial active</span>
                )}
              </div>
              <button
                type="button"
                className={`text-[8.5px] font-bold px-2 py-0.5 rounded-md ml-1 ${f.blocked ? 'bg-green-pale text-green-dark' : 'bg-rose-pale text-rose-dark'}`}
                disabled={busyId === f.id}
                onClick={() => toggleBlock(f)}
              >
                {f.blocked ? 'Unblock' : 'Block'}
              </button>
              <Link to={`/families/${f.id}`} className="text-[9px] font-bold text-purple font-fredoka no-underline ml-1">
                View →
              </Link>
            </Row>
          ))}
          <Pagination
            page={lc.page}
            pageCount={lc.pageCount}
            rangeStart={lc.rangeStart}
            rangeEnd={lc.rangeEnd}
            total={lc.total}
            onPage={lc.setPage}
          />
        </TableCard>
      </PageContent>
    </PageShell>
  );
}
