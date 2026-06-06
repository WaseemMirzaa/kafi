---
slug: kafi-dashboard-revert-revenue-filters
project: kafi-admin-panel
title: Revert dashboard design (keep logic), add global period filters to Revenue page
owner: architect
status: READY_FOR_BUILD
updated: 2026-06-07
---

# Plan — kafi-dashboard-revert-revenue-filters

## 0. Read-before-plan confirmation

Source read prior to planning:
- `admin-panel/src/pages/Dashboard.tsx` (current HEAD d6c4423) and its `2bb67f8`
  (original) + `ee8a1e3` (live-data) versions via `git show`.
- `admin-panel/src/pages/business/Revenue.tsx`.
- `admin-panel/src/services/firestore.ts` lines 1370–1493 (RevenueService, types,
  `buildTrend`, mock data) and import block.
- `admin-panel/src/components/ui/ListControls.tsx`, `hooks/useListControls.ts`.
- Reference page using the primitives: `pages/trials/AllTrials.tsx`.
- `components/ui/AdminUI.tsx` StatusBadge variants.

WU0 (branch + the two baseline commits) is already done: HEAD is
`d6c4423 admin: WIP baseline — partial revert of dashboard revenue cards design`
on branch `feat/kafi-dashboard-revert-revenue-filters`, and `23cb82d` carries the
chat/dispute commit. No further WU0 action — the PM handles the PR at the end.

## 1. Architecture summary

Two independent slices, both staying inside the existing patterns:

- **WU1 (Dashboard.tsx only):** The current HEAD already restored the original
  4-card revenue-row *layout* (hardcoded). The remaining work is to feed that
  exact original layout with the live `byPlan`/`vat` values already returned by
  `RevenueService.summary()` (which Dashboard already calls). No layout/JSX
  structure changes beyond swapping hardcoded strings for live values. All other
  `ee8a1e3` logic (live fetch, computed "New today", TableCard `actionTo`,
  `onAction` CSV exports) is already present at HEAD and is preserved untouched.

- **WU2 (Revenue.tsx + firestore.ts):** Add ONE global `FilterBar` (reused
  primitive) with Weekly/Monthly/Yearly presets + custom from/to date range. The
  page fetches the full transaction history once via a new
  `RevenueService.allTransactions()` service method (replaces the 50-capped
  `recentTransactions()` for this page; the old method stays for any other
  caller). All four sections (stat cards, trend, Plan revenue split, Recent
  transactions) are **derived client-side** from the paid transactions that fall
  inside the selected range, using `useMemo`. The date filtering reuses the same
  inclusive-range semantics as `useListControls` but is applied to derived
  aggregates, so we compute the range bounds directly rather than paginating.

Data flow (WU2): `allTransactions()` → `txns` state → `useMemo` filters by
`from/to` → derived `{ statCards, trend, byPlan, recentRows }` → render. The
preset buttons set `from`/`to` to computed dates; the date inputs are the same
state, so presets and custom range share one source of truth (one global bar).

### Why a new service method instead of changing `recentTransactions()`
`recentTransactions()` is also called by `Dashboard`? — verified: it is **not**;
only `Revenue.tsx` calls it (`grep`). However the scope says keep it from
"silently truncating". Cleanest contained change: add `allTransactions()` that
returns the uncapped list (mock + live), and switch Revenue to it. Leaving
`recentTransactions()` in place avoids touching unrelated call sites and keeps the
diff minimal. (If a reviewer prefers deleting `recentTransactions()`, note that
no other caller exists, but the plan keeps it to stay minimal — do NOT delete.)

## 2. Reuse map (no new primitives, no one-off styling)

| Need | Reuse (do NOT recreate) |
| ---- | ----------------------- |
| Filter bar shell + search + date range | `FilterBar` from `components/ui/ListControls.tsx` |
| Preset dropdown (Weekly/Monthly/Yearly/Custom) | `FilterSelect` from same file, passed as `FilterBar` child |
| Page scaffold | `PageShell`, `PageHeader`, `PageContent`, `TableCard`, `Row`, `TopStat`, `BarRow`, `StatusBadge` from `AdminUI.tsx` (already imported in Revenue.tsx) |
| CSV export | `exportCsv` from `utils/csv.ts` (already imported) |
| Revenue card (Dashboard) | existing `RevCard` component in `Dashboard.tsx` (already present, unchanged) |
| Plan colors / muted / borders | existing token hexes: weekly `#FFB347`, monthly `#9B6EDB`, twoMonths `#2E9A58`, rose `#FF8FAB`, muted `#8090B0` |
| Firestore query helpers | `collection/query/where/orderBy/getDocs/Timestamp` already imported in `firestore.ts`; `parseTimestamp`, `useMock()` |

