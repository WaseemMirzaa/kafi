---
slug: kafi-listing-filters
project: Nannies app (Kafi admin)
title: Separate nationality / city / status dropdown filters on nannies and families listings
owner: architect
status: READY_FOR_BUILD
updated: 2026-06-07
---

# Plan: kafi-listing-filters

## 0. Source read (done before planning)

Read in full before writing this plan:
- `admin-panel/src/components/ui/ListControls.tsx` — `FilterBar`, `FilterSelect`, `Pagination`.
- `admin-panel/src/hooks/useListControls.ts` — `useListControls<T>` (search + date + `extraFilter` + pagination).
- `admin-panel/src/pages/nannies/AllNannies.tsx` — already on `FilterBar`/`useListControls` with a single Status `FilterSelect` and `extraFilter`.
- `admin-panel/src/pages/nannies/VerifyDocuments.tsx` — same pattern, single Document-status `FilterSelect`.
- `admin-panel/src/pages/families/AllFamilies.tsx` — NOT on `FilterBar`; lone header `<input type="search">` + local `useMemo` filter; no pagination, no date filter.
- `admin-panel/src/services/firestore.ts` — `NannyRow` and `FamilyRow` shapes. Confirmed: `NannyRow.nationality: string`, `NannyRow.city: string`, `NannyRow.createdAt?: Date`; `FamilyRow.nationality: string`, `FamilyRow.city: string`, `FamilyRow.createdAt?: Date`, `FamilyRow.subscription.status: 'free' | 'active' | 'cancelled' | 'expired' | 'paymentFailed'`.
- `admin-panel/src/utils/csv.ts` — `exportCsv(filename, rows, cols)`; pages already export `lc.filtered` (nannies) / `filtered` (families).

Verdict on existing practice: **sound**. The listing pages share `FilterBar` + `useListControls` cleanly; `extraFilter` is the designed extension point for dropdowns; CSV exports the filtered set. No refactor needed. AllFamilies is simply the one page that predates the shared pattern — migrating it *to* the pattern is the right move (the scope already calls for this), not a refactor risk. **No scope risk to escalate.**

---

## 1. Architecture summary

All filtering stays client-side over the already-loaded rows, consistent with the current pattern. Each new dropdown is page-local React state (`useState<string>` defaulting to `'all'`), folded into the page's existing/`new` `extraFilter` predicate passed to `useListControls`. The dropdowns render as `FilterSelect` children inside `FilterBar`, exactly like the existing Status dropdown. AND semantics are automatic: `useListControls` already ANDs `search`, `extraFilter`, and date range, and combining multiple dropdown conditions inside the single `extraFilter` with `&&` keeps every dropdown AND-ed with the others.

Dropdown options are derived from the loaded rows via one new pure helper, `distinctOptions`, added to the shared `ListControls.tsx`. It returns `{ value, label }[]` with an "All …" entry first followed by distinct non-empty values sorted alphabetically (locale-aware, case-insensitive). This avoids hardcoded nationality/city lists and avoids duplicating the distinct-and-sort logic across three pages.

Data flow per page:
```
rows (state) ──► distinctOptions(rows, accessor, allLabel) ──► FilterSelect options
rows + dropdown state ──► extraFilter ──► useListControls ──► filtered ──► table + CSV
```

New module boundary: none. One helper added to an existing shared file; pages keep their current structure.

---

## 2. Reuse map

Reuse — do **not** create new equivalents:
- `FilterBar`, `FilterSelect`, `Pagination` from `components/ui/ListControls.tsx` — the only filter UI primitives; pass dropdowns as `FilterBar` children.
- `useListControls` from `hooks/useListControls.ts` — search/date/`extraFilter`/pagination. `extraFilter` is the designed hook for dropdown predicates; do not add filtering logic outside it.
- `exportCsv` + existing column arrays — unchanged; keep exporting the filtered set.
- `PageShell`, `PageHeader`, `PageContent`, `TableCard`, `Row`, `Avatar`, `ColStat`, `StatusBadge` from `components/ui/AdminUI` — already used; reuse as-is for AllFamilies migration.

