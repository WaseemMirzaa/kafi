---
slug: kafi-listing-filters
project: Nannies app (Kafi admin)
title: Separate nationality / city / status dropdown filters on nannies and families listings
owner: developer
status: READY_FOR_REVIEW
updated: 2026-06-07
worktree-branch: worktree-agent-a3c201e906e0bc713
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
