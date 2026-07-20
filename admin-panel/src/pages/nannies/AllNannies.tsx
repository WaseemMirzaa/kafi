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
import { FilterBar, FilterSelect, Pagination } from '../../components/ui/ListControls';
import { useListControls } from '../../hooks/useListControls';
import { NannyService, NannyRow } from '../../services/firestore';
import { initials, gradientFor } from '../../utils/avatar';
import { exportCsv } from '../../utils/csv';
import {
  availabilityLabel,
  jobTypeLabel,
  visaStatusLabel,
  salaryRange,
  emiratesList,
  listOr,
  yesNo,
  label,
} from '../../utils/nannyLabels';

const statusVariant: Record<string, string> = {
  approved: 'verified',
  pending: 'verify',
  rejected: 'rejected',
  draft: 'pending',
};

const STATUSES = ['draft', 'pending', 'approved', 'rejected'];

export default function AllNannies() {
  const [items, setItems] = useState<NannyRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [status, setStatus] = useState('all');

  useEffect(() => {
    setLoadError(null);
    NannyService.list()
      .then(setItems)
      .catch((e) => {
        setItems([]);
        setLoadError((e as Error).message || 'Failed to load nannies');
      })
      .finally(() => setLoading(false));
  }, []);

  const toggleBlock = async (n: NannyRow) => {
    setBusyId(n.id);
    try {
      if (n.blocked) {
        await NannyService.unblock(n.id);
      } else {
        await NannyService.block(n.id);
      }
      setItems((prev) => prev.map((x) => x.id === n.id ? { ...x, blocked: !x.blocked } : x));
    } finally {
      setBusyId(null);
    }
  };

  const extraFilter = useMemo(
    () => (n: NannyRow) => status === 'all' || n.status === status,
    [status],
  );

  const lc = useListControls(items, {
    search: (n, q) =>
      [n.fullName, n.nationality, n.city, n.currentArea, ...(n.languages ?? [])].some((s) =>
        s?.toLowerCase().includes(q),
      ),
    getDate: (n) => n.createdAt,
    extraFilter,
    pageSize: 8,
  });

  const stats = useMemo(() => {
    const approved = items.filter((n) => n.status === 'approved').length;
    const pendingDocs = items.filter((n) => n.status === 'pending').length;
    const rejected = items.filter((n) => n.status === 'rejected').length;
    return { approved, pendingDocs, rejected };
  }, [items]);

  const onExport = () => {
    exportCsv('nannies.csv', lc.filtered, [
      { header: 'ID', value: (r) => r.id },
      { header: 'Name', value: (r) => r.fullName },
      { header: 'Nationality', value: (r) => r.nationality },
      { header: 'City', value: (r) => r.city },
      { header: 'Area', value: (r) => r.currentArea ?? '' },
      { header: 'Age', value: (r) => String(r.age ?? '') },
      { header: 'Experience (yrs)', value: (r) => String(r.experienceYears ?? '') },
      { header: 'Languages', value: (r) => listOr(r.languages).replace('—', '') },
      { header: 'Visa status', value: (r) => label(visaStatusLabel, r.visaStatus).replace('—', '') },
      { header: 'Emirates ID', value: (r) => yesNo(r.hasEmiratesId) },
      { header: 'Work emirates', value: (r) => emiratesList(r.workEmirates).replace('—', '') },
      { header: 'Availability', value: (r) => label(availabilityLabel, r.availability).replace('—', '') },
      { header: 'Job type', value: (r) => label(jobTypeLabel, r.jobTypePreference).replace('—', '') },
      { header: 'Salary (AED)', value: (r) => salaryRange(r.expectedSalaryMin, r.expectedSalaryMax).replace('—', '') },
      { header: 'Can cook', value: (r) => yesNo(r.canCook) },
      { header: 'Live-in OK', value: (r) => (r.jobTypePreference === 'liveOut' ? 'no' : 'yes') },
      { header: 'Status', value: (r) => r.status },
      { header: 'Verified', value: (r) => (r.isVerified ? 'yes' : 'no') },
      { header: 'Profile %', value: (r) => String(r.profileScore ?? 0) },
    ]);
  };

  return (
    <PageShell>
      <PageHeader
        title="All nannies"
        subtitle={`${items.length} total · Manage profiles & verifications`}
        actions={
          <button type="button" className="qa-btn qa-g" onClick={onExport}>
            Export CSV
          </button>
        }
      />
      <PageContent>
        <div className="flex gap-1.5 mb-2.5">
          <ColStat num={String(stats.approved)} label="Active" change="↑ verified" />
          <ColStat num={String(stats.pendingDocs)} label="Pending docs" change="⚠ Review" numColor="#FFB347" />
          <ColStat num={String(stats.rejected)} label="Rejected" change="re-upload" numColor="#FF5C8A" />
        </div>

        <FilterBar
          query={lc.query}
          setQuery={lc.setQuery}
          from={lc.from}
          setFrom={lc.setFrom}
          to={lc.to}
          setTo={lc.setTo}
          onClear={() => {
            lc.clear();
            setStatus('all');
          }}
          searchPlaceholder="Search by name, nationality, city, language…"
          dateLabel="Submitted"
        >
          <FilterSelect
            label="Status"
            value={status}
            onChange={setStatus}
            options={[{ value: 'all', label: 'All statuses' }, ...STATUSES.map((s) => ({ value: s, label: s }))]}
          />
        </FilterBar>

        <TableCard title="All nannies">
          {loading && (
            <div className="px-3 py-4 text-[10px] text-[#8090B0]">Loading…</div>
          )}
          {!loading && loadError && (
            <div className="px-3 py-4 text-[10px] font-bold text-rose-dark">{loadError}</div>
          )}
          {!loading && !loadError && lc.total === 0 && (
            <div className="px-3 py-4 text-[10px] text-[#8090B0]">
              No nannies in Firestore yet. Complete nanny signup in the mobile app first.
            </div>
          )}
          {lc.pageItems.map((n) => (
            <Row key={n.id}>
              <Avatar letter={initials(n.fullName)} gradient={gradientFor(n.id)} />
              <div className="flex-1 min-w-0">
                <div className="text-[10.5px] font-extrabold text-navy">
                  {n.fullName}
                  {n.blocked && <span className="ml-1.5 text-[8px] font-bold text-rose-dark">[BLOCKED]</span>}
                </div>
                <div className="text-[8.5px] font-semibold text-[#8090B0] truncate">
                  {n.nationality} · {n.city}
                  {n.age ? ` · ${n.age}y` : ''}
                  {n.experienceYears ? ` · ${n.experienceYears} yrs` : ''}
                  {n.visaStatus ? ` · ${visaStatusLabel[n.visaStatus]}` : ''}
                </div>
                <div className="text-[8px] font-semibold text-[#A0ADC8] truncate mt-0.5">
                  {[
                    n.jobTypePreference ? jobTypeLabel[n.jobTypePreference] : null,
                    salaryRange(n.expectedSalaryMin, n.expectedSalaryMax) !== '—'
                      ? salaryRange(n.expectedSalaryMin, n.expectedSalaryMax)
                      : null,
                    listOr(n.languages) !== '—' ? listOr(n.languages) : null,
                  ]
                    .filter(Boolean)
                    .join(' · ')}
                </div>
              </div>
              {n.availability && (
                <StatusBadge variant={n.availability === 'availableNow' ? 'verified' : n.availability === 'onTrial' ? 'new' : 'pending'}>
                  {availabilityLabel[n.availability]}
                </StatusBadge>
              )}
              <StatusBadge variant={statusVariant[n.status] ?? 'pending'}>
                {n.status === 'approved' ? 'Verified' : n.status === 'pending' ? 'Needs review' : n.status}
              </StatusBadge>
              <button
                type="button"
                className={`text-[8.5px] font-bold px-2 py-0.5 rounded-md ml-1 ${n.blocked ? 'bg-green-pale text-green-dark' : 'bg-rose-pale text-rose-dark'}`}
                disabled={busyId === n.id}
                onClick={() => toggleBlock(n)}
              >
                {n.blocked ? 'Unblock' : 'Block'}
              </button>
              <Link to={`/nannies/${n.id}`} className="text-[9px] font-bold text-purple font-fredoka no-underline ml-1">
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
