import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { FamilyService, NannyService, NannyRow, FamilyRow, RevenueService, TrialService, TrialAdminRow } from '../services/firestore';
import { gradientFor, initials } from '../utils/avatar';
import { useAuthStore } from '../hooks/useAuth';
import { exportCsv } from '../utils/csv';

const muted = '#8090B0';

function TopStat({ num, label, change, numClass = '' }: { num: string; label: string; change: string; numClass?: string }) {
  return (
    <div className="admin-card p-2.5">
      <div className={`text-[17px] font-black text-navy ${numClass}`}>{num}</div>
      <div className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide mt-0.5">{label}</div>
      <div className="text-[8px] font-bold mt-0.5 cs-up">{change}</div>
    </div>
  );
}

function RevCard({
  label,
  amount,
  sub,
  pct,
  color,
  borderRose,
}: {
  label: string;
  amount: string;
  sub: string;
  pct: number;
  color: string;
  borderRose?: boolean;
}) {
  return (
    <div className={`admin-card p-2.5 ${borderRose ? 'border-[#FFD8E8]' : ''}`}>
      <div className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide mb-1">{label}</div>
      <div className="text-[15px] font-black mb-0.5" style={{ color }}>
        {amount}
      </div>
      <div className="text-[8.5px] text-[#8090B0] mb-1">{sub}</div>
      <div className="h-1 bg-[#F0F1FA] rounded-sm overflow-hidden">
        <div className="h-full rounded-sm" style={{ width: `${pct}%`, background: color }} />
      </div>
    </div>
  );
}

function ColStat({ num, label, change, numColor }: { num: string; label: string; change: string; numColor?: string }) {
  return (
    <div className="admin-card flex-1 p-2 text-center">
      <div className="text-[15px] font-black text-navy" style={numColor ? { color: numColor } : undefined}>
        {num}
      </div>
      <div className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide mt-0.5">{label}</div>
      <div className="text-[8px] font-bold mt-0.5" style={{ color: change.includes('⚠') ? '#FFB347' : change.includes('Convert') ? '#FFB347' : change.includes('Good') || change.includes('↑') ? '#2E9A58' : muted }}>
        {change}
      </div>
    </div>
  );
}

function StatusBadge({ children, variant }: { children: React.ReactNode; variant: string }) {
  const styles: Record<string, string> = {
    active: 'bg-[#E8F8EE] text-[#2A8A50]',
    pending: 'bg-amber-light text-[#A06010]',
    new: 'bg-purple-light text-purple',
    sub: 'bg-[#E8F8EE] text-[#2A8A50]',
    unsub: 'bg-rose-pale text-rose-dark',
    verify: 'bg-amber-light text-[#A06010]',
  };
  return (
    <span className={`text-[8.5px] font-bold font-fredoka px-[7px] py-0.5 rounded-full ${styles[variant]}`}>
      {children}
    </span>
  );
}

function Avatar({ letter, gradient }: { letter: string; gradient: string }) {
  return (
    <div
      className="w-[26px] h-[26px] rounded-lg flex items-center justify-center text-[11px] font-extrabold text-white flex-shrink-0"
      style={{ background: gradient }}
    >
      {letter}
    </div>
  );
}

function BarRow({ pct, label, color }: { pct: number; label: string; color: string }) {
  return (
    <div className="flex items-center gap-1.5">
      <div className="w-[55px] h-1 bg-[#F0F1FA] rounded-sm overflow-hidden flex-shrink-0">
        <div className="h-full rounded-sm" style={{ width: `${pct}%`, background: color }} />
      </div>
      <span className="text-[10px] font-bold text-navy">{label}</span>
    </div>
  );
}

function TableCard({
  title,
  action,
  actionTo,
  onAction,
  children,
}: {
  title: string;
  action?: string;
  actionTo?: string;
  onAction?: () => void;
  children: React.ReactNode;
}) {
  const actionCls = 'text-[9.5px] font-bold text-purple font-fredoka no-underline';
  return (
    <div className="admin-table">
      <div className="flex items-center justify-between px-[11px] py-2 border-b border-[#EBEEF8]">
        <h4 className="text-[11px] font-extrabold text-navy">{title}</h4>
        {action && actionTo ? (
          <Link to={actionTo} className={actionCls}>
            {action}
          </Link>
        ) : action ? (
          <button type="button" className={actionCls} onClick={onAction}>
            {action}
          </button>
        ) : null}
      </div>
      {children}
    </div>
  );
}