Design tokens for WU2 filter bar come entirely from `FilterBar`/`FilterSelect` —
no inline styling. Stat cards keep existing `TopStat` styling.

## 3. File-by-file change list

### WU1 — `admin-panel/src/pages/Dashboard.tsx`  (MODIFY)

Goal: original revenue-row layout, live values. Keep everything else as-is.

1. **Add `byPlan` to state and load it** (mirrors `ee8a1e3`):
   - Add state: `const [byPlan, setByPlan] = useState<{ plan: string; subs: number; revenue: number }[]>([]);`
     Place it next to `monthlyRevenue`/`monthlyVat` state (around line 158).
   - In `load()`, the `Promise.all` already destructures `rev` from
     `RevenueService.summary()`. After `setMonthlyVat(rev.vat);` add
     `setByPlan(rev.byPlan);` (around line 178).
2. **Replace the hardcoded Revenue row (current lines 277–283)** with live-mapped
   `RevCard`s, keeping the SAME `RevCard` component, the SAME wrapping
   `div className="grid grid-cols-2 lg:grid-cols-4 gap-2 px-[18px] pb-3"`, and the
   SAME 3-plan + VAT card order/labels/colors/`borderRose`. Map values from
   `byPlan`/`monthlyVat`:
   - Define inside the JSX (IIFE pattern already used elsewhere in this file):
     ```
     const planMeta = {
       weekly:    { label: 'Weekly · AED 89',   color: '#FFB347' },
       monthly:   { label: 'Monthly · AED 239', color: '#9B6EDB' },
       twoMonths: { label: '2 months · AED 369', color: '#2E9A58' },
     } as const;
     const maxRevenue = Math.max(...byPlan.map((p) => p.revenue), 1);
     const planOf = (key: string) => byPlan.find((p) => p.plan === key);
     ```
   - Render the three plan cards by iterating `Object.entries(planMeta)`:
     `amount = loading ? '—' : 'AED ' + (p?.revenue ?? 0).toLocaleString()`,
     `sub = loading ? '' : (p?.subs ?? 0) + ' active'`,
     `pct = Math.round(((p?.revenue ?? 0) / maxRevenue) * 100)`,
     `color = meta.color`.
   - Render the VAT card unchanged in semantics:
     `label="VAT (5%)" amount={loading ? '—' : 'AED ' + monthlyVat.toLocaleString()} sub="Due to FTA" pct={100} color="#FF8FAB" borderRose`.
   - **Design constraint:** the rendered DOM must be visually identical to the
     original `2bb67f8` layout (same grid, same `RevCard` markup, same labels,
     same colors). Only the numeric `amount`/`sub`/`pct` come from live data.
   - **Justification for keeping labels/prices hardcoded:** plan name + AED price
     are fixed business constants (89/239/369), not data that varies per query;
     the original design encoded them in the label. `revenue`/`subs` ARE live.
3. **Do not touch** anything else: TopStat row, the two-column section, all
   `TableCard`/`actionTo`/`onAction`/`exportCsv` blocks, "New today"
   (`newTodayCount`), `handleApprove`/`handleReject`. These are already the
   `ee8a1e3` logic and are correct.

