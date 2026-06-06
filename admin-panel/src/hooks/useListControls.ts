import { useEffect, useMemo, useState } from 'react';

export interface ListControlsOptions<T> {
  /** Predicate for the search box. Receives the lowercased query. */
  search: (item: T, q: string) => boolean;
  /** Date accessor for the date-range filter (optional). */
  getDate?: (item: T) => Date | undefined;
  /** Extra predicate (e.g. a status dropdown) controlled by the page. */
  extraFilter?: (item: T) => boolean;
  pageSize?: number;
}

/** Shared search + date-range + pagination logic for listing pages. */
export function useListControls<T>(items: T[], opts: ListControlsOptions<T>) {
  const { search, getDate, extraFilter, pageSize = 8 } = opts;
  const [query, setQuery] = useState('');
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');
  const [page, setPage] = useState(1);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    const fromT = from ? new Date(from).getTime() : null;
    // include the whole "to" day
    const toT = to ? new Date(to).getTime() + 86400000 - 1 : null;
    return items.filter((it) => {
      if (q && !search(it, q)) return false;
      if (extraFilter && !extraFilter(it)) return false;
      if (getDate && (fromT != null || toT != null)) {
        const d = getDate(it);
        const t = d ? d.getTime() : null;
        if (fromT != null && (t == null || t < fromT)) return false;
        if (toT != null && (t == null || t > toT)) return false;
      }
      return true;
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [items, query, from, to, extraFilter, search, getDate]);

  const pageCount = Math.max(1, Math.ceil(filtered.length / pageSize));

  // Snap back to a valid page whenever filters shrink the result set.
  useEffect(() => {
    if (page > pageCount) setPage(1);
  }, [pageCount, page]);

  const start = (page - 1) * pageSize;
  const pageItems = filtered.slice(start, start + pageSize);

  const clear = () => {
    setQuery('');
    setFrom('');
    setTo('');
    setPage(1);
  };

  return {
    query,
    setQuery,
    from,
    setFrom,
    to,
    setTo,
    page,
    setPage,
    pageSize,
    filtered,
    pageItems,
    pageCount,
    total: filtered.length,
    rangeStart: filtered.length === 0 ? 0 : start + 1,
    rangeEnd: Math.min(start + pageSize, filtered.length),
    clear,
  };
}
