import { NavLink } from 'react-router-dom';
import clsx from 'clsx';
import { useAuthStore } from '../../hooks/useAuth';

type NavItem = {
  to: string;
  label: string;
  count?: number;
  icon: React.ReactNode;
};

const overview: NavItem[] = [
  {
    to: '/',
    label: 'Dashboard',
    icon: (
      <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
        <rect x="3" y="3" width="7" height="7" />
        <rect x="14" y="3" width="7" height="7" />
        <rect x="14" y="14" width="7" height="7" />
        <rect x="3" y="14" width="7" height="7" />
      </svg>
    ),
  },
];

const nannies: NavItem[] = [
  {
    to: '/nannies',
    label: 'All nannies',
    count: 142,
    icon: (
      <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
        <circle cx="12" cy="7" r="4" />
      </svg>
    ),
  },
  {
    to: '/nannies/verify',
    label: 'Verify docs',
    count: 8,
    icon: (
      <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
        <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
        <polyline points="22 4 12 14.01 9 11.01" />
      </svg>
    ),
  },
];

const families: NavItem[] = [
  {
    to: '/families',
    label: 'All families',
    count: 87,
    icon: (
      <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
        <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
      </svg>
    ),
  },
  {
    to: '/families/subscriptions',
    label: 'Subscriptions',
    count: 54,
    icon: (
      <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
        <rect x="1" y="4" width="22" height="16" rx="2" />
        <line x1="1" y1="10" x2="23" y2="10" />
      </svg>
    ),
  },
];

const operations: NavItem[] = [
  {
    to: '/trials',
    label: 'Active trials',
    count: 6,
    icon: (
      <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M3 12h4l2 5 4-12 2 7h6" />
      </svg>
    ),
  },
];

const safety: NavItem[] = [
  {
    to: '/disputes',
    label: 'Disputes',
    icon: (
      <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
        <path d="M12 9v4M12 17h.01" />
        <path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0Z" />
      </svg>
    ),
  },
];

const business: NavItem[] = [
  {
    to: '/revenue',
    label: 'Revenue',
    icon: (
      <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
        <line x1="12" y1="1" x2="12" y2="23" />
        <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" />
      </svg>
    ),
  },
  {
    to: '/broadcast',
    label: 'Broadcast',
    icon: (
      <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
        <circle cx="12" cy="12" r="10" />
        <path d="M8.56 2.75c4.37 6.03 6.02 9.42 8.03 17.72m2.54-15.38c-3.72 4.35-8.94 5.66-16.88 5.85m19.5 1.9c-3.5-.93-6.63-.82-8.94 0-2.58.92-5.01 2.86-7.44 6.32" />
      </svg>
    ),
  },
];

function NavSection({ label, items }: { label: string; items: NavItem[] }) {
  return (
    <>
      <p className="text-[8px] font-bold text-white/20 uppercase tracking-widest px-[13px] pt-2 pb-1 font-fredoka">
        {label}
      </p>
      {items.map((item) => (
        <NavLink
          key={item.to}
          to={item.to}
          end={item.to === '/'}
          className={({ isActive }) =>
            clsx(
              'flex items-center gap-[7px] py-2 px-[13px] border-r-[3px] transition-all font-fredoka',
              isActive
                ? 'bg-[rgba(255,143,171,0.14)] border-r-rose-dark text-rose'
                : 'border-r-transparent text-white/40 hover:bg-white/[0.04]',
            )
          }
        >
          {({ isActive }) => (
            <>
              <span className={clsx('flex-shrink-0', isActive ? 'opacity-100 text-rose' : 'opacity-[0.38]')}>
                {item.icon}
              </span>
              <span className={clsx('text-[10px] font-bold flex-1', isActive ? 'text-rose' : 'text-white/40')}>
                {item.label}
              </span>
              {item.count != null && (
                <span className="bg-rose-dark text-white text-[8px] font-bold px-[5px] py-0.5 rounded-full">
                  {item.count}
                </span>
              )}
            </>
          )}
        </NavLink>
      ))}
    </>
  );
}

export default function Sidebar() {
  const { user, logout } = useAuthStore();

  return (
    <aside className="w-[182px] flex-shrink-0 bg-navy flex flex-col py-3.5 h-screen sticky top-0 overflow-hidden">
      <div className="flex items-center gap-1.5 px-[13px] pb-3.5 mb-2.5 border-b border-white/[0.07]">
        <svg width="18" height="18" viewBox="0 0 34 34" aria-hidden>
          <ellipse cx="17" cy="9" rx="6" ry="10" fill="#FF8FAB" opacity="0.8" />
          <ellipse cx="17" cy="9" rx="6" ry="10" fill="#FF8FAB" opacity="0.7" transform="rotate(60 17 17)" />
          <ellipse cx="17" cy="9" rx="6" ry="10" fill="#FF8FAB" opacity="0.7" transform="rotate(120 17 17)" />
          <ellipse cx="17" cy="9" rx="6" ry="10" fill="#FF9BBB" opacity="0.8" transform="rotate(180 17 17)" />
          <ellipse cx="17" cy="9" rx="6" ry="10" fill="#FF9BBB" opacity="0.7" transform="rotate(240 17 17)" />
          <ellipse cx="17" cy="9" rx="6" ry="10" fill="#FF8FAB" opacity="0.7" transform="rotate(300 17 17)" />
          <circle cx="17" cy="17" r="7" fill="rgba(255,255,255,0.12)" />
          <circle cx="17" cy="17" r="4.5" fill="#FF8FAB" />
        </svg>
        <span className="font-pacifico text-[15px] text-[#FF8FAB]">Kafi</span>
        <span className="text-[8px] bg-rose-dark text-white px-1.5 py-0.5 rounded-full font-fredoka font-bold ml-auto">
          ADMIN
        </span>
      </div>

      <nav className="flex-1 overflow-hidden">
        <NavSection label="Overview" items={overview} />
        <NavSection label="Nannies" items={nannies} />
        <NavSection label="Families" items={families} />
        <NavSection label="Operations" items={operations} />
        <NavSection label="Safety" items={safety} />
        <NavSection label="Business" items={business} />
      </nav>

      <div className="px-[13px] pt-3 border-t border-white/[0.07] mt-2">
        {user && <p className="text-[9px] text-white/40 truncate mb-2">{user.email}</p>}
        <button
          type="button"
          onClick={logout}
          className="text-[10px] font-fredoka font-bold text-rose-light hover:text-white transition"
        >
          Log out
        </button>
        <p className="text-[10px] text-white/25 mt-3">© 2026 Kafi</p>
      </div>
    </aside>
  );
}
