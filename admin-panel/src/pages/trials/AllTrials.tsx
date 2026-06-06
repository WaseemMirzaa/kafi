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
import { TrialService, TrialAdminRow } from '../../services/firestore';
import { gradientFor, initials } from '../../utils/avatar';
import { exportCsv } from '../../utils/csv';
import { trialStatusVariant, fmtDate } from '../../utils/nannyLabels';
import { trialDayNumber, trialShortLeft } from '../../utils/trials';

const STATUSES = ['pending', 'countered', 'accepted', 'active', 'completed', 'declined', 'cancelled'];

export default function AllTrials() {
  const [items, setItems] = useState<TrialAdminRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [status, setStatus] = useState('all');

  useEffect(() => {
    TrialService.listAll()
      .then(setItems)
      .finally(() => setLoading(false));
  }, []);

  const extraFilter = useMemo(
    () => (t: TrialAdminRow) => status === 'all' || String(t.status) === status,
    [status],
  );

  const lc = useListControls(items, {
    search: (t, q) =>
      [t.nannyName, t.familyName, t.location, t.trialType, t.id].some((s) => s?.toLowerCase().includes(q)),
    getDate: (t) => t.startDate,
    extraFilter,
    pageSize: 8,
  });

  const stats = useMemo(() => {
    const active = items.filter((t) => t.status === 'active').length;
    const completed = items.filter((t) => t.status === 'completed').length;
    const pending = items.filter((t) => t.status === 'pending').length;
    const cancelled = items.filter((t) => t.status === 'cancelled').length;
    return { active, completed, pending, cancelled };
  }, [items]);

  const onExport = () => {
    exportCsv('trials.csv', lc.filtered, [
      { header: 'ID', value: (t) => t.id },
      { header: 'Nanny', value: (t) => t.nannyName ?? t.nannyId },
      { header: 'Family', value: (t) => t.familyName ?? t.familyId },
      { header: 'Status', value: (t) => String(t.status) },
      { header: 'Duration (days)', value: (t) => String(t.durationDays) },
      { header: 'Daily rate', value: (t) => String(t.dailyRate) },
      { header: 'Start', value: (t) => fmtDate(t.startDate) },
      { header: 'End', value: (t) => fmtDate(t.endDate) },
      { header: 'Location', value: (t) => t.location ?? '' },
      { header: 'Outcome', value: (t) => t.outcome ?? '' },
    ]);
  };

  return (
    <PageShell>
      <PageHeader
        title="Active trials"
        subtitle={`${items.length} total · Monitor nanny ↔ family trials`}
        actions={
          <button type="button" className="qa-btn qa-g" onClick={onExport}>
            Export CSV
          </button>
        }
      />
      <PageContent>
        <div className="flex gap-1.5 mb-2.5">
          <ColStat num={String(stats.active)} label="Active" change="● live" numColor="#9B6EDB" />
          <ColStat num={String(stats.pending)} label="Pending" change="⚠ awaiting" numColor="#FFB347" />
          <ColStat num={String(stats.completed)} label="Completed" change="↑ done" />
          <ColStat num={String(stats.cancelled)} label="Cancelled" change="dropped" numColor="#FF5C8A" />
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
          searchPlaceholder="Search by nanny, family, location…"
          dateLabel="Start date"
        >
          <FilterSelect
            label="Status"
            value={status}
            onChange={setStatus}
            options={[{ value: 'all', label: 'All statuses' }, ...STATUSES.map((s) => ({ value: s, label: s }))]}
          />
        </FilterBar>

        <TableCard title="Trials">
          {loading && <div className="px-3 py-4 text-[10px] text-[#8090B0]">Loading…</div>}
          {!loading && lc.total === 0 && (
            <div className="px-3 py-4 text-[10px] text-[#8090B0]">No trials match your filters.</div>
          )}
          {lc.pageItems.map((t) => {
            const dayNum = trialDayNumber(t);
            const ended = t.status === 'completed' || t.status === 'cancelled';
            return (
              <Row key={t.id}>
                <Avatar letter={initials(t.nannyName ?? 'N')} gradient={gradientFor(t.id)} />
                <div className="flex-1 min-w-0">
                  <div className="text-[10.5px] font-extrabold text-navy truncate">
                    {t.nannyName ?? t.nannyId} ↔ {t.familyName ?? t.familyId}
                  </div>
                  <div className="text-[8.5px] font-semibold text-[#8090B0] truncate">
                    {t.durationDays}-day trial · Day {dayNum}/{t.durationDays}
                    {t.location ? ` · ${t.location}` : ''}
                  </div>
                </div>
                <div className="flex flex-col items-end">
                  <StatusBadge variant={trialStatusVariant(String(t.status))}>{String(t.status)}</StatusBadge>
                  <span className={`text-[8px] font-bold mt-0.5 ${ended ? 'text-[#A0ADC8]' : 'text-green-dark'}`}>
                    {ended ? fmtDate(t.endDate) : trialShortLeft(t)}
                  </span>
                </div>
                <Link
                  to={`/trials/${t.id}`}
                  className="text-[9px] font-bold text-purple font-fredoka no-underline ml-1"
                >
                  View →
                </Link>
              </Row>
            );
          })}
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
