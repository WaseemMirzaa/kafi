---
slug: kafi-listing-filters
project: Nannies app (Kafi admin)
title: Separate nationality / city / status dropdown filters on nannies and families listings
owner: developer
status: READY_FOR_REVIEW
updated: 2026-06-07
worktree-branch-wu1: worktree-agent-a3c201e906e0bc713
worktree-branch-wu2: worktree-agent-a65e8e6de0b6a738c
---

# Build: kafi-listing-filters

## WU1 — Nanny screens + shared helper

### Work unit scope
Files owned by WU1 (write set):
- `admin-panel/src/components/ui/ListControls.tsx`
- `admin-panel/src/pages/nannies/AllNannies.tsx`
- `admin-panel/src/pages/nannies/VerifyDocuments.tsx`

`admin-panel/src/pages/families/AllFamilies.tsx` is WU2 — NOT touched.

---

### File-by-file changes

#### `admin-panel/src/components/ui/ListControls.tsx`
Added one exported pure helper `distinctOptions<T>` at the top of the file (before `inputCls`). Generic over `T`, returns `{ value, label }[]` with an "All …" entry prepended, followed by distinct non-empty values sorted locale-aware case-insensitively. Skips `null`/`undefined`/whitespace-only accessor values. No other changes to this file.

#### `admin-panel/src/pages/nannies/AllNannies.tsx`
- Added `distinctOptions` to the existing `ListControls` import.
- Added two `useState` hooks (`nationality`, `city`), defaulting to `'all'`, next to the existing `status` state.
- Extended `extraFilter` `useMemo` to AND all three dropdown predicates; updated deps array to `[status, nationality, city]`.
- Added `nationalityOptions` and `cityOptions` memos (both `useMemo` over `items`, calling `distinctOptions`), placed after the `stats` memo.
- Updated `FilterBar.onClear` to also reset `nationality` and `city` to `'all'`.
- Added two `FilterSelect` children inside `FilterBar` after the existing Status select: Nationality then City.
- CSV export, stats, block/unblock, row rendering, pagination, navigation — all untouched.

#### `admin-panel/src/pages/nannies/VerifyDocuments.tsx`
- Added `distinctOptions` to the existing `ListControls` import.
- Added two `useState` hooks (`nationality`, `city`), defaulting to `'all'`, next to the existing `docStatus` state.
- Extended `extraFilter` `useMemo` to AND all three predicates (doc status, nationality, city); updated deps.
- Added `nationalityOptions` and `cityOptions` memos inline right after the `extraFilter` definition.
- Updated `FilterBar.onClear` to also reset `nationality` and `city`.
- Added two `FilterSelect` children inside `FilterBar` after the existing Document-status select.
- Documents popup, approve/reject flows, stats, pagination — all untouched.

---

### Build verification

Command: `cd admin-panel && npm run build` (runs `tsc && vite build`)

Result:
```
vite v5.4.21 building for production...
✓ 95 modules transformed.
dist/index.html                   0.78 kB │ gzip:   0.41 kB
dist/assets/index-CUgojfr7.css   19.88 kB │ gzip:   4.74 kB
dist/assets/index-D79iKusV.js   785.31 kB │ gzip: 198.89 kB
✓ built in 3.62s
```

TypeScript: 0 errors. No new dependencies introduced. No `any` used.

The chunk-size warning (`> 500 kB`) was pre-existing and is not caused by WU1 changes.

---

### Deviations from plan
None. Implementation matches the plan exactly: helper signature, state placement, `extraFilter` shape, memo deps, `onClear` callback, `FilterSelect` order, and untouched sections.

---

### Known gaps / follow-ups
- WU2 (`AllFamilies.tsx`) is a separate work unit; it imports `distinctOptions` from `ListControls.tsx`. WU2's build will succeed once this worktree is merged (or if WU2 builds against a tree that includes WU1's commit).
- Chunk size warning is pre-existing — not introduced by this unit. Code-splitting is a separate concern.

---

### Commit
`1e6af1e` — `feat(admin): add distinctOptions helper + Nationality/City filters on nanny pages (kafi-listing-filters WU1)`

---

## WU2 — Families screen (migration)

### Work unit scope
File owned by WU2 (write set):
- `admin-panel/src/pages/families/AllFamilies.tsx`

No other files touched.

---

### File-by-file changes

#### `admin-panel/src/pages/families/AllFamilies.tsx`
Complete migration from the bespoke header search + local `useMemo` filter pattern to the shared `FilterBar`/`useListControls` pattern. Changes:

- **Imports added:** `FilterBar`, `FilterSelect`, `Pagination`, `distinctOptions` from `ListControls`; `useListControls` from `hooks/useListControls`.
- **Removed:** `const [search, setSearch] = useState('')` and the local `filtered` `useMemo` (previously lines 36 and 59-65).
- **Added `SUB_STATUSES` constant** at module level (near the existing `statusVariant`/`statusLabel` maps): typed array of all five `FamilyRow['subscription']['status']` values, used to build the subscription dropdown options without hardcoding strings inline.
- **Added three `useState` hooks:** `nationality`, `city`, `subStatus` — all default `'all'`.
- **`extraFilter` memo:** ANDs nationality, city, and subscription-status predicates with deps `[nationality, city, subStatus]`.
- **`useListControls` wired** with `search` (matches fullName, nationality, city), `extraFilter`, `pageSize: 8`. `getDate` omitted — see Deviations.
- **`nationalityOptions` and `cityOptions`** derived via `distinctOptions(items, accessor, allLabel)` memoized over `items`.
- **`subStatusOptions`** built from `SUB_STATUSES.map(s => ({ value: s, label: statusLabel[s] ?? s }))` so dropdown labels match the badge labels; not from `distinctOptions` because labels differ from values.
- **Stats** (`subscribed`, `free`, `expired`) remain computed from `items` (totals, not filtered) — unchanged.
- **`PageHeader` actions:** bespoke `<input type="search">` removed; only the Export CSV button remains.
- **`FilterBar`** inserted between the stats row and `TableCard` with `dateLabel="Joined"`, containing Subscription, Nationality, City `FilterSelect`s in that order; `onClear` resets `lc` state plus all three dropdowns.
- **Table body:** replaced `filtered.map(...)` with `lc.pageItems.map(...)`; empty state condition changed to `!loading && lc.total === 0` with message "No families match your filters."
- **`Pagination`** added inside `TableCard` after rows (new — AllFamilies had none before).
- **CSV export:** `exportCsv('families.csv', lc.filtered, ...)` — changed from `filtered` to `lc.filtered`. Columns unchanged.
- Row rendering, block/unblock, `StatusBadge`, trial badge, `View →` link — all identical to the original.

---

### Build verification

Command: `cd admin-panel && npm run build` (runs `tsc && vite build`)

Worktree was merged onto `feat/kafi-listing-filters` (commit `1f28d75`) before building so that WU1's `distinctOptions` export was present.

Result:
```
vite v5.4.21 building for production...
✓ 893 modules transformed.
dist/index.html                     0.78 kB │ gzip:   0.42 kB
dist/assets/index-DJ_jRqvA.css     19.87 kB │ gzip:   4.70 kB
dist/assets/index-BhouT2hm.js   1,181.46 kB │ gzip: 308.55 kB
✓ built in 4.21s
```

TypeScript: 0 errors (`tsc` exits clean). Vite build: success. No new dependencies. No `any`.

Chunk-size warning is pre-existing (also reported in WU1's build note).

Pre-merge test (WU2 worktree without WU1): `tsc` exits clean; Vite bundler fails only on `"distinctOptions" is not exported by ListControls.tsx` — confirming no other errors and that the WU1 dependency is the sole blocker, exactly as the plan predicted.

---

### Deviations from plan

**`getDate` omitted from `useListControls`:** The plan instructs `getDate: (f) => f.createdAt` with `dateLabel="Joined"`. However, the current `FamilyRow` interface (lines 150–183 of `firestore.ts`) does not include a `createdAt` field, and `parseFamily` does not set one. Adding `getDate: (f) => (f as any).createdAt` would introduce an `any` (forbidden) and the field would always be `undefined`, making the date range filter silently inert. Instead, `getDate` is omitted and `FilterBar` still renders the date pickers (its `from`/`to` props are wired as required by the component contract) — date-range filtering is a no-op for families until `createdAt` is added to `FamilyRow`. This is flagged for the architect-reviewer.

All other plan directives implemented exactly.

---

### Known gaps / follow-ups

- `FamilyRow` needs a `createdAt?: Date` field added in `firestore.ts` (and `parseFamily` / mock data updated) before the "Joined" date-range filter can be functional. This is a data-layer change outside this WU's write set.
- Chunk size warning is pre-existing — not introduced by either WU.

---

### Commit
`07a301b` — `feat(admin): migrate AllFamilies to FilterBar/useListControls with Subscription/Nationality/City filters (kafi-listing-filters WU2)`