Edge cases: `byPlan` empty → `maxRevenue` guard `Math.max(..., 1)` prevents
divide-by-zero; `planOf` returns undefined → `?? 0` yields "AED 0" / "0 active".
`loading` state already shows "—". No new error path needed (errors surface via
existing `error` banner from `load()`'s try/catch).

### WU2a — `admin-panel/src/services/firestore.ts`  (MODIFY)

Add an uncapped fetch used by the Revenue page. Place it inside `RevenueService`,
directly after `recentTransactions()` (do not remove `recentTransactions`).

```ts
/** Full transaction history (no 50-row cap) for the Revenue page's
 *  client-side period filtering. Newest first. */
async allTransactions(): Promise<RevenueTransaction[]> {
  if (useMock()) {
    return [...mockTransactions].sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
  }
  const snap = await getDocs(
    query(collection(db!, 'transactions'), orderBy('createdAt', 'desc')),
  );
  return snap.docs.map((d) => {
    const data = d.data() as Record<string, unknown>;
    return {
      id: d.id,
      familyId: (data.familyId as string) ?? '',
      familyName: (data.familyName as string) ?? '',
      plan: (data.plan as string) ?? '',
      amount: (data.amount as number) ?? 0,
      status: (data.status as RevenueTransaction['status']) ?? 'paid',
      createdAt: parseTimestamp(data.createdAt),
    };
  });
}
```

Notes:
- Reuses existing imports (`collection`, `query`, `orderBy`, `getDocs`,
  `parseTimestamp`, `useMock`). No new imports.
- The live query drops the `limit(50)` — that is the explicit fix for yearly
  truncation. Removing the bound is acceptable here because the page aggregates
  client-side; there is no Dashboard call path that loads this unbounded.
- Mock branch returns the same 10 `mockTransactions` (already spans ~160 days,
  enough to exercise Weekly/Monthly/Yearly in mock mode).
- **Do not** add date `where()` clauses to the service: filtering is done in the
  component so preset switches don't re-query. Keep the service dumb.

Edge case: empty collection → `snap.docs` empty → returns `[]`. Caller handles.

### WU2b — `admin-panel/src/pages/business/Revenue.tsx`  (MODIFY)

Rewrite the page to drive all four sections from one global period filter. Keep
the existing `PageShell/PageHeader/PageContent/TableCard/Row/TopStat/BarRow/
StatusBadge` composition and the existing token usage; add the `FilterBar` +
`FilterSelect` from `ListControls`.

**Imports to add:**
`import { FilterBar, FilterSelect } from '../../components/ui/ListControls';`

**State (replace current `data`/`txns`/`loading`):**
- `const [txns, setTxns] = useState<RevenueTransaction[]>([]);`
- `const [loading, setLoading] = useState(true);`
- `const [error, setError] = useState<string | null>(null);`
- `const [preset, setPreset] = useState<'weekly' | 'monthly' | 'yearly' | 'custom'>('monthly');`
- `const [from, setFrom] = useState('');`  // YYYY-MM-DD
- `const [to, setTo] = useState('');`

**Fetch (effect):** call `RevenueService.allTransactions()` only (drop
`summary()` — all numbers are now derived from txns in range, including VAT).
Wrap in try/catch; on error `setError(...)`, always `setLoading(false)`.
```ts
useEffect(() => {
  RevenueService.allTransactions()
    .then(setTxns)
    .catch((e) => setError((e as Error).message || 'Failed to load revenue'))
    .finally(() => setLoading(false));
}, []);
```

**Preset → date-range wiring:** a helper that maps a preset to `[from,to]`
`YYYY-MM-DD` strings, defined module-scope (pure, testable):
```ts
function presetRange(preset: 'weekly' | 'monthly' | 'yearly'): { from: string; to: string } {
  const now = new Date();
  const to = now;
  const from = new Date(now);
  if (preset === 'weekly') from.setDate(now.getDate() - 6);
  else if (preset === 'monthly') from.setMonth(now.getMonth() - 1);
  else from.setFullYear(now.getFullYear() - 1);
  const iso = (d: Date) => d.toISOString().slice(0, 10);
  return { from: iso(from), to: iso(to) };
}
```
- When a preset button/select changes to weekly/monthly/yearly: set `preset` and
  set `from`/`to` from `presetRange`.
- When the user edits a date input directly: set the date AND set
  `preset = 'custom'` (so the dropdown reflects manual editing).
- On mount, initialize `from`/`to` to `presetRange('monthly')` (default) — do this
  in a `useState` initializer or a one-time effect; default preset is `monthly`.

**Filter the txns (`useMemo`):** inclusive range, same semantics as
`useListControls` (whole "to" day):
```ts
const inRange = useMemo(() => {
  const fromT = from ? new Date(from).getTime() : null;
  const toT = to ? new Date(to).getTime() + 86400000 - 1 : null;
  return txns.filter((t) => {
    const ts = t.createdAt.getTime();
    if (fromT != null && ts < fromT) return false;
    if (toT != null && ts > toT) return false;
    return true;
  });
}, [txns, from, to]);
```

**Derive all four sections from `inRange` (paid only where revenue is meant):**
```ts
const derived = useMemo(() => {
  const paid = inRange.filter((t) => t.status === 'paid');
  const total = paid.reduce((s, t) => s + t.amount, 0);
  const vat = Math.round(total * 0.05);

  // byPlan from paid txns in range (basis change per scope — approved)
  const map: Record<string, { subs: number; revenue: number }> = {};
  paid.forEach((t) => {
    map[t.plan] = { subs: (map[t.plan]?.subs ?? 0) + 1, revenue: (map[t.plan]?.revenue ?? 0) + t.amount };
  });
  const byPlan = Object.entries(map).map(([plan, v]) => ({ plan, ...v }));

  // trend: bucket paid txns by month within range (oldest→newest)
  // reuse buildTrend-style monthly bucketing but bounded to the range span.
  return { paid, total, vat, byPlan };
}, [inRange]);
```

**Trend chart:** keep the existing bar-chart markup. Build the trend buckets in
the component from `derived.paid` over the selected range. Bucket granularity
rule (so weekly ranges aren't one bar):
- span ≤ 31 days → daily buckets (label = `DD/MM`);
- span ≤ 366 days → monthly buckets (label = `MMM`);
- else monthly.
Provide a small local helper `buildRangeTrend(paid, from, to)` returning
`{ label, amount, pct }[]` with `pct` relative to max bucket (same shape the
existing chart already consumes — reuse the existing JSX that maps
`trend.map((m) => …)`). This keeps the chart component code unchanged; only its
data source changes. Empty range → all buckets 0 → existing
`!hasTrendData` empty-state message shows.

**Stat cards (the four `TopStat`s):** replace current values with range-derived:
- `Revenue in range` = `AED ${derived.total.toLocaleString()}`
- `Paid transactions` = `${derived.paid.length}` (count)
- `VAT 5%` = `AED ${derived.vat.toLocaleString()}`
- `Avg / transaction` = `AED ${derived.paid.length ? Math.round(derived.total / derived.paid.length).toLocaleString() : 0}`
  (The old "Last 3 months"/"Active subs" cards depended on `summary()`, which is
  gone; these range-aware replacements are consistent with the one-bar contract.
  Labels chosen to reflect the selected period.)

**Plan revenue split:** unchanged markup; iterate `derived.byPlan` instead of
`data.byPlan`. `pct = Math.min(100, (p.revenue / Math.max(1, derived.total)) * 100)`.
Keep `planColor` map (already in file).

**Recent transactions:** show `inRange` (all statuses) newest-first, capped at the
last 50 *for display only* to keep the DOM light: `inRange.slice(0, 50)`. The
aggregates above use the full `inRange`/`paid`, so yearly totals are NOT
truncated — only the visual list is bounded, with a note row when truncated:
if `inRange.length > 50` render a final muted Row "Showing latest 50 of
{inRange.length}". Keep existing `txVariant` map + Row markup.

**FilterBar placement:** at top of `PageContent`, above the stat cards, exactly
like `AllTrials.tsx`:
```tsx
<FilterBar
  query=""                 // search not used on this page
  setQuery={() => {}}
  from={from}
  setFrom={(v) => { setFrom(v); setPreset('custom'); }}
  to={to}
  setTo={(v) => { setTo(v); setPreset('custom'); }}
  onClear={() => { setPreset('monthly'); const r = presetRange('monthly'); setFrom(r.from); setTo(r.to); }}
  dateLabel="Date"
>
  <FilterSelect
    label="Period"
    value={preset}
    onChange={(v) => {
      const p = v as 'weekly' | 'monthly' | 'yearly' | 'custom';
      setPreset(p);
      if (p !== 'custom') { const r = presetRange(p); setFrom(r.from); setTo(r.to); }
    }}
    options={[
      { value: 'weekly', label: 'Weekly (7 days)' },
      { value: 'monthly', label: 'Monthly (30 days)' },
      { value: 'yearly', label: 'Yearly (12 months)' },
      { value: 'custom', label: 'Custom range' },
    ]}
  />
</FilterBar>
```
- The search box is unused here. To avoid shipping a dead search field, **do not
  pass an empty no-op**; instead the developer must confirm whether `FilterBar`
  renders without the search column. It does NOT (search is hardcoded in
  `FilterBar`). **Decision:** keep the search box visible but inert is NOT
  acceptable (dead UI). Therefore: pass `query`/`setQuery` wired to a real
  `txnQuery` state and make it filter Recent transactions by `familyName`/`plan`
  (cheap, useful, removes dead UI). Add `const [txnQuery, setTxnQuery] = useState('')`
  and apply it to the Recent-transactions list only (not aggregates). Placeholder
  `searchPlaceholder="Search transactions…"`.

**Export CSV (`PageHeader` action):** keep the button; export `derived.byPlan`
plus a second export option is out of scope — keep single CSV of the in-range
plan split (same columns as today). Update `onExport` to use `derived.byPlan`.

**Loading/error states:** keep the existing loading `PageShell`+`PageHeader`
early return; add an error banner Row inside `PageContent` (reuse the rose-pale
banner pattern from Dashboard: `mx`/`p-2 bg-rose-pale text-rose-dark text-[10px]
font-bold rounded-lg`) when `error` is set.

Edge cases handled in this file:
- Empty `txns` → all derived values 0, empty-state rows show.
- `from > to` (user error) → `inRange` empty → zeros + empty states (acceptable;
  no crash). No need to swap dates.
- Plan not in `planColor` → fallback `'#9B6EDB'` (already coded).
- Division guards: `Math.max(1, derived.total)`, `paid.length ? … : 0`.

## 4. Work units & parallelization

| WU | Files | Type | Notes |
| -- | ----- | ---- | ----- |
| WU1 | `pages/Dashboard.tsx` | **INDEPENDENT** | No overlap with WU2 files. |
| WU2a | `services/firestore.ts` | **INDEPENDENT** | Add `allTransactions()` only. No overlap with Dashboard.tsx. |
| WU2b | `pages/business/Revenue.tsx` | **SEQUENTIAL after WU2a** | Calls `allTransactions()`; depends on WU2a existing. |

**File-overlap verification (required by task):** WU1 touches only
`Dashboard.tsx`. WU2 touches `firestore.ts` + `Revenue.tsx`. Dashboard imports
from `firestore.ts` but **does not modify it**, and WU2a only *adds* a method to
`RevenueService` (no change to `summary()`/types Dashboard relies on). Therefore
**WU1 ∥ WU2 are truly non-overlapping and safe to build in parallel.** Inside WU2,
WU2a → WU2b is sequential (compile dependency). Recommend: dev A = WU1, dev B =
WU2a then WU2b.

## 5. Refactor callouts

None required. The codebase practice is sound: shared `AdminUI`/`ListControls`
primitives, a clean mock-aware service layer, consistent tokens. The only debt
touched is the `limit(50)` cap, addressed by adding `allTransactions()` rather
than mutating the existing method (minimal, no collateral). No competing pattern
introduced.

## 6. Test plan (what the reviewer will exercise)

Build/type:
- `cd admin-panel && npm run build` (or `tsc --noEmit`) passes with zero TS errors.

WU1 (Dashboard) — mock mode:
- Revenue row renders 4 cards, same layout/colors/labels as original `2bb67f8`.
- Card amounts/subs reflect `RevenueService.summary().byPlan` mock values
  (weekly 2225/25, monthly 7170/30, twoMonths 3690/10), VAT card = 540.
- All TableCard links navigate (`/nannies/verify`, `/nannies`, `/families`,
  `/trials`); 4 CSV export buttons download; "New today" computes; sidebar badges
  unchanged.

WU2 (Revenue) — mock mode:
- One filter bar present (Period select + Date from/to + search), styled via
  ListControls (no one-off styling).
- Default = Monthly: stat cards, trend, plan split, recent txns all reflect paid
  txns in last 30 days.
- Switch Weekly → all four sections shrink to last 7 days consistently.
- Switch Yearly → totals include txns up to ~160 days old (mock has txns at 130/
  160 days) and are NOT truncated; aggregates count full set even if list shows
  "latest 50 of N".
- Custom from/to → updates all sections; editing a date flips Period to "Custom".
- Clear → returns to Monthly default range.
- Transaction search filters the Recent list only, not the aggregates.
- Empty range (from>to) → zeros + empty states, no crash.

Live mode (smoke, if Firestore configured): `allTransactions()` returns >50 rows
when present and yearly totals reflect them.

## 7. Definition of done (gradable)

- [ ] Dashboard revenue row DOM matches pre-`ee8a1e3` layout (grid, RevCard
      markup, 3 plan + VAT cards, labels, colors, `borderRose`).
- [ ] Dashboard plan cards show live `byPlan` revenue/subs; VAT card shows live
      `monthlyVat`; loading shows "—".
- [ ] All `ee8a1e3` behavior intact: TableCard `actionTo` links, 4 `onAction`
      CSV exports, computed "New today", live sidebar badges.
- [ ] `RevenueService.allTransactions()` added (mock + live), live path has no
      `limit(50)`; `recentTransactions()` left in place.
- [ ] Revenue page has ONE global FilterBar (Weekly/Monthly/Yearly + custom
      from/to) built from `FilterBar`/`FilterSelect` — no new styling.
- [ ] Changing the filter updates stat cards, trend, plan split, and recent txns
      consistently from paid txns in range; plan split basis = paid txns in
      period.
- [ ] Yearly / wide ranges not truncated in aggregates (display list cap is
      cosmetic with a "latest 50 of N" indicator).
- [ ] Works in mock + live; `tsc`/build passes.
- [ ] No empty catches; every async path has error handling; no dead UI fields.
