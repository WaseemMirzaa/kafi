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
import { DisputeService, DisputeRow } from '../../services/firestore';

const statusVariant: Record<DisputeRow['status'], string> = {
  open: 'verify',
  investigating: 'new',
  resolved: 'verified',
  dismissed: 'rejected',
};

const categoryLabel: Record<DisputeRow['category'], string> = {
  fraud: 'Fraud',
  abuse: 'Abuse',
  no_show: 'No show',
  payment: 'Payment',
  other: 'Other',
};

export default function Disputes() {
  const [items, setItems] = useState<DisputeRow[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    DisputeService.list()
      .then(setItems)
      .finally(() => setLoading(false));
  }, []);

  const openCount = items.filter((d) => d.status === 'open').length;
  const investigating = items.filter((d) => d.status === 'investigating').length;
  const resolved = items.filter((d) => d.status === 'resolved').length;

  return (
    <PageShell>
      <PageHeader
        title="Disputes & reports"
        subtitle={`${openCount} open · ${investigating} investigating`}
      />
      <PageContent>
        <div className="flex gap-1.5 mb-2.5">
          <ColStat num={String(openCount)} label="Open" change="⚠ New" numColor="#FFB347" />
          <ColStat num={String(investigating)} label="Investigating" change="• In progress" numColor="#9B6EDB" />
          <ColStat num={String(resolved)} label="Resolved" change="↑ Closed" />
        </div>

        <TableCard title="Reports queue">
          {loading && <div className="px-3 py-4 text-[10px] text-[#8090B0]">Loading…</div>}
          {!loading && items.length === 0 && (
            <div className="px-3 py-4 text-[10px] text-[#8090B0]">No disputes filed.</div>
          )}
          {items.map((d) => (
            <Row key={d.id}>
              <div className="flex-1 min-w-0">
                <div className="text-[10.5px] font-extrabold text-navy">
                  {categoryLabel[d.category]} · {d.reporterName ?? d.reporterId} → {d.reportedName ?? d.reportedUserId}
                </div>
                <div className="text-[8.5px] font-semibold text-[#8090B0] truncate">
                  {d.createdAt.toLocaleDateString()} · {d.description.substring(0, 80)}
                </div>
              </div>
              <StatusBadge variant={statusVariant[d.status]}>{d.status}</StatusBadge>
              <Link
                to={`/disputes/${d.id}`}
                className="text-[9px] font-bold text-purple font-fredoka no-underline ml-1"
              >
                Open chat →
              </Link>
            </Row>
          ))}
        </TableCard>
      </PageContent>
    </PageShell>
  );
}