function Row({ children, highlight }: { children: React.ReactNode; highlight?: boolean }) {
  return (
    <div
      className={`flex items-center gap-[7px] px-[11px] py-2 border-b border-[#F4F5FC] last:border-b-0 hover:bg-[#F8F9FD] transition-colors ${highlight ? 'bg-[#FFF5F8]' : ''}`}
    >
      {children}
    </div>
  );
}

// Fixed business constants: plan keys → display label + color
const planMeta: Record<string, { label: string; color: string }> = {
  weekly:    { label: 'Weekly · AED 89',    color: '#FFB347' },
  monthly:   { label: 'Monthly · AED 239',  color: '#9B6EDB' },
  twoMonths: { label: '2 months · AED 369', color: '#2E9A58' },
};

export default function Dashboard() {
  const today = new Date().toLocaleDateString('en-GB', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  });

  const adminId = useAuthStore((s) => s.user?.uid ?? 'admin_001');
  const [nannies, setNannies] = useState<NannyRow[]>([]);
  const [pendingDocs, setPendingDocs] = useState<NannyRow[]>([]);
  const [families, setFamilies] = useState<FamilyRow[]>([]);
  const [activeTrials, setActiveTrials] = useState<TrialAdminRow[]>([]);
  const [monthlyRevenue, setMonthlyRevenue] = useState<number>(0);
  const [monthlyVat, setMonthlyVat] = useState<number>(0);
  const [byPlan, setByPlan] = useState<{ plan: string; subs: number; revenue: number }[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [actingId, setActingId] = useState<string | null>(null);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      // Fetch families once and hand them to summary() so it doesn't re-list
      // them (it derives MRR/plan split from the same set).
      const fams = await FamilyService.list();
      const [allN, pend, rev, trials] = await Promise.all([
        NannyService.list(),
        NannyService.listPendingDocs(),
        RevenueService.summary(fams),
        TrialService.listActive(),
      ]);
      setNannies(allN);
      setPendingDocs(pend);
      setFamilies(fams);
      setMonthlyRevenue(rev.monthly);
      setMonthlyVat(rev.vat);
      setByPlan(rev.byPlan);
      setActiveTrials(trials);
    } catch (e) {
      setError((e as Error).message || 'Failed to load dashboard');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void load();
  }, []);

  const totalUsers = nannies.length + families.length;
  const activeSubs = families.filter((f) => f.subscription.status === 'active').length;
  const activeNannies = nannies.filter((n) => n.status === 'approved').length;
  const subscribedCount = families.filter((f) => f.subscription.status === 'active').length;
  const freeCount = families.filter((f) => f.subscription.status === 'free').length;
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);
  const newTodayCount = families.filter((f) => f.createdAt && f.createdAt >= todayStart).length;

  async function handleApprove(id: string) {
    setActingId(id);
    try {
      await NannyService.approve(id, adminId);
      await load();
    } catch (e) {
      alert((e as Error).message || 'Approve failed');
    } finally {
      setActingId(null);
    }
  }

  async function handleReject(id: string) {
    const reason = prompt('Reason for rejection?');
    if (reason == null) return;
    setActingId(id);
    try {
      await NannyService.reject(id, reason || 'No reason provided', adminId);
      await load();
    } catch (e) {
      alert((e as Error).message || 'Reject failed');
    } finally {
      setActingId(null);
    }
  }

  // Derived: max revenue across plans (guard against empty/zero)
  const maxRevenue = Math.max(...byPlan.map((p) => p.revenue), 1);
  const planOf = (key: string) => byPlan.find((p) => p.plan === key);

  return (
    <div className="flex flex-col flex-1">
      {/* Header */}
      <div className="flex flex-wrap justify-between items-start gap-2.5 px-[18px] pt-4 pb-0 mb-3">
        <div>
          <h1 className="text-base font-black text-navy">Dashboard</h1>
          <p className="text-[10px] font-semibold text-[#8090B0] mt-0.5">Welcome back 🌸 — {today}</p>
        </div>
        <div className="flex flex-wrap gap-1.5">
          <Link to="/nannies/verify" className="qa-btn qa-r">
            <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
              <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
              <polyline points="22 4 12 14.01 9 11.01" />
            </svg>
            Verify docs ({pendingDocs.length})
          </Link>
          <Link to="/revenue" className="qa-btn qa-g">
            <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
              <line x1="12" y1="1" x2="12" y2="23" />
              <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" />
            </svg>
            View revenue
          </Link>
          <Link to="/broadcast" className="qa-btn qa-p">
            <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
              <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
              <polyline points="22,6 12,13 2,6" />
            </svg>
            Broadcast
          </Link>
        </div>
      </div>

      {error && (
        <div className="mx-[18px] mb-2 p-2 bg-rose-pale text-rose-dark text-[10px] font-bold rounded-lg">
          {error}
        </div>
      )}

      {/* Top stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-2 px-[18px] pb-3">
        <TopStat num={loading ? '—' : String(totalUsers)} label="Total users" change="" />
        <TopStat num={loading ? '—' : String(activeSubs)} label="Active subs" change="" />
        <TopStat num={loading ? '—' : `AED ${monthlyRevenue.toLocaleString()}`} label="This month revenue" change="" numClass="!text-[13px]" />
        <div className="admin-card p-2.5">
          <div className="text-[17px] font-black text-navy">{loading ? '—' : `AED ${monthlyVat.toLocaleString()}`}</div>
          <div className="text-[11px] font-black text-[#8090B0] mt-0.5">VAT collected</div>
          <div className="text-[8px] font-bold mt-0.5 text-[#8090B0]">→ FTA</div>
        </div>
      </div>

      {/* Revenue row — original 4-card layout fed with live byPlan/vat values */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-2 px-[18px] pb-3">
        {Object.entries(planMeta).map(([key, meta]) => {
          const p = planOf(key);
          return (
            <RevCard
              key={key}
              label={meta.label}
              amount={loading ? '—' : `AED ${(p?.revenue ?? 0).toLocaleString()}`}
              sub={loading ? '' : `${p?.subs ?? 0} active`}
              pct={Math.round(((p?.revenue ?? 0) / maxRevenue) * 100)}
              color={meta.color}
            />
          );
        })}
        <RevCard
          label="VAT (5%)"
          amount={loading ? '—' : `AED ${monthlyVat.toLocaleString()}`}
          sub="Due to FTA"
          pct={100}
          color="#FF8FAB"
          borderRose
        />
      </div>

      <div className="h-px bg-[#EBEEF8] mx-[18px] mb-3" />

      {/* Two columns */}
      <div className="flex flex-col xl:flex-row flex-1">
        {/* Nannies */}
        <div className="flex-1 px-[18px] pb-[18px] xl:border-r border-[#EBEEF8]">
          <div className="flex items-center gap-1.5 mb-0.5">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#FF5C8A" strokeWidth="2.5" strokeLinecap="round">
              <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
              <circle cx="12" cy="7" r="4" />
            </svg>
            <h2 className="text-[13px] font-black text-navy">Nannies</h2>
            <span className="text-[10px] font-bold text-white bg-rose-dark px-2 py-0.5 rounded-full ml-1">{loading ? '—' : `${nannies.length} total`}</span>
          </div>
          <p className="text-[9px] font-semibold text-[#8090B0] mb-2.5">Manage profiles & verifications</p>

          <div className="flex gap-1.5 mb-2.5">
            <ColStat num={loading ? '—' : String(activeNannies)} label="Active" change="" />
            <ColStat num={loading ? '—' : String(pendingDocs.length)} label="Pending docs" change="⚠ Review" numColor="#FFB347" />
          </div>

          <TableCard title="📋 Document verification queue" action={`View all (${pendingDocs.length})`} actionTo="/nannies/verify">
            {pendingDocs.length === 0 && !loading ? (
              <div className="px-3 py-4 text-[10.5px] text-[#8090B0]">No nannies awaiting verification.</div>
            ) : null}
            {pendingDocs.slice(0, 5).map((n) => {
              const docs = n.documents ?? [];
              const subtitle = `${n.nationality || '—'} · ${docs.length ? docs.map((d) => `${d.type} ${d.status === 'approved' ? '✓' : d.status === 'rejected' ? '✗' : '⏳'}`).join(' · ') : 'Awaiting docs'}`;
              const letter = (n.fullName || 'N').charAt(0).toUpperCase();
              return (
                <Row key={n.id}>
                  <Avatar letter={letter} gradient="linear-gradient(135deg,#FFB347,#FF8042)" />
                  <div className="flex-1 min-w-0">
                    <div className="text-[10.5px] font-extrabold text-navy">{n.fullName}</div>
                    <div className="text-[8.5px] font-semibold text-[#8090B0] truncate">{subtitle}</div>
                  </div>
                  <div className="flex flex-col items-end gap-1">
                    <StatusBadge variant="verify">Needs review</StatusBadge>
                    <div className="flex gap-1">
                      <button
                        type="button"
                        className="verify-btn"
                        disabled={actingId === n.id}
                        onClick={() => handleApprove(n.id)}
                      >
                        {actingId === n.id ? '…' : 'Approve ✓'}
                      </button>
                      <button
                        type="button"
                        className="reject-btn"
                        disabled={actingId === n.id}
                        onClick={() => handleReject(n.id)}
                      >
                        {actingId === n.id ? '…' : 'Reject ✗'}
                      </button>
                    </div>
                  </div>
                </Row>
              );
            })}
          </TableCard>

          <TableCard title="All nannies" action="View all" actionTo="/nannies">
            {loading && <div className="px-3 py-4 text-[10px] text-[#8090B0]">Loading…</div>}
            {nannies.slice(0, 5).map((n) => {
              const badgeVariant = n.status === 'approved' ? 'active' : n.status === 'pending' ? 'verify' : 'pending';
              const sub = [
                n.nationality,
                n.city,
                n.experienceYears ? `${n.experienceYears}y` : null,
                n.introVideoUrl ? (n.introVideoStatus === 'approved' ? 'Video ✓' : 'Video ⏳') : 'No video',
              ].filter(Boolean).join(' · ');
              return (
                <Row key={n.id}>
                  <Avatar letter={initials(n.fullName)} gradient={gradientFor(n.id)} />
                  <div className="flex-1 min-w-0">
                    <div className="text-[10.5px] font-extrabold text-navy">{n.fullName}</div>
                    <div className="text-[8.5px] font-semibold text-[#8090B0] truncate">{sub}</div>
                  </div>
                  <StatusBadge variant={badgeVariant}>{n.status}</StatusBadge>
                </Row>
              );
            })}
          </TableCard>

          {(() => {
            // Nationality breakdown from live data
            const counts: Record<string, number> = {};
            nannies.forEach((n) => { counts[n.nationality] = (counts[n.nationality] ?? 0) + 1; });
            const sorted = Object.entries(counts).sort((a, b) => b[1] - a[1]).slice(0, 5);
            const total = nannies.length || 1;
            const colors = ['#FF8FAB', '#FFB347', '#6DBF8A', '#9B6EDB', muted];
            return (
              <TableCard
                title="Nationality breakdown"
                action="Export CSV"
                onAction={() =>
                  exportCsv(
                    'nanny-nationality-breakdown.csv',
                    sorted,
                    [
                      { header: 'Nationality', value: ([nat]) => nat },
                      { header: 'Count', value: ([, cnt]) => String(cnt) },
                      { header: 'Percent', value: ([, cnt]) => `${Math.round((cnt / total) * 100)}%` },
                    ],
                  )
                }
              >
                {sorted.map(([nat, cnt], i) => (
                  <Row key={nat}>
                    <div className="flex-1 text-[10.5px] font-extrabold text-navy">{nat}</div>
                    <BarRow pct={Math.round((cnt / total) * 100)} label={`${Math.round((cnt / total) * 100)}%`} color={colors[i % colors.length]} />
                  </Row>
                ))}
                {sorted.length === 0 && <div className="px-3 py-4 text-[10px] text-[#8090B0]">No data yet.</div>}
              </TableCard>
            );
          })()}

          {(() => {
            // Active nannies by city
            const approved = nannies.filter((n) => n.status === 'approved');
            const byCityCounts: Record<string, number> = {};
            approved.forEach((n) => { byCityCounts[n.city] = (byCityCounts[n.city] ?? 0) + 1; });
            const sorted = Object.entries(byCityCounts).sort((a, b) => b[1] - a[1]).slice(0, 4);
            const max = Math.max(...sorted.map((e) => e[1]), 1);
            const colors = ['#FF5C8A', '#9B6EDB', '#0EA5A0', muted];
            return (
              <TableCard
                title="Active nannies by city"
                action="Export"
                onAction={() =>
                  exportCsv('active-nannies-by-city.csv', sorted, [
                    { header: 'City', value: ([city]) => city },
                    { header: 'Active nannies', value: ([, cnt]) => String(cnt) },
                  ])
                }
              >
                {sorted.map(([city, cnt], i) => (
                  <Row key={city}>
                    <div className="flex-1 text-[10.5px] font-extrabold text-navy">{city}</div>
                    <BarRow pct={Math.round((cnt / max) * 100)} label={String(cnt)} color={colors[i % colors.length]} />
                  </Row>
                ))}
                {sorted.length === 0 && <div className="px-3 py-4 text-[10px] text-[#8090B0]">No data yet.</div>}
              </TableCard>
            );
          })()}
        </div>

        {/* Families */}
        <div className="flex-1 px-[18px] pb-[18px]">
          <div className="flex items-center gap-1.5 mb-0.5">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#9B6EDB" strokeWidth="2.5" strokeLinecap="round">
              <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
            </svg>
            <h2 className="text-[13px] font-black text-navy">Families</h2>
            <span className="text-[10px] font-bold text-white bg-purple px-2 py-0.5 rounded-full ml-1">{loading ? '—' : `${families.length} total`}</span>
          </div>
          <p className="text-[9px] font-semibold text-[#8090B0] mb-2.5">Manage family accounts, subscriptions & billing</p>

          <div className="flex gap-1.5 mb-2.5">
            <ColStat num={loading ? '—' : String(subscribedCount)} label="Subscribed" change="" />
            <ColStat num={loading ? '—' : String(freeCount)} label="Free users" change="Convert" numColor={muted} />
            <ColStat num={loading ? '—' : String(newTodayCount)} label="New today" change="" numColor="#9B6EDB" />
          </div>

          <TableCard title="Recent family accounts" action="View all" actionTo="/families">
            {loading && <div className="px-3 py-4 text-[10px] text-[#8090B0]">Loading…</div>}
            {families.slice(0, 5).map((f) => {
              const isActive = f.subscription.status === 'active';
              const variant = isActive ? 'sub' : f.subscription.status === 'free' ? 'unsub' : 'pending';
              const sub = [f.nationality, f.city, f.subscription.plan ? `${f.subscription.plan} plan` : null].filter(Boolean).join(' · ');
              return (
                <Row key={f.id}>
                  <Avatar letter={initials(f.fullName)} gradient={gradientFor(f.id)} />
                  <div className="flex-1 min-w-0">
                    <div className="text-[10.5px] font-extrabold text-navy">{f.fullName}</div>
                    <div className="text-[8.5px] font-semibold text-[#8090B0] truncate">{sub}</div>
                  </div>
                  <StatusBadge variant={variant}>{f.subscription.status}</StatusBadge>
                </Row>
              );
            })}
            {!loading && families.length === 0 && (
              <div className="px-3 py-4 text-[10px] text-[#8090B0]">No families yet.</div>
            )}
          </TableCard>

          {(() => {
            const planCounts: Record<string, number> = { weekly: 0, monthly: 0, twoMonths: 0 };
            let freeCount2 = 0;
            families.forEach((f) => {
              if (f.subscription.status !== 'active') { freeCount2++; return; }
              const p = f.subscription.plan ?? 'monthly';
              planCounts[p] = (planCounts[p] ?? 0) + 1;
            });
            const max = Math.max(...Object.values(planCounts), freeCount2, 1);
            return (
              <TableCard
                title="Subscription breakdown"
                action="Export CSV"
                onAction={() =>
                  exportCsv(
                    'subscription-breakdown.csv',
                    [
                      { plan: 'Weekly', subs: planCounts.weekly ?? 0 },
                      { plan: 'Monthly', subs: planCounts.monthly ?? 0 },
                      { plan: '2-months', subs: planCounts.twoMonths ?? 0 },
                      { plan: 'Not subscribed', subs: freeCount2 },
                    ],
                    [
                      { header: 'Plan', value: (r) => r.plan },
                      { header: 'Count', value: (r) => String(r.subs) },
                    ],
                  )
                }
              >
                <Row><div className="flex-1 text-[10.5px] font-extrabold text-navy">Weekly · AED 89/wk</div><BarRow pct={Math.round(((planCounts.weekly ?? 0) / max) * 100)} label={`${planCounts.weekly ?? 0} subs`} color="#FFB347" /></Row>
                <Row><div className="flex-1 text-[10.5px] font-extrabold text-navy">Monthly · AED 239/mo</div><BarRow pct={Math.round(((planCounts.monthly ?? 0) / max) * 100)} label={`${planCounts.monthly ?? 0} subs`} color="#9B6EDB" /></Row>
                <Row><div className="flex-1 text-[10.5px] font-extrabold text-navy">2-months · AED 369</div><BarRow pct={Math.round(((planCounts.twoMonths ?? 0) / max) * 100)} label={`${planCounts.twoMonths ?? 0} subs`} color="#6DBF8A" /></Row>
                <Row highlight>
                  <div className="flex-1 text-[10.5px] font-extrabold text-[#8090B0]">Not subscribed</div>
                  <BarRow pct={Math.round((freeCount2 / max) * 100)} label={`${freeCount2} users`} color="#FFD8E8" />
                </Row>
              </TableCard>
            );
          })()}

          {(() => {
            const counts2: Record<string, number> = {};
            families.forEach((f) => { counts2[f.nationality] = (counts2[f.nationality] ?? 0) + 1; });
            const sorted2 = Object.entries(counts2).sort((a, b) => b[1] - a[1]).slice(0, 4);
            const total2 = families.length || 1;
            const colors2 = ['#9B6EDB', '#0EA5A0', '#FF8FAB', '#FFB347'];
            return (
              <TableCard
                title="Family nationality breakdown"
                action="Export"
                onAction={() =>
                  exportCsv('family-nationality-breakdown.csv', sorted2, [
                    { header: 'Nationality', value: ([nat]) => nat },
                    { header: 'Count', value: ([, cnt]) => String(cnt) },
                    { header: 'Percent', value: ([, cnt]) => `${Math.round((cnt / total2) * 100)}%` },
                  ])
                }
              >
                {sorted2.map(([nat, cnt], i) => (
                  <Row key={nat}>
                    <div className="flex-1 text-[10.5px] font-extrabold text-navy">{nat}</div>
                    <BarRow pct={Math.round((cnt / total2) * 100)} label={`${Math.round((cnt / total2) * 100)}%`} color={colors2[i % colors2.length]} />
                  </Row>
                ))}
                {sorted2.length === 0 && <div className="px-3 py-4 text-[10px] text-[#8090B0]">No data yet.</div>}
              </TableCard>
            );
          })()}

          <TableCard title="🤝 Active trials" action="Monitor all" actionTo="/trials">
            {loading && <div className="px-3 py-4 text-[10px] text-[#8090B0]">Loading…</div>}
            {activeTrials.map((t) => {
              const dayNum = Math.max(1, Math.ceil((Date.now() - t.startDate.getTime()) / 86400000));
              const msLeft = t.endDate.getTime() - Date.now();
              const dLeft = Math.max(0, Math.floor(msLeft / 86400000));
              const hLeft = Math.max(0, Math.floor((msLeft % 86400000) / 3600000));
              const label = `${t.nannyName ?? t.nannyId} ↔ ${t.familyName ?? t.familyId}`;
              const sub = `${t.durationDays}-day trial · Day ${dayNum}/${t.durationDays}${t.location ? ` · ${t.location}` : ''}`;
              return (
                <Row key={t.id}>
                  <Avatar letter={initials(t.nannyName ?? 'N')} gradient={gradientFor(t.id)} />
                  <div className="flex-1 min-w-0">
                    <div className="text-[10.5px] font-extrabold text-navy">{label}</div>
                    <div className="text-[8.5px] font-semibold text-[#8090B0]">{sub}</div>
                  </div>
                  <div className="flex flex-col items-end">
                    <StatusBadge variant="active">{t.status}</StatusBadge>
                    <span className="text-[8px] font-bold text-green-dark mt-0.5">{dLeft}d {hLeft}h left</span>
                  </div>
                </Row>
              );
            })}
            {!loading && activeTrials.length === 0 && (
              <div className="px-3 py-4 text-[10px] text-[#8090B0]">No active trials.</div>
            )}
          </TableCard>
        </div>
      </div>
    </div>
  );
}
