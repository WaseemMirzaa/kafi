/** Distinct, alphabetically-sorted dropdown options derived from rows.
 *  Prepends an "all" entry. Skips empty/undefined accessor values. */
export function distinctOptions<T>(
  rows: T[],
  accessor: (row: T) => string | undefined | null,
  allLabel: string,
): { value: string; label: string }[] {
  const seen = new Set<string>();
  for (const r of rows) {
    const v = accessor(r);
    if (v != null && v.trim() !== '') seen.add(v);
  }
  const sorted = [...seen].sort((a, b) =>
    a.localeCompare(b, undefined, { sensitivity: 'base' }),
  );
  return [{ value: 'all', label: allLabel }, ...sorted.map((v) => ({ value: v, label: v }))];
}

const inputCls =
  'admin-card text-[10px] font-semibold text-navy px-2.5 py-2 border-[#EBEEF8] focus:outline-none focus:ring-1 focus:ring-rose-dark/30';

/** Search box + date-range filter row used across listing pages.
 *  Pass extra controls (e.g. a status dropdown) as children. */
export function FilterBar({
  query,
  setQuery,
  from,
  setFrom,
  to,
  setTo,
  onClear,
  searchPlaceholder = 'Search…',
  dateLabel = 'Submitted',
  children,
}: {
  query: string;
  setQuery: (v: string) => void;
  from: string;
  setFrom: (v: string) => void;
  to: string;
  setTo: (v: string) => void;
  onClear: () => void;
  searchPlaceholder?: string;
  dateLabel?: string;
  children?: React.ReactNode;
}) {
  const dirty = !!(query || from || to);
  return (
    <div className="admin-card p-2.5 mb-2.5 flex flex-wrap items-end gap-2">
      <div className="flex flex-col gap-1 flex-1 min-w-[160px]">
        <label className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide">Search</label>
        <input
          type="search"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder={searchPlaceholder}
          className={`${inputCls} w-full`}
        />
      </div>
      <div className="flex flex-col gap-1">
        <label className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide">{dateLabel} from</label>
        <input type="date" value={from} onChange={(e) => setFrom(e.target.value)} className={inputCls} />
      </div>
      <div className="flex flex-col gap-1">
        <label className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide">{dateLabel} to</label>
        <input type="date" value={to} onChange={(e) => setTo(e.target.value)} className={inputCls} />
      </div>
      {children}
      {dirty && (
        <button type="button" className="qa-btn qa-n" onClick={onClear}>
          Clear
        </button>
      )}
    </div>
  );
}

/** Simple labeled select for inline filters (e.g. status). */
export function FilterSelect({
  label,
  value,
  onChange,
  options,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  options: { value: string; label: string }[];
}) {
  return (
    <div className="flex flex-col gap-1">
      <label className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide">{label}</label>
      <select value={value} onChange={(e) => onChange(e.target.value)} className={`${inputCls} pr-6`}>
        {options.map((o) => (
          <option key={o.value} value={o.value}>
            {o.label}
          </option>
        ))}
      </select>
    </div>
  );
}

/** Pagination footer: result range + prev/next + numbered pages. */
export function Pagination({
  page,
  pageCount,
  rangeStart,
  rangeEnd,
  total,
  onPage,
}: {
  page: number;
  pageCount: number;
  rangeStart: number;
  rangeEnd: number;
  total: number;
  onPage: (p: number) => void;
}) {
  if (total === 0) return null;
  // Compact window of page numbers around the current page.
  const pages: number[] = [];
  const win = 2;
  for (let p = Math.max(1, page - win); p <= Math.min(pageCount, page + win); p++) pages.push(p);

  const btn =
    'text-[9px] font-bold px-2 py-1 rounded-md border border-[#EBEEF8] disabled:opacity-40 disabled:cursor-not-allowed hover:bg-[#F8F9FD]';

  return (
    <div className="flex items-center justify-between gap-2 px-[11px] py-2 border-t border-[#EBEEF8]">
      <div className="text-[8.5px] font-semibold text-[#8090B0]">
        {rangeStart}–{rangeEnd} of {total}
      </div>
      <div className="flex items-center gap-1">
        <button type="button" className={btn} onClick={() => onPage(page - 1)} disabled={page <= 1}>
          ←
        </button>
        {pages[0] > 1 && <span className="text-[9px] text-[#A0ADC8]">…</span>}
        {pages.map((p) => (
          <button
            key={p}
            type="button"
            onClick={() => onPage(p)}
            className={`text-[9px] font-bold px-2 py-1 rounded-md border ${
              p === page ? 'border-rose-dark bg-rose-pale text-rose-dark' : 'border-[#EBEEF8] text-navy hover:bg-[#F8F9FD]'
            }`}
          >
            {p}
          </button>
        ))}
        {pages[pages.length - 1] < pageCount && <span className="text-[9px] text-[#A0ADC8]">…</span>}
        <button type="button" className={btn} onClick={() => onPage(page + 1)} disabled={page >= pageCount}>
          →
        </button>
      </div>
    </div>
  );
}
