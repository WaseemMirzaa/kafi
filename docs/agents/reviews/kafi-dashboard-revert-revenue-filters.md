---
slug: kafi-dashboard-revert-revenue-filters
project: kafi-admin-panel
title: Revert dashboard design (keep logic), add global period filters to Revenue page
owner: architect-reviewer
status: REVIEW_PASS
updated: 2026-06-07
---

# Review — kafi-dashboard-revert-revenue-filters

**Verdict: REVIEW_PASS.** 0 Critical, 0 Major. 2 Minor (non-blocking).

Reviewed the integrated `feat/kafi-dashboard-revert-revenue-filters` branch
(HEAD `0767f62`). Type-check `tsc --noEmit` exit 0; `npm run build` exit 0.
Traced all flows end-to-end by reading the code paths and simulating the date
math / mock-fixture windows in node. The three flagged integration risks were
verified clean.

## Integration-risk verification (build-note items 1–3)

**1. Merged `Dashboard.tsx` is coherent.** No conflict markers, no duplicated or
orphaned blocks, single `Dashboard`/`load`/`handleApprove`/`handleReject`. The
revenue row (lines 290–313) is the original `2bb67f8` layout exactly — same grid
(`grid grid-cols-2 lg:grid-cols-4 gap-2 px-[18px] pb-3`), same `RevCard` markup,
same 3-plan + VAT order, same labels (`Weekly · AED 89`, `Monthly · AED 239`,
`2 months · AED 369`, `VAT (5%)`), same colors, same `borderRose`, same
`sub="Due to FTA"` — now fed by live `byPlan`/`monthlyVat`. `byPlan` state added
and `setByPlan(rev.byPlan)` wired in `load()`. All `ee8a1e3` wiring intact: 4
TableCard `actionTo` links (`/nannies/verify`, `/nannies`, `/families`,
`/trials`), 4 `onAction` CSV exports (nanny nationality, active-by-city,
subscription breakdown, family nationality), computed `newTodayCount`, live
sidebar/count badges, `handleApprove`/`handleReject` preserved.

**2. `Revenue.tsx` meets scope and preserves `ee8a1e3` intent.** WU2's wholesale
version supersedes the `summary()`-based sections with range-aware equivalents,
which is exactly what the plan specified (approved basis change). The `ee8a1e3`
trend fix intent is preserved and improved: live transaction-based trend via
`buildRangeTrend`, AED labels on bars, `!hasTrendData` empty state. One global
`FilterBar` + `FilterSelect` (Weekly/Monthly/Yearly/Custom) drives all four
sections from `inRange` paid txns. Plan split = paid txns in period. Aggregates
use full `inRange`; only the visual list is capped at 50 with a "Showing latest
50 of N" indicator — yearly is NOT truncated.

**3. `firestore.ts` auto-merge clean.** `allTransactions()` (uncapped, mock +
live) coexists with `recentTransactions()` (kept per plan) and `summary()`
(still used by Dashboard + Subscriptions). Mock branch returns the 10
`mockTransactions`. No `limit(50)` on the live `allTransactions` query.

## Acceptance criteria

- [PASS] Dashboard revenue row visually matches pre-`ee8a1e3` — diffed against
  `git show 2bb67f8`; DOM structure/labels/colors identical.
- [PASS] All `ee8a1e3` behavior works — actionTo links, 4 CSV exports, live
  badges, computed "New today" all present and unchanged.
- [PASS] ONE global filter bar from ListControls primitives, no one-off styling.
- [PASS] Filter updates stat cards, trend, plan split, recent txns consistently
  from paid txns in range (all derived from the same `inRange` memo).
- [PASS] Yearly / wide ranges not truncated in aggregates (display cap cosmetic
  with indicator). Verified mock: yearly = 8 paid txns counted in full.
- [PASS] Mock + live modes both handled; `tsc` and `npm run build` pass.
- [PASS] Chat/dispute/trial changes are their own commit `23cb82d` (4 expected
  files), separate from the WU1/WU2 commits.

## Quality bar (CLAUDE.md §4)

- Design tokens: filter bar entirely from `FilterBar`/`FilterSelect`; cards use
  `TopStat`/`BarRow`/`Row`; error banner reuses `bg-rose-pale text-rose-dark`.
  No generic styling. PASS.
- Typed: `Preset` union typed; service returns `RevenueTransaction[]`; dropped
  unused `RevenueSummary` import. PASS.
- Error paths: `allTransactions()` fetch has `.catch` → `setError` →
  `.finally(setLoading(false))`; error banner rendered. `load()` try/catch
  intact. No empty catches. PASS.
- Duplication: reused all existing primitives; new service method instead of
  mutating `recentTransactions()`. PASS.
- No secrets; division/empty guards (`Math.max(...,1)`, `paid.length ? : 0`,
  `?? 0`); search filters list only, not aggregates (no dead UI). PASS.

## Minor findings (non-blocking — fix opportunistically or defer)

**M1 — `recentTransactions()` is now dead code.** Severity: Minor. Where:
`firestore.ts:1430`. After this change no caller references it (grep confirms
only `allTransactions` is used by Revenue; `summary` by Dashboard/Subscriptions).
Root cause: the plan deliberately kept it to minimize the diff and avoid touching
unrelated call sites — a defensible call at plan time, but the result is an
unused exported method. Not a defect; flagging for a future cleanup pass. No
action required for this PR. If addressed later: delete `recentTransactions()`
and its `limit` import if then unused.

**M2 — Weekly preset shows empty state in mock mode.** Severity: Minor
(cosmetic, data-driven, not a bug). Where: Revenue page, Weekly preset. The mock
fixture's only txns within 7 days are one `failed` (3d) and one `refunded` (7d),
so Weekly yields zero paid → AED 0 cards, empty plan split, "No data for selected
period" trend. This is correct behavior and usefully exercises the empty-state
paths, but a demo of Weekly will look empty. Root cause: mock fixture gap (build
note already flagged the inverse for Yearly). Optional: add one recent `paid`
mock txn (e.g. 2 days ago) so all three presets demo with data. No code defect.

## Re-review notes

Nothing to re-verify — pass on first review. The merge integration the build note
worried about is sound: both the full-file Dashboard rewrite and the wholesale
Revenue replacement produced a coherent tree with all `ee8a1e3` behavior intact.
