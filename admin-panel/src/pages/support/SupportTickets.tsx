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
} from '../../components/ui/AdminUI';
import { TicketService, TicketRow } from '../../services/firestore';

const statusVariant: Record<TicketRow['status'], string> = {
  open: 'verify',
  investigating: 'new',
  resolved: 'verified',
  closed: 'rejected',
};

const categoryLabel: Record<TicketRow['category'], string> = {
  account: 'Account',
  payment: 'Payment',
  trial: 'Trial',
  hiring: 'Hiring',
  technical: 'Technical',
  other: 'Other',
};

export default function SupportTickets() {
  const [items, setItems] = useState<TicketRow[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    TicketService.list()
      .then(setItems)
      .catch(() => setItems([]))
      .finally(() => setLoading(false));
  }, []);

  const openCount = items.filter((t) => t.status === 'open').length;
  const investigating = items.filter((t) => t.status === 'investigating').length;
  const resolved = items.filter((t) => t.status === 'resolved' || t.status === 'closed').length;

  return (
    <PageShell>
      <PageHeader title="Support tickets" subtitle={`${openCount} open · ${investigating} in progress`} />
      <PageContent>
        <div className="flex gap-1.5 mb-2.5">
          <ColStat num={String(openCount)} label="Open" change="⚠ New" numColor="#FFB347" />
          <ColStat num={String(investigating)} label="In progress" change="• Active" numColor="#9B6EDB" />
          <ColStat num={String(resolved)} label="Resolved" change="↑ Closed" />
        </div>

        <TableCard title="Tickets queue">
          {loading && <div className="px-3 py-4 text-[10px] text-[#8090B0]">Loading…</div>}
          {!loading && items.length === 0 && (
            <div className="px-3 py-4 text-[10px] text-[#8090B0]">No tickets yet.</div>
          )}
          {items.map((t) => (
            <Row key={t.id}>
              <div className="flex-1 min-w-0">
                <div className="text-[10.5px] font-extrabold text-navy truncate">
                  {t.subject || categoryLabel[t.category]}
                </div>
                <div className="text-[8.5px] font-semibold text-[#8090B0] truncate">
                  {categoryLabel[t.category]} · {t.openerName ?? t.openerId} ({t.openerType}) ·{' '}
                  {t.createdAt.toLocaleDateString()}
                </div>
              </div>
              <StatusBadge variant={statusVariant[t.status]}>{t.status}</StatusBadge>
              <Link
                to={`/support/${t.id}`}
                className="text-[9px] font-bold text-purple font-fredoka no-underline ml-1"
              >
                Open →
              </Link>
            </Row>
          ))}
        </TableCard>
      </PageContent>
    </PageShell>
  );
}
