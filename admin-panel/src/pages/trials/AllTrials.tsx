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
  PageLoader,
} from '../../components/ui/AdminUI';
import { FilterBar, FilterSelect, Pagination } from '../../components/ui/ListControls';
import { useListControls } from '../../hooks/useListControls';
import { TrialService, TrialAdminRow } from '../../services/firestore';
import { gradientFor, initials } from '../../utils/avatar';
import { exportCsv } from '../../utils/csv';
import { trialStatusVariant, trialStatusLabel, fmtDate } from '../../utils/nannyLabels';
import { trialDayNumber, trialShortLeft } from '../../utils/trials';
import { useLocale } from '../../context/LocaleContext';

const STATUSES = ['pending', 'countered', 'accepted', 'active', 'completed', 'declined', 'cancelled'];

export default function AllTrials() {
  const { t: translate } = useLocale();
  const [items, setItems] = useState<TrialAdminRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [status, setStatus] = useState('all');

  useEffect(() => {
    TrialService.listAll()
      .then(setItems)
      .catch((e) => setError((e as Error).message || translate('trials.failedToLoad')))
      .finally(() => setLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
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
        title={translate('trials.allTrialsTitle')}
        subtitle={translate('trials.allTrialsSubtitle', { count: items.length })}
        actions={
          <button type="button" className="qa-btn qa-g" onClick={onExport}>
            {translate('common.exportCsv')}
          </button>
        }
      />
      <PageContent>
        <div className="flex gap-1.5 mb-2.5">
          <ColStat num={String(stats.active)} label={translate('trials.active')} change={translate('trials.liveDot')} numColor="#9B6EDB" />
          <ColStat num={String(stats.pending)} label={translate('trials.pending')} change={translate('trials.awaiting')} numColor="#FFB347" />
          <ColStat num={String(stats.completed)} label={translate('trials.completed')} change={translate('trials.doneChange')} />
          <ColStat num={String(stats.cancelled)} label={translate('trials.cancelled')} change={translate('trials.dropped')} numColor="#FF5C8A" />
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
          searchPlaceholder={translate('trials.searchPlaceholder')}
          dateLabel={translate('trials.startDate')}
        >
          <FilterSelect
            label={translate('common.status')}
            value={status}
            onChange={setStatus}
            options={[
              { value: 'all', label: translate('trials.allStatuses') },
              ...STATUSES.map((s) => ({ value: s, label: trialStatusLabel(s) })),
            ]}
          />
        </FilterBar>

        <TableCard title={translate('nannies.trials')}>
          {loading && <PageLoader compact />}
          {!loading && error && (
            <div className="px-3 py-4 text-[10px] font-bold text-rose-dark">{error}</div>
          )}
          {!loading && !error && lc.total === 0 && (
            <div className="px-3 py-4 text-[10px] text-[#8090B0]">{translate('trials.noMatchFilters')}</div>
          )}
          {lc.pageItems.map((row) => {
            const dayNum = trialDayNumber(row);
            const ended = row.status === 'completed' || row.status === 'cancelled';
            return (
              <Row key={row.id}>
                <Avatar letter={initials(row.nannyName ?? 'N')} gradient={gradientFor(row.id)} />
                <div className="flex-1 min-w-0">
                  <div className="text-[10.5px] font-extrabold text-navy truncate">
                    {row.nannyName ?? row.nannyId} ↔ {row.familyName ?? row.familyId}
                  </div>
                  <div className="text-[8.5px] font-semibold text-[#8090B0] truncate">
                    {translate('trials.dayTrial', { days: row.durationDays, day: dayNum, total: row.durationDays })}
                    {row.location ? ` · ${row.location}` : ''}
                  </div>
                </div>
                <div className="flex flex-col items-end">
                  <StatusBadge variant={trialStatusVariant(String(row.status))}>{trialStatusLabel(row.status)}</StatusBadge>
                  <span className={`text-[8px] font-bold mt-0.5 ${ended ? 'text-[#A0ADC8]' : 'text-green-dark'}`}>
                    {ended ? fmtDate(row.endDate) : trialShortLeft(row)}
                  </span>
                </div>
                <Link
                  to={`/trials/${row.id}`}
                  className="text-[9px] font-bold text-purple font-fredoka no-underline ml-1"
                >
                  {translate('common.view')}
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
