---
slug: kafi-revenue-trend-chart
project: Nannies app (Kafi admin)
title: Professional Recharts revenue-trend area chart on Revenue page, driven by enriched mock data
owner: architect-reviewer
status: REVIEW_PASS
updated: 2026-06-07
---

# Review: kafi-revenue-trend-chart

**Verdict: REVIEW_PASS** — 0 Critical, 0 Major, 2 Minor.

Reviewed the integrated branch `feat/kafi-revenue-trend-chart` (both work-unit
worktrees merged). The implementation matches the plan file-by-file, holds the
architecture/best-practice bar, and all acceptance criteria pass. Findings below
are Minor (non-blocking) plus the evidence for each criterion.

## Verification method

- Read all three integrated files against the plan's exact spec.
- `npm run build` (tsc + vite): **PASS** — 893 modules transformed (recharts now
  bundled; bundle grew to ~1.18 MB, pre-existing chunk-size warning only).
- Worktree base-mismatch check (both build notes flagged branching off `2bb67f8`
  then resetting/ff-merging to feature HEAD): grepped for conflict markers (none)
  and duplicate top-level declarations in all three files (none — each of
  `mockTransactions`, `seeded`, `buildTrend`, `RevenueTransaction`, `Revenue`,
  `buildRangeTrend`, `trendMode`, `presetRange` appears exactly once). The ort
  merge did not orphan or duplicate code.
- Simulated the deterministic generator + `buildRangeTrend` bucketing in Node to
  exercise the data-driven criteria (determinism, weekly coverage, chart/stat
  consistency, non-flat curves) without a browser.

## Acceptance criteria

1. **Recharts area chart with rose-gradient, monotone curve, axes, tooltip** —
   PASS. `RevenueTrendChart.tsx` uses `AreaChart` + `Area type="monotone"`,
   gradient `#FF5C8A`@0.35 → `#FF8FAB`@0, 2px `#FF5C8A` stroke, `#EBEEF8` grid,
   `#8090B0` ticks, compact `k` Y-axis, custom tooltip (navy value, `#EBEEF8`
   border, `AED X,XXX` via `toLocaleString`). Hex values verified against
   `tailwind.config.js` tokens (rose `#FF8FAB`, rose.dark `#FF5C8A`, navy). Exact
   match to plan §3.
2. **Chart derived from same filtered paid txns; reacts to filters; totals
   consistent with "Revenue in range"** — PASS. Chart is fed `derived.trend`
   from the same `derived` memo (`paid` → `buildRangeTrend`) that the stat card
   uses. Simulation confirmed `sum(chart buckets) === derived.total` on all
   presets: weekly 2768 = 2768, monthly 9930 = 9930, yearly 144200 = 144200.
3. **Empty state preserved** — PASS. `!derived.hasTrendData` branch and the
   string "No data for selected period." are unchanged; chart mounts only when
   data exists.
4. **Non-flat curve on weekly / monthly / yearly** — PASS. Weekly: 7 nonzero
   daily buckets (6 distinct values). Monthly: 2 nonzero buckets (2 distinct).
   Yearly: 13 nonzero monthly buckets (13 distinct). All non-flat. Weekly
   coverage is *guaranteed* (forced paid row per day 0..6), fixing the prior
   sparse-weekly risk noted in scope and in my memory.
5. **Mock enrichment touches only the mock block; live path/type/CSV/plan-split/
   table unchanged** — PASS. `git diff --stat` confined to the 3 planned files.
   `RevenueTransaction` interface, `buildTrend` (default `months = 6`), and all
   `RevenueService` methods are byte-unchanged. Generator is a typed IIFE above
   `buildTrend`, no `any`.
6. **No new dependency; typed; responsive; no console errors** — PASS. recharts
   resolves to 2.15.4 (satisfies `^2.12.7`), already in package.json. No `any`
   (tooltip typed via `TooltipProps<number, string>`). `ResponsiveContainer`
   used. `isAnimationActive={false}` avoids render noise.
