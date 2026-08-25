import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  ColStat,
  PageContent,
  PageHeader,
  PageShell,
  Row,
  StatusBadge,
  TableCard,
  PageLoader,
} from '../../components/ui/AdminUI';
import { DisputeService, DisputeRow } from '../../services/firestore';
import { useLocale } from '../../context/LocaleContext';
import { TranslationKey } from '../../locales/t';
import { disputeStatusLabel } from '../../utils/nannyLabels';

const statusVariant: Record<DisputeRow['status'], string> = {
  open: 'verify',
  investigating: 'new',
  resolved: 'verified',
  dismissed: 'rejected',
};

const categoryLabelKeys: Record<DisputeRow['category'], TranslationKey> = {
  fraud: 'reports.category.fraud',
  abuse: 'reports.category.abuse',
  no_show: 'reports.category.no_show',
  payment: 'reports.category.payment',
  other: 'reports.category.other',
};

export default function Disputes() {
  const { t } = useLocale();
  const [items, setItems] = useState<DisputeRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  function displayName(name: string | undefined, fallback: string): string {
    const trimmed = name?.trim();
    return trimmed ? trimmed : fallback;
  }

  useEffect(() => {
    DisputeService.list()
      .then(setItems)
      .catch((e) => setError((e as Error).message || t('reports.failedToLoad')))
      .finally(() => setLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const openCount = items.filter((d) => d.status === 'open').length;
  const investigating = items.filter((d) => d.status === 'investigating').length;
  const resolved = items.filter((d) => d.status === 'resolved').length;

  return (
    <PageShell>
      <PageHeader
        title={t('reports.title')}
        subtitle={t('reports.subtitle', { open: openCount, investigating })}
      />
      <PageContent>
        <div className="flex gap-1.5 mb-2.5">
          <ColStat num={String(openCount)} label={t('reports.open')} change={t('reports.newChange')} numColor="#FFB347" />
          <ColStat num={String(investigating)} label={t('reports.investigating')} change={t('reports.inProgress')} numColor="#9B6EDB" />
          <ColStat num={String(resolved)} label={t('reports.resolved')} change={t('reports.closedChange')} />
        </div>

        <TableCard title={t('reports.queue')}>
          {loading && <PageLoader compact />}
          {!loading && error && (
            <div className="px-3 py-4 text-[10px] font-bold text-rose-dark">{error}</div>
          )}
          {!loading && !error && items.length === 0 && (
            <div className="px-3 py-4 text-[10px] text-[#8090B0]">{t('reports.noneFiled')}</div>
          )}
          {items.map((d) => (
            <Row key={d.id}>
              <div className="flex-1 min-w-0">
                <div className="text-[10.5px] font-extrabold text-navy">
                  {t(categoryLabelKeys[d.category])} · {displayName(d.reporterName, t('reports.reporter'))} →{' '}
                  {displayName(d.reportedName, t('reports.reportedUser'))}
                </div>
                <div className="text-[8.5px] font-semibold text-[#8090B0] truncate">
                  {d.createdAt.toLocaleDateString()} · {d.description.substring(0, 80)}
                  {(d.attachments?.length ?? 0) > 0
                    ? ` · 📎 ${d.attachments!.length}`
                    : ''}
                </div>
                <div className="text-[7.5px] font-semibold text-[#A0ADC8] truncate mt-0.5">
                  {d.reporterId} → {d.reportedUserId}
                  {d.relatedTrialId ? ` · trial ${d.relatedTrialId}` : ''}
                </div>
              </div>
              <StatusBadge variant={statusVariant[d.status]}>{disputeStatusLabel(d.status)}</StatusBadge>
              <Link
                to={`/reports/${d.id}`}
                className="text-[9px] font-bold text-purple font-fredoka no-underline ml-1"
              >
                {t('reports.openChat')}
              </Link>
            </Row>
          ))}
        </TableCard>
      </PageContent>
    </PageShell>
  );
}
