import { Link } from 'react-router-dom';

const muted = '#8090B0';

export function PageShell({ children }: { children: React.ReactNode }) {
  return <div className="flex flex-col flex-1">{children}</div>;
}

export function PageHeader({
  title,
  subtitle,
  actions,
}: {
  title: string;
  subtitle?: string;
  actions?: React.ReactNode;
}) {
  return (
    <div className="flex flex-wrap justify-between items-start gap-2.5 px-[18px] pt-4 pb-0 mb-3">
      <div>
        <h1 className="text-base font-black text-navy">{title}</h1>
        {subtitle && <p className="text-[10px] font-semibold text-[#8090B0] mt-0.5">{subtitle}</p>}
      </div>
      {actions && <div className="flex flex-wrap gap-1.5">{actions}</div>}
    </div>
  );
}

export function PageContent({ children }: { children: React.ReactNode }) {
  return <div className="px-[18px] pb-[18px] flex-1">{children}</div>;
}

export function TopStat({ num, label, change, numClass = '' }: { num: string; label: string; change: string; numClass?: string }) {
  return (
    <div className="admin-card p-2.5">
      <div className={`text-[17px] font-black text-navy ${numClass}`}>{num}</div>
      <div className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide mt-0.5">{label}</div>
      <div className="text-[8px] font-bold mt-0.5 cs-up">{change}</div>
    </div>
  );
}

export function ColStat({ num, label, change, numColor }: { num: string; label: string; change: string; numColor?: string }) {
  return (
    <div className="admin-card flex-1 p-2 text-center">
      <div className="text-[15px] font-black text-navy" style={numColor ? { color: numColor } : undefined}>
        {num}
      </div>
      <div className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide mt-0.5">{label}</div>
      <div
        className="text-[8px] font-bold mt-0.5"
        style={{
          color: change.includes('⚠')
            ? '#FFB347'
            : change.includes('Convert')
              ? '#FFB347'
              : change.includes('Good') || change.includes('↑')
                ? '#2E9A58'
                : muted,
        }}
      >
        {change}
      </div>
    </div>
  );
}

export function StatusBadge({ children, variant }: { children: React.ReactNode; variant: string }) {
  const styles: Record<string, string> = {
    active: 'bg-[#E8F8EE] text-[#2A8A50]',
    pending: 'bg-amber-light text-[#A06010]',
    new: 'bg-purple-light text-purple',
    sub: 'bg-[#E8F8EE] text-[#2A8A50]',
    unsub: 'bg-rose-pale text-rose-dark',
    verify: 'bg-amber-light text-[#A06010]',
    verified: 'bg-[#E8F8EE] text-[#2A8A50]',
    rejected: 'bg-rose-pale text-rose-dark',
    free: 'bg-purple-light text-purple',
    expired: 'bg-rose-pale text-rose-dark',
  };
  return (
    <span className={`text-[8.5px] font-bold font-fredoka px-[7px] py-0.5 rounded-full ${styles[variant] ?? styles.pending}`}>
      {children}
    </span>
  );
}

export function Avatar({ letter, gradient }: { letter: string; gradient: string }) {
  return (
    <div
      className="w-[26px] h-[26px] rounded-lg flex items-center justify-center text-[11px] font-extrabold text-white flex-shrink-0"
      style={{ background: gradient }}
    >
      {letter}
    </div>
  );
}

export function TableCard({
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
  return (
    <div className="admin-table">
      <div className="flex items-center justify-between px-[11px] py-2 border-b border-[#EBEEF8]">
        <h4 className="text-[11px] font-extrabold text-navy">{title}</h4>
        {action && actionTo ? (
          <Link to={actionTo} className="text-[9.5px] font-bold text-purple font-fredoka no-underline">
            {action}
          </Link>
        ) : action && onAction ? (
          <button type="button" className="text-[9.5px] font-bold text-purple font-fredoka" onClick={onAction}>
            {action}
          </button>
        ) : null}
      </div>
      {children}
    </div>
  );
}

export function Row({ children, highlight }: { children: React.ReactNode; highlight?: boolean }) {
  return (
    <div
      className={`flex items-center gap-[7px] px-[11px] py-2 border-b border-[#F4F5FC] last:border-b-0 hover:bg-[#F8F9FD] transition-colors ${highlight ? 'bg-[#FFF5F8]' : ''}`}
    >
      {children}
    </div>
  );
}

export function BarRow({ pct, label, color }: { pct: number; label: string; color: string }) {
  return (
    <div className="flex items-center gap-1.5">
      <div className="w-[55px] h-1 bg-[#F0F1FA] rounded-sm overflow-hidden flex-shrink-0">
        <div className="h-full rounded-sm" style={{ width: `${pct}%`, background: color }} />
      </div>
      <span className="text-[10px] font-bold text-navy">{label}</span>
    </div>
  );
}

export function SectionTitle({ icon, title, badge, badgeClass, sub }: {
  icon: React.ReactNode;
  title: string;
  badge?: string;
  badgeClass?: string;
  sub?: string;
}) {
  return (
    <>
      <div className="flex items-center gap-1.5 mb-0.5">
        {icon}
        <h2 className="text-[13px] font-black text-navy">{title}</h2>
        {badge && (
          <span className={`text-[10px] font-bold text-white px-2 py-0.5 rounded-full ml-1 ${badgeClass ?? 'bg-rose-dark'}`}>
            {badge}
          </span>
        )}
      </div>
      {sub && <p className="text-[9px] font-semibold text-[#8090B0] mb-2.5">{sub}</p>}
    </>
  );
}

export function DetailCard({ children }: { children: React.ReactNode }) {
  return <div className="admin-card p-4">{children}</div>;
}

export function FieldGrid({ children }: { children: React.ReactNode }) {
  return <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 mt-4">{children}</div>;
}

export function Field({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <div className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide">{label}</div>
      <div className="text-[10.5px] font-extrabold text-navy mt-0.5">{value}</div>
    </div>
  );
}

export function QaLink({ to, variant, children }: { to: string; variant: 'r' | 'g' | 'p' | 'n'; children: React.ReactNode }) {
  return (
    <Link to={to} className={`qa-btn qa-${variant} no-underline`}>
      {children}
    </Link>
  );
}