Design tokens / styling (no new visual patterns):
- `FilterSelect` already carries the project's input styling (`inputCls`: `admin-card text-[10px] font-semibold text-navy px-2.5 py-2 border-[#EBEEF8] focus:ring-rose-dark/30`, label `text-[8px] font-bold text-[#8090B0] uppercase tracking-wide`). New dropdowns MUST be rendered through `FilterSelect` only — no inline `<select>`, no one-off classes.
- AllFamilies' search moves from the bespoke header `<input>` into `FilterBar`'s built-in search; the bespoke header input is removed (its styling is replaced by `FilterBar`'s, which is the canonical pattern).
- Empty-state, loading, and `Pagination` styling come from the existing components; reuse the exact class strings already present in the nanny pages.

---

## 3. File-by-file change list

### WU1 — Nanny screens + shared helper

#### `admin-panel/src/components/ui/ListControls.tsx` — MODIFY
Add one exported pure helper (no other changes to this file):

```ts
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
```
- Edge cases: empty `rows` → returns just the "all" entry (dropdown still renders, only "All …"). Whitespace/empty values excluded. Returned `value`s are the raw row values, so equality checks against `n.nationality` / `n.city` are exact.
- No `any`. Generic `T`. Pure (no side effects).

#### `admin-panel/src/pages/nannies/AllNannies.tsx` — MODIFY
- Import `distinctOptions` alongside the existing `FilterBar, FilterSelect, Pagination` import from `ListControls`.
- Add two state hooks next to `const [status, setStatus] = useState('all')`:
  ```ts
  const [nationality, setNationality] = useState('all');
  const [city, setCity] = useState('all');
  ```
- Derive options from `items` (memoized) just before the return / after `stats`:
  ```ts
  const nationalityOptions = useMemo(
    () => distinctOptions(items, (n) => n.nationality, 'All nationalities'),
    [items],
  );
  const cityOptions = useMemo(
    () => distinctOptions(items, (n) => n.city, 'All cities'),
    [items],
  );
  ```
- Extend `extraFilter` to AND all three dropdowns and update its deps:
  ```ts
  const extraFilter = useMemo(
    () => (n: NannyRow) =>
      (status === 'all' || n.status === status) &&
      (nationality === 'all' || n.nationality === nationality) &&
      (city === 'all' || n.city === city),
    [status, nationality, city],
  );
  ```
- In `FilterBar`'s `onClear`, also reset the new dropdowns:
  ```ts
  onClear={() => { lc.clear(); setStatus('all'); setNationality('all'); setCity('all'); }}
  ```
- Add two `FilterSelect` children inside `FilterBar`, after the existing Status select (order: Status, Nationality, City):
  ```tsx
  <FilterSelect label="Nationality" value={nationality} onChange={setNationality} options={nationalityOptions} />
  <FilterSelect label="City" value={city} onChange={setCity} options={cityOptions} />
  ```
- Leave CSV export, stats, `toggleBlock`, row rendering, pagination, and navigation untouched. CSV continues to read `lc.filtered`, so it already reflects the new dropdowns.
- Edge case: `FilterBar`'s `Clear` button only shows when `query || from || to` is dirty (see `FilterBar.dirty`). This is unchanged existing behavior — dropdown-only selections do not surface a Clear button. Do NOT modify `FilterBar` to change this; it is out of scope and consistent with how the existing Status dropdown already behaves.

#### `admin-panel/src/pages/nannies/VerifyDocuments.tsx` — MODIFY
- Import `distinctOptions` alongside the existing `ListControls` import.
- Add state next to `const [docStatus, setDocStatus] = useState('all')`:
  ```ts
  const [nationality, setNationality] = useState('all');
  const [city, setCity] = useState('all');
  ```
- Derive options from `items` (memoized):
  ```ts
  const nationalityOptions = useMemo(
    () => distinctOptions(items, (n) => n.nationality, 'All nationalities'),
    [items],
  );
  const cityOptions = useMemo(
    () => distinctOptions(items, (n) => n.city, 'All cities'),
    [items],
  );
  ```
- Extend `extraFilter` (currently checks `docStatus`) and its deps:
  ```ts
  const extraFilter = useMemo(
    () => (n: NannyRow) =>
      (docStatus === 'all' || (n.documents ?? []).some((d) => d.status === docStatus)) &&
      (nationality === 'all' || n.nationality === nationality) &&
      (city === 'all' || n.city === city),
    [docStatus, nationality, city],
  );
  ```
- Extend `onClear`: `lc.clear(); setDocStatus('all'); setNationality('all'); setCity('all');`
- Add the two `FilterSelect` children after the existing Document-status select (order: Document status, Nationality, City), identical markup to AllNannies.
- Leave the documents popup, approve/reject flows, stats, and pagination untouched. No CSV export on this page — nothing to change there.

### WU2 — Families screen (migration)

#### `admin-panel/src/pages/families/AllFamilies.tsx` — MODIFY (migrate to FilterBar/useListControls)
- Update imports:
  - Add `FilterBar, FilterSelect, Pagination, distinctOptions` from `../../components/ui/ListControls`.
  - Add `useListControls` from `../../hooks/useListControls`.
  - Keep existing `useEffect, useMemo, useState`, AdminUI imports, `FamilyService, FamilyRow`, avatar utils, `exportCsv`.
- Remove the lone `const [search, setSearch] = useState('')` and the local `filtered` `useMemo` (lines ~36 and ~59–65).
- Add dropdown state:
  ```ts
  const [nationality, setNationality] = useState('all');
  const [city, setCity] = useState('all');
  const [subStatus, setSubStatus] = useState('all');
  ```
- Add a module-level constant for subscription statuses (mirrors the `STATUSES` pattern in AllNannies), placed near the existing `statusVariant`/`statusLabel` maps. Reuse the existing `statusLabel` map for the dropdown option labels so the labels match the badge labels:
  ```ts
  const SUB_STATUSES: FamilyRow['subscription']['status'][] =
    ['free', 'active', 'cancelled', 'expired', 'paymentFailed'];
  ```
- Build the `extraFilter` and wire `useListControls`:
  ```ts
  const extraFilter = useMemo(
    () => (f: FamilyRow) =>
      (nationality === 'all' || f.nationality === nationality) &&
      (city === 'all' || f.city === city) &&
      (subStatus === 'all' || f.subscription.status === subStatus),
    [nationality, city, subStatus],
  );

  const lc = useListControls(items, {
    search: (f, q) => [f.fullName, f.nationality, f.city].some((s) => s?.toLowerCase().includes(q)),
    getDate: (f) => f.createdAt,
    extraFilter,
    pageSize: 8,
  });
  ```
  Rationale for date wiring: `FamilyRow.createdAt?: Date` exists, so wire it with `dateLabel="Joined"`. Resolves the scope's open question — wire it, do not omit. Rows without `createdAt` are simply excluded when a date bound is set (existing `useListControls` behavior), which is acceptable.
- Derive options from `items` (memoized):
  ```ts
  const nationalityOptions = useMemo(() => distinctOptions(items, (f) => f.nationality, 'All nationalities'), [items]);
  const cityOptions = useMemo(() => distinctOptions(items, (f) => f.city, 'All cities'), [items]);
  ```
  Subscription-status options are a fixed union, so build them from `SUB_STATUSES` + `statusLabel` (NOT `distinctOptions`, since the label differs from the value):
  ```ts
  const subStatusOptions = [
    { value: 'all', label: 'All subscriptions' },
    ...SUB_STATUSES.map((s) => ({ value: s, label: statusLabel[s] ?? s })),
  ];
  ```
- Stats (`subscribed`, `free`, `expired`) keep computing from `items` (totals over all rows, unchanged) — do not switch them to filtered.
- `PageHeader`: remove the bespoke `<input type="search">` from `actions`. `actions` becomes just the `Export CSV` button (keep the surrounding fragment or simplify to the single button). The search now lives in `FilterBar`.
- Insert a `FilterBar` between the stats row and the `TableCard` (mirroring AllNannies placement):
  ```tsx
  <FilterBar
    query={lc.query} setQuery={lc.setQuery}
    from={lc.from} setFrom={lc.setFrom} to={lc.to} setTo={lc.setTo}
    onClear={() => { lc.clear(); setNationality('all'); setCity('all'); setSubStatus('all'); }}
    searchPlaceholder="Search by name, nationality, city…"
    dateLabel="Joined"
  >
    <FilterSelect label="Subscription" value={subStatus} onChange={setSubStatus} options={subStatusOptions} />
    <FilterSelect label="Nationality" value={nationality} onChange={setNationality} options={nationalityOptions} />
    <FilterSelect label="City" value={city} onChange={setCity} options={cityOptions} />
  </FilterBar>
  ```
- Table body: replace `filtered` with `lc.pageItems` in the `.map(...)`, and the empty-state condition with `!loading && lc.total === 0` (message: `No families match your filters.`). Row rendering, block/unblock, `StatusBadge`, trial badge, and `View →` link stay identical.
- Add `<Pagination>` inside `TableCard` after the rows (AllFamilies currently has none — this is a behavior improvement that comes free with the pattern and matches the other listing pages):
  ```tsx
  <Pagination page={lc.page} pageCount={lc.pageCount} rangeStart={lc.rangeStart} rangeEnd={lc.rangeEnd} total={lc.total} onPage={lc.setPage} />
  ```
- CSV export: change `exportCsv('families.csv', filtered, ...)` to use `lc.filtered`. Columns unchanged.
- Edge cases: empty list → dropdowns show only "All …"; `subscription.status` is non-optional so no guard needed; `createdAt` optional handled by `useListControls`.

---

## 4. Work units & parallelization

| WU | Files (write set) | Mode |
| -- | ----------------- | ---- |
| **WU1** | `components/ui/ListControls.tsx`, `pages/nannies/AllNannies.tsx`, `pages/nannies/VerifyDocuments.tsx` | **INDEPENDENT** |
| **WU2** | `pages/families/AllFamilies.tsx` | **INDEPENDENT** |

- File write-sets are disjoint → both can build in parallel in separate worktrees with no merge collisions.
- The shared `distinctOptions` helper is **created and owned by WU1** (lives in `ListControls.tsx`, WU1's write set). **WU2 only imports it** (read-only dependency, no edit to that file), so there is still zero write-overlap.
- Soft ordering note for the orchestrator: because WU2 imports `distinctOptions` from `ListControls.tsx`, WU2's `npm run build` will fail to typecheck only if it runs against a tree where WU1 hasn't added the export yet. Each WU builds in its own worktree branched from the same base; if WU2's worktree does not contain WU1's commit, WU2 should add the same `distinctOptions` export is NOT permitted (would create a duplicate/conflict). Instead: merge WU1 first, then WU2, OR base WU2's worktree on WU1. Mark this as **WU2 verify-depends-on WU1** for the final typecheck/merge step only — the code authoring is independent.

---

## 5. Refactor callouts

None required. AllFamilies' migration to `FilterBar`/`useListControls` is in-scope feature work, not a remediation. No competing patterns introduced.

---

## 6. Test plan

This project has no automated test setup; verification is `npm run build` (tsc + vite) plus manual flows. Review will exercise:

1. **Build:** `cd admin-panel && npm run build` passes — no TS errors, no `any`, no new deps.
2. **All nannies:** Nationality and City dropdowns appear after Status; each defaults to "All …" and lists distinct sorted values from loaded nannies. Selecting Nationality=Filipino AND City=Dubai narrows the list to rows matching both (AND with search + date range too). Clear (when search/date dirty) resets dropdowns. CSV export downloads exactly the filtered rows. Stats cards, block/unblock, pagination, `View →` unchanged.
3. **Verify documents:** Same two dropdowns after Document status; AND semantics across all filters; documents popup, approve/reject, "All caught up" empty state all still work.
4. **All families:** No bespoke header search input remains; `FilterBar` present with search + Joined date + Subscription/Nationality/City dropdowns. Subscription dropdown labels match the badge labels (`statusLabel`). Search still matches name/nationality/city. Pagination renders. Empty filter result shows "No families match your filters." CSV exports filtered rows. Block/unblock, trial badge, stats unchanged.
5. **Derived options:** No hardcoded nationality/city arrays anywhere; options reflect loaded data; empty data → only "All …".

---

## 7. Definition of done

- [ ] `distinctOptions` added to `ListControls.tsx`: generic, pure, "All" first, distinct + locale-sorted, skips empty values, no `any`.
- [ ] AllNannies: Nationality + City `FilterSelect`s next to Status; options from `distinctOptions(items, …)`; `extraFilter` ANDs status+nationality+city with correct deps; `onClear` resets all three; CSV reads `lc.filtered` (unchanged).
- [ ] VerifyDocuments: same Nationality + City dropdowns wired into existing `FilterBar`/`extraFilter`; `onClear` resets all; popup/approve/reject untouched.
- [ ] AllFamilies: migrated to `FilterBar` + `useListControls`; bespoke header search removed; Subscription (labeled via `statusLabel`) + Nationality + City dropdowns; `getDate: f => f.createdAt` with `dateLabel="Joined"`; `Pagination` added; table uses `lc.pageItems`; empty state "No families match your filters."; CSV exports `lc.filtered`; stats/block/trial/View unchanged.
- [ ] All dropdowns single-select, default "All …", AND semantics, options derived from data (no hardcoded nationality/city lists).
- [ ] Only `FilterSelect`/`FilterBar` used for UI — no inline `<select>`, no one-off styles; matches existing design tokens.
- [ ] `cd admin-panel && npm run build` passes; no new dependencies; no `any`.
