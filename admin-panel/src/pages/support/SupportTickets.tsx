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
import { TicketService, TicketRow } from '../../services/firestore';
import { useLocale } from '../../context/LocaleContext';
import { TranslationKey } from '../../locales/t';
import { ticketStatusLabel, personTypeLabel } from '../../utils/nannyLabels';

const statusVariant: Record<TicketRow['status'], string> = {
  open: 'verify',
  investigating: 'new',
  resolved: 'verified',
  closed: 'rejected',
};

const categoryLabelKeys: Record<TicketRow['category'], TranslationKey> = {
  account: 'support.category.account',
  payment: 'support.category.payment',
  trial: 'support.category.trial',
  hiring: 'support.category.hiring',
  technical: 'support.category.technical',
  other: 'support.category.other',
};

export default function SupportTickets() {
  const { t } = useLocale();
  const [items, setItems] = useState<TicketRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    TicketService.list()
      .then(setItems)
      .catch((e) => setError((e as Error).message || t('support.failedToLoad')))
      .finally(() => setLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const openCount = items.filter((tk) => tk.status === 'open').length;
  const investigating = items.filter((tk) => tk.status === 'investigating').length;
  const resolved = items.filter((tk) => tk.status === 'resolved' || tk.status === 'closed').length;

  return (
    <PageShell>
      <PageHeader title={t('support.title')} subtitle={t('support.subtitle', { open: openCount, investigating })} />
      <PageContent>
        <div className="flex gap-1.5 mb-2.5">
          <ColStat num={String(openCount)} label={t('support.open')} change={t('support.newChange')} numColor="#FFB347" />
          <ColStat num={String(investigating)} label={t('support.inProgress')} change={t('support.activeChange')} numColor="#9B6EDB" />
          <ColStat num={String(resolved)} label={t('support.resolved')} change={t('support.closedChange')} />
        </div>

        <TableCard title={t('support.queue')}>
          {loading && <PageLoader compact />}
          {!loading && error && (
            <div className="px-3 py-4 text-[10px] font-bold text-rose-dark">{error}</div>
          )}
          {!loading && !error && items.length === 0 && (
            <div className="px-3 py-4 text-[10px] text-[#8090B0]">{t('support.noneYet')}</div>
          )}
          {items.map((tk) => (
            <Row key={tk.id}>
              <div className="flex-1 min-w-0">
                <div className="text-[10.5px] font-extrabold text-navy truncate">
                  {tk.subject || t(categoryLabelKeys[tk.category])}
                </div>
                <div className="text-[8.5px] font-semibold text-[#8090B0] truncate">
                  {t(categoryLabelKeys[tk.category])} · {tk.openerName ?? tk.openerId} ({personTypeLabel(tk.openerType)}) ·{' '}
                  {tk.createdAt.toLocaleDateString()}
                </div>
              </div>
              <StatusBadge variant={statusVariant[tk.status]}>{ticketStatusLabel(tk.status)}</StatusBadge>
              <Link
                to={`/support/${tk.id}`}
                className="text-[9px] font-bold text-purple font-fredoka no-underline ml-1"
              >
                {t('support.openLink')}
              </Link>
            </Row>
          ))}
        </TableCard>
      </PageContent>
    </PageShell>
  );
}
