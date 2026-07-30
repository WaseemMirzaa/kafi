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

export default function AllFamilies() {
  const [items, setItems] = useState<FamilyRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [busyId, setBusyId] = useState<string | null>(null);

  useEffect(() => {
    setLoadError(null);
    FamilyService.list()
      .then(setItems)
      .catch((e) => setLoadError((e as Error).message || 'Failed to load families'))
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
    } catch (e) {
      // Without this the failure was swallowed — the admin assumed the block
      // took when it didn't. Surface it (NannyDetail uses the same alert).
      alert((e as Error).message || 'Block toggle failed');
    } finally {
      setBusyId(null);
    }
  };

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return items;
    return items.filter((f) =>
      [f.fullName, f.nationality, f.city].some((s) => s?.toLowerCase().includes(q))
    );
  }, [items, search]);

  const subscribed = items.filter((f) => ['active', 'cancelled'].includes(f.subscription.status)).length;
  const free = items.filter((f) => f.subscription.status === 'free').length;
  const expired = items.filter((f) => ['expired', 'paymentFailed'].includes(f.subscription.status)).length;

  const onExport = () => {
    exportCsv('families.csv', filtered, [
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
          <>
            <input
              type="search"
              placeholder="Search families…"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="admin-card text-[10px] font-semibold text-navy px-3 py-2 w-52 border-[#EBEEF8] focus:outline-none"
            />
            <button type="button" className="qa-btn qa-g" onClick={onExport}>
              Export CSV
            </button>
          </>
        }
      />
      <PageContent>
        <div className="flex gap-1.5 mb-2.5">
          <ColStat num={String(subscribed)} label="Subscribed" change="↑ Active" />
          <ColStat num={String(free)} label="Free users" change="Convert" numColor="#8090B0" />
          <ColStat num={String(expired)} label="Expired" change="⚠ Reactivate" numColor="#FF5C8A" />
        </div>

        <TableCard title="Family accounts">
          {loading && <div className="px-3 py-4 text-[10px] text-[#8090B0]">Loading…</div>}
          {!loading && loadError && (
            <div className="px-3 py-4 text-[10px] font-bold text-rose-dark">{loadError}</div>
          )}
          {!loading && !loadError && filtered.length === 0 && (
            <div className="px-3 py-4 text-[10px] text-[#8090B0]">No families found.</div>
          )}
          {filtered.map((f) => (
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
        </TableCard>
      </PageContent>
    </PageShell>
  );
}
