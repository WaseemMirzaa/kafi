---
name: kafi-revenue-patterns
description: Recurring review check points for Kafi admin Dashboard.tsx and business/Revenue.tsx revenue work
metadata:
  type: project
---

Review check points for Kafi admin revenue features (Dashboard + Revenue page).

**Why:** `kafi-dashboard-revert-revenue-filters` established the shape; future
revenue tasks will touch the same files and primitives.

**How to apply:**
- Dashboard revenue row: original (`2bb67f8`) layout = 3 plan `RevCard`s + 1 VAT
  `RevCard`, grid `grid-cols-2 lg:grid-cols-4`, labels carry fixed AED prices
  (89/239/369), live values come from `RevenueService.summary().byPlan` + `.vat`.
- `RevenueService` (firestore.ts ~line 1370+): `summary()` used by Dashboard +
  families/Subscriptions; `allTransactions()` (uncapped) used by Revenue page;
  `recentTransactions()` (limit 50) currently has no callers — dead but kept.
- Revenue page filters must reuse `FilterBar`/`FilterSelect` from
  `components/ui/ListControls.tsx`; pattern reference is `pages/trials/AllTrials.tsx`.
  Inclusive-day range semantics: `new Date(to).getTime() + 86400000 - 1`.
- Mock fixture `mockTransactions` spans ~3 to 160 days ago; within 7 days there
  are only failed/refunded txns, so the Weekly preset legitimately shows empty
  paid aggregates in mock mode. Don't flag that as a bug.
- Date presets use `toISOString().slice(0,10)` (UTC) vs local `Date` createdAt;
  the whole-day inclusion tolerates the skew — matches `useListControls`, fine.
- Revenue trend bucketing (`buildRangeTrend`/`trendMode` in Revenue.tsx) splits
  daily vs monthly at `spanDays <= 31`. The "Monthly (30 days)" preset uses
  `setMonth(now.getMonth()-1)` → a 32-day inclusive span → falls into MONTHLY
  bucketing (2 calendar buckets), NOT daily. Don't flag as a bug — it's a
  pre-existing label/boundary mismatch; still non-flat + consistent. Only flag if
  a task's plan promises daily granularity on the monthly preset.
- Mock revenue determinism: `seeded(0xdeadbeef)` mulberry32 gives a stable
  plan/status/family/id sequence; `createdAt` is anchored to `Date.now()` BY
  DESIGN (relative presets need it), so timestamps legitimately shift across
  reloads. "Deterministic" means stable sequence, not frozen dates — don't flag.
- Chart lives at `components/charts/RevenueTrendChart.tsx`: presentational, no
  data logic, consumes `derived.trend` (`{label,amount,pct}[]`). Verify
  chart-sum == "Revenue in range" stat (both from `derived.paid`).
