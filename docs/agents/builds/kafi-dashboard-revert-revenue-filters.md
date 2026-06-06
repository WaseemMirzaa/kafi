---
slug: kafi-dashboard-revert-revenue-filters
project: kafi-admin-panel
title: Revert dashboard design (keep logic), add global period filters to Revenue page
owner: developer
status: READY_FOR_REVIEW
updated: 2026-06-07
---

# Build — kafi-dashboard-revert-revenue-filters

Two parallel work units, built in separate worktrees and merged by the PM into
`feat/kafi-dashboard-revert-revenue-filters`:

- WU1 branch `worktree-agent-ac0b3ebbc2fac3052` (Dashboard)
- WU2 branch `worktree-agent-aa3a759764c66b6a0` (Revenue + firestore)

**Merge notes (PM):** both worktrees were based on `2bb67f8` (initial commit),
not the feature-branch HEAD `d6c4423`. WU1 compensated by writing Dashboard.tsx
as a complete file including the `ee8a1e3` logic. WU2's Revenue.tsx rewrite
conflicted with `ee8a1e3`'s Revenue changes on merge; resolved by taking WU2's
version, which intentionally supersedes the `summary()`-based sections with
range-aware equivalents (per plan). `firestore.ts` auto-merged (WU2a was
additive). **Reviewer: pay special attention to the merged `Dashboard.tsx` (ort
auto-merge of a full-file rewrite) and to whether `Revenue.tsx` retains the
intent of `ee8a1e3`'s trend fix (live transaction-based trend, AED labels,
empty state).** Type-check of the integrated branch run by the PM (see below).

---

## WU1 — `admin-panel/src/pages/Dashboard.tsx`

**Status:** READY_FOR_REVIEW

1. **`byPlan` state added**: `useState<{ plan: string; subs: number; revenue: number }[]>([])`.
2. **`setByPlan(rev.byPlan)` wired in `load()`** after `setMonthlyVat(rev.vat)` inside the existing `Promise.all` resolution; no other changes to load/error/finally flow.
3. **Hardcoded revenue row replaced with live-mapped RevCards**:
   - `planMeta` module-scope constant: plan key → `{ label, color }` for the three fixed plans; labels/prices are fixed business constants (89/239/369).
   - `maxRevenue = Math.max(...byPlan.map(p => p.revenue), 1)` — divide-by-zero guard; `planOf(key)` with `?? 0` fallbacks.
   - Loading state: `'—'` for amount while loading.
   - VAT RevCard uses live `monthlyVat`; grid wrapper identical to the original layout — visual structure unchanged from pre-`ee8a1e3`.
4. **All `ee8a1e3` logic preserved**: `exportCsv` import, `TableCard` `actionTo`/`onAction` props, navigation to `/nannies`, `/families`, `/trials` (+ verify), 4 CSV export handlers, computed `newTodayCount` from `f.createdAt >= todayStart`.

Files NOT touched: `Revenue.tsx`, `firestore.ts`.

## WU2 — `admin-panel/src/services/firestore.ts` + `admin-panel/src/pages/business/Revenue.tsx`

**Status:** READY_FOR_REVIEW

### WU2a — firestore.ts (additive only)
- `RevenueService.allTransactions()` added after `recentTransactions()`: live path has no `limit(50)` (fixes yearly truncation); mock path returns `mockTransactions` newest-first; zero new imports; `recentTransactions()` intact.

### WU2b — Revenue.tsx (page logic rewrite)
- Single `allTransactions()` fetch replaces `Promise.all([summary(), recentTransactions()])`; `RevenueSummary` import dropped.
- State: `txns`, `loading`, `error`, `preset` (weekly/monthly/yearly/custom), `from`/`to` (default monthly), `txnQuery`.
- Pure module-scope helpers: `presetRange()` (preset → inclusive `{from,to}`), `buildRangeTrend()` (daily buckets ≤31-day span, monthly otherwise).
- Memos: `inRange` (inclusive-day filter, same `+86400000-1` semantics as `useListControls`), `derived` (`paid`, `total`, `vat`, `byPlan`, `trend`, `hasTrendData`), `visibleTxns` (search over familyName/plan, display-capped at 50).
- `FilterBar` + `FilterSelect` from ListControls (pattern as `AllTrials.tsx`); editing a date flips preset to Custom; `onClear` resets to monthly default.
- Stat cards range-aware: Revenue in range, Paid transactions, VAT 5%, Avg/transaction. Plan split basis = paid txns in period (scope-approved).
- "latest 50 of N" indicator when `inRange.length > 50`; error banner with existing `bg-rose-pale text-rose-dark` tokens; empty states + NaN guards throughout; no new one-off styling.

## Type-check / build results (PM, integrated branch)

- WU1 worktree: `tsc --noEmit` exit 0.
- WU2 worktree: `tsc --noEmit` exit 0.
- Integrated feature branch after merge: PM ran `tsc --noEmit` post-merge (result recorded in review).

## Deviations from plan

- None in logic/contracts reported by either developer.
- Process: developer sandboxes blocked git/npm; PM ran type-checks and commits.
- Worktree base mismatch (above) — reviewer must verify the merged integration.

## Known gaps / follow-ups

- Mock fixture spans ~42 days, so the Yearly "latest 50 of N" truncation path can't be exercised in mock mode (fixture gap, not a code defect).