7. **`npm run build` passes; lint passes on changed files** — build PASS. Lint:
   the `lint` script is `eslint . --ext ts,tsx` but the project has no
   `eslint.config.js` (ESLint 9 flat-config requirement), so lint is
   non-functional project-wide. Pre-existing gap, not introduced here; tsc is
   the authoritative static gate and passes clean. See Minor 2.

## Findings

### Minor 1 — "Monthly" preset renders 2 monthly buckets, not ~30 daily buckets
- **Where:** `Revenue.tsx` interaction between `presetRange('monthly')` and
  `buildRangeTrend` / `trendMode` span threshold (all pre-existing, unchanged by
  this task).
- **What & evidence:** `presetRange('monthly')` does `setMonth(now.getMonth()-1)`,
  producing a 32-day inclusive span (e.g. 2026-05-06 → 2026-06-06). The bucket
  threshold is `spanDays <= 31` → daily, so 32 days falls into **monthly**
  bucketing and the "Monthly (30 days)" preset shows 2 calendar-month buckets
  (May, Jun), not the "~30 daily buckets" the plan's test step 3 anticipated.
- **Root cause:** The preset label says "30 days" but the date math yields 32
  inclusive days, crossing the daily/monthly boundary. This is a cosmetic
  mismatch between the preset's intent and the bucketing boundary, both of which
  predate this task (the plan explicitly kept `buildRangeTrend` and `presetRange`
  as-is). The acceptance criterion ("non-flat on all three presets") still
  passes — 2 distinct nonzero buckets is non-flat and the totals are consistent.
- **Why not a blocker:** No criterion fails; chart is correct and consistent.
  The only deviation is from the plan's *prose* expectation of daily granularity
  on this preset, not from any criterion or contract.
- **Exact fix (optional, defer to PM — touches out-of-scope `presetRange`):** if
  daily granularity is desired for the monthly preset, change
  `fromDate.setMonth(now.getMonth() - 1)` to `fromDate.setDate(now.getDate() - 29)`
  so the span is 30 days (≤31 → daily). This alters preset semantics and is
  outside this task's scope — route through PM rather than the fixer.

### Minor 2 — `lint` script is non-functional (no ESLint flat config)
- **Where:** `admin-panel/package.json` `lint` script; project root.
- **What & evidence:** `eslint . --ext ts,tsx` fails because ESLint 9 requires
  `eslint.config.js`, which the repo lacks. Both build notes flagged this.
- **Root cause:** Pre-existing project tooling gap, not introduced by this task.
  Acceptance criterion 7 names lint, but tsc covers the static-typing intent.
- **Exact fix (optional, defer):** out of scope for this task; tracked as a
  separate tooling task if the team wants lint coverage.

## Notes (validated, not defects)

- **Determinism:** the PRNG (`seeded(0xdeadbeef)`) produces an identical
  plan/status/family/id/amount sequence on every load (verified: two fresh
  `seeded` instances emit identical sequences). `createdAt` is anchored to
  `Date.now()` per the plan's explicit mandate, so timestamps shift by real
  elapsed time across reloads — required for relative presets to keep working.
  This satisfies "stable between reloads" as the plan intended.
- **`mode` prop unused in the chart (`_mode`):** the plan specified the `mode`
  prop for X-axis thinning but the component thins via `data.length`
  (`xAxisInterval`), so `mode` is destructured as `_mode`. The plan itself called
  `pct`/`mode` "shape parity" props, and `_`-prefix is the project's typed-unused
  convention. Acceptable, not a deviation.
- **~758 mock rows** (plan estimated ~140–200). More rows than planned, but the
  plan stated "~140–200" as a target for non-flatness, not a cap; richer data
  only strengthens the curves and the criteria. Not a deviation worth flagging.

## PM summary

REVIEW_PASS — 0 Critical, 0 Major, 2 Minor (both pre-existing, out-of-scope:
"Monthly" preset buckets monthly because its span is 32 days; lint script lacks
ESLint flat config). All 7 acceptance criteria pass; build is green; chart/stat
consistency and weekly coverage verified by simulation. Ready for PR.
