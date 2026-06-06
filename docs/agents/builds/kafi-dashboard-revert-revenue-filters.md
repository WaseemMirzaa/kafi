---
slug: kafi-dashboard-revert-revenue-filters
project: kafi-admin-panel
title: Revert dashboard design (keep logic), add global period filters to Revenue page
owner: developer
status: READY_FOR_REVIEW
updated: 2026-06-07
worktree-branch: main
---

# Build — kafi-dashboard-revert-revenue-filters

## Work unit implemented

**WU2 (WU2a then WU2b sequential)** — Revenue service uncapped fetch + Revenue page global filter bar.

WU1 (Dashboard.tsx) is out of scope for this developer session.

## Files changed

### `admin-panel/src/services/firestore.ts` (WU2a — additive only)

Added `RevenueService.allTransactions()` method directly after `recentTransactions()`. The new method:
- Returns the full transaction list with no `limit(50)` cap in the live Firestore path (fixes yearly truncation).
- Mock path returns the same `mockTransactions` array sorted newest-first — identical behavior to `recentTransactions()` mock, so all mock test scenarios work.
- Reuses all existing imports (`collection`, `query`, `orderBy`, `getDocs`, `parseTimestamp`, `useMock`) — zero new imports.
- `recentTransactions()` left completely intact as specified (no deletions).

### `admin-panel/src/pages/business/Revenue.tsx` (WU2b — full rewrite of page logic)

Replaced the two-call `Promise.all([summary(), recentTransactions()])` pattern with a single `allTransactions()` fetch. All four page sections (stat cards, trend, plan split, recent transactions) are now derived client-side via `useMemo` from paid transactions within the selected period. Key changes:

- **`RevenueSummary` import dropped** — no longer needed; `summary()` is not called.
- **State:** `txns` (raw fetch), `loading`, `error`, `preset` (weekly/monthly/yearly/custom), `from`/`to` (YYYY-MM-DD strings defaulting to monthly range), `txnQuery` (search).
- **`presetRange()`** — pure module-scope helper; maps preset to `{from, to}` inclusive date strings.
- **`buildRangeTrend()`** — pure module-scope helper; buckets paid transactions daily (span <= 31 days) or monthly (else) for the trend chart; returns `{label, amount, pct}[]` matching the existing chart markup's shape.
- **`inRange` memo** — inclusive-day filter over all `txns` for the selected range; reuses the same `+86400000-1` semantics as `useListControls`.
- **`derived` memo** — computes `paid`, `total`, `vat`, `byPlan`, `trend`, `hasTrendData` from `inRange`. Plan split basis is now paid transactions in period (scope-approved change).
- **`visibleTxns` memo** — applies `txnQuery` search (familyName/plan) to `inRange`, capped at 50 for display; aggregates use full `inRange`/`paid`.
- **FilterBar** — uses `FilterBar` + `FilterSelect` from `ListControls` exactly as in `AllTrials.tsx`. Search wired to `txnQuery` (filters Recent transactions list only, not aggregates — eliminates dead UI).
- **Period dropdown** — Weekly/Monthly/Yearly/Custom presets; editing a date input flips preset to Custom.
- **onClear** — resets search, preset to monthly, and from/to to monthly default range.
- **Stat cards** — range-aware: Revenue in range, Paid transactions count, VAT 5%, Avg/transaction.
- **"latest 50 of N" indicator** — shown when `inRange.length > 50`.
- **Error banner** — uses `bg-rose-pale text-rose-dark` token pattern from Dashboard; shown when `allTransactions()` rejects.
- **Empty states** — all sections have graceful empty-state text; division guards `Math.max(1, ...)` and `paid.length ? ... : 0` prevent NaN.
- **No new one-off styling** — all layout/colors use existing Tailwind tokens, AdminUI components, and ListControls primitives.

## Type-check / build result

Bash access was denied during this session, so `npx tsc --noEmit` could not be run automatically. Manual review confirms:

- All imports resolve to existing named exports (verified by reading AdminUI.tsx, ListControls.tsx, firestore.ts, csv.ts).
- `strict: true`, `noUnusedLocals: true`, `noUnusedParameters: true` — all declared variables and parameters are used; no dead locals.
- `RevenueTransaction` type is fully satisfied in `allTransactions()` return shape (identical to `recentTransactions()` mapping).
- `exportCsv` generic type inference works: `derived.byPlan` is `{ plan: string; subs: number; revenue: number }[]` and the column callbacks match.
- `FilterBar` and `FilterSelect` prop contracts fully satisfied (verified against ListControls.tsx source).

**Action required:** The PM or reviewer should run `cd admin-panel && npx tsc --noEmit` before the final review pass.

## Deviations from plan

None. All implementation matches the plan's specified contracts, signatures, data shapes, and JSX structure exactly.

## Known gaps / follow-ups

- TypeScript build was not machine-verified (Bash access denied in this session). Manual review is thorough but reviewer should run tsc.
- Mock data spans ~42 days max (the actual `mockTransactions` in code), not 160 as referenced in the plan's test notes. The Yearly preset will include all mock transactions but the "latest 50 of N" truncation indicator cannot be exercised with only 6 mock rows. This is a data gap in the existing mock fixture, not a code defect.
- Git commit could not be created (Bash access denied). PM needs to commit after reviewing.

## Worktree branch

Bash access was denied so the branch name could not be confirmed via git. The gitStatus header at session start shows `Current branch: main`. The plan notes the feature branch is `feat/kafi-dashboard-revert-revenue-filters` — if the PM set up this worktree on that branch, the commit should land there.
