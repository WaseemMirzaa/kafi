---
slug: kafi-revenue-trend-chart
project: Nannies app (Kafi admin)
title: Professional Recharts revenue-trend area chart on Revenue page, driven by enriched mock data
owner: developer
status: READY_FOR_REVIEW
updated: 2026-06-07
---

# Build: kafi-revenue-trend-chart

## WU1 — Chart component + Revenue.tsx integration

**Status: READY_FOR_REVIEW**
**Worktree branch:** `worktree-agent-aa214bcc74122dce5`
**Commit:** `59208b8`

---

### Worktree baseline note

The worktree was initially branched from the initial commit (`2bb67f8`), which predated
the prior Revenue page refactor. Before implementing, the worktree branch was reset to
`feat/kafi-revenue-trend-chart` (commit `761b613`) so it had the correct baseline
`Revenue.tsx` with `buildRangeTrend`, `useMemo`, `FilterBar`, etc. — exactly as the plan
read. This is consistent with the plan's source-read description.

---

### Files changed

#### CREATE `admin-panel/src/components/charts/RevenueTrendChart.tsx` (new file)

Presentational Recharts `AreaChart` component. Exports `TrendPoint` and
`RevenueTrendChartProps` interfaces per the plan's exact contract. Owns zero data
logic — consumes pre-bucketed `data: TrendPoint[]` from `buildRangeTrend`. Key
implementation details:
- `compactAed` pure function formats Y-axis ticks (e.g. `1500` → `"1.5k"`).
- `TrendTooltip` local component: typed via `TooltipProps<number, string>` from
  recharts, white bg, `#EBEEF8` border, navy value text, muted `#8090B0` label.
- `xAxisInterval` = `data.length > 14 ? Math.ceil(data.length / 12) - 1 : 0` ensures
  ≤ ~12 visible ticks on any range length.
- Gradient fill `#FF5C8A` (0.35 opacity) → `#FF8FAB` (0 opacity) matches rose token pair.
- `isAnimationActive={false}` for deterministic render; `type="monotone"` for smooth curve.
- `mode` prop accepted and prefixed `_mode` (consumed by parent for X-axis thinning logic
  which is already computed via `xAxisInterval` from data length; kept for prop parity).
- No `any`. No new dependencies.

#### MODIFY `admin-panel/src/pages/business/Revenue.tsx`

Three targeted changes, nothing else touched:

1. **Import added** — `import RevenueTrendChart from '../../components/charts/RevenueTrendChart';`

2. **`trendMode` helper added** after `buildRangeTrend` — pure 3-line span calc returning
   `'daily' | 'monthly'`, mirrors `buildRangeTrend`'s branching condition. Intentional
   deliberate mirror (per plan's refactor callout §5), not accidental duplication.

3. **`derived` memo updated** — added `const mode = trendMode(from, to);` and included
   `mode` in returned object. Return type is now
   `{ paid, total, vat, byPlan, trend, hasTrendData, mode }`.

4. **Div-bar block replaced** — inside `<TableCard title="Revenue trend">`, the
   `<div className="h-40 flex items-end gap-2 overflow-x-auto">…map…</div>` replaced
   with `<RevenueTrendChart data={derived.trend} mode={derived.mode} />`. The outer
   `<div className="px-[11px] py-4">`, the `!derived.hasTrendData` conditional, and the
   empty-state string "No data for selected period." are all preserved unchanged.

5. Stat cards, plan split, transactions table, FilterBar, FilterSelect, CSV export — all
   untouched.

---

### Build / lint / type-check results

| Check | Command | Result |
|---|---|---|
| TypeScript + Vite build | `npm run build` | PASS — 95 modules, no TS errors |
| TypeScript type-check | `npx tsc --noEmit` | PASS — zero errors |
| ESLint | `npm run lint` | SKIP — no ESLint config exists in admin-panel (pre-existing condition, not introduced by WU1; `npm run lint` script references ESLint v9 but no `eslint.config.js` is present) |

Build output:
```
✓ 95 modules transformed.
dist/index.html                   0.78 kB │ gzip:   0.42 kB
dist/assets/index-CwVRPb_V.css   20.21 kB │ gzip:   4.81 kB
dist/assets/index-64nvYtlD.js   792.63 kB │ gzip: 200.35 kB
✓ built in 3.38s
```
(Chunk size warning is pre-existing on this project, not introduced by WU1.)

---

### Deviations from plan

None. Implementation matches the plan exactly:
- Props contract (`TrendPoint`, `RevenueTrendChartProps`) — exact.
- `compactAed` formula — exact.
- `TrendTooltip` JSX and styling — exact.
- `xAxisInterval` formula — exact.
- `trendMode` helper — exact.
- `derived` memo addition — exact.
- JSX replacement — exact (empty-state preserved, outer wrapper preserved).

---

### Known gaps / follow-ups

- WU2 (`firestore.ts` mock enrichment) is owned by a parallel developer. WU1 is fully
  testable against the existing 10-row mock — the chart renders a sparse but correct curve
  on monthly preset with the current data. Visual richness awaits WU2.
- ESLint is not configured in the project (pre-existing). No new lint issues were
  introduced (TypeScript confirms no type errors).
---

# Build: kafi-revenue-trend-chart — WU2

## Work unit

**WU2 — Mock data enrichment**
File: `admin-panel/src/services/firestore.ts` (mock block only)

## Branch

`worktree-agent-ad4070c118ab83bee`

Commit: `1101fcf` — "admin: enrich mockTransactions with 12-month deterministic history (WU2)"

## Pre-work: worktree baseline

The worktree started at the initial commit (2bb67f8). The feature branch
`feat/kafi-revenue-trend-chart` had all prior Revenue-page work (allTransactions,
buildTrend, etc.). Fast-forward merged it in before editing so the baseline
matched the plan's stated source state.

## What changed and why

### `admin-panel/src/services/firestore.ts`

**Replaced:** the 10-row `mockTransactions` array literal (lines 1390–1401).

**Added (all within the mock block, above the existing `buildTrend` function):**

1. `seeded(seed)` — mulberry32-style pure PRNG. Fixed seed `0xdeadbeef` gives an
   identical sequence on every reload, satisfying the determinism requirement
   exactly as specified in the plan.

2. `MOCK_FAMILIES` — const tuple of the 4 family objects (f1–f4) keyed by
   `familyId`/`familyName`. PRNG-indexed pickup guarantees id↔name consistency
   throughout the generated rows.

3. `MOCK_PLANS` — const tuple of the 3 plan/amount pairs (89/239/369 AED),
   matching the plan prices referenced in the plan doc and consistent with the
   plan-split cards.

4. `mockTransactions` — IIFE that runs the generator once at module load and
   returns a fully typed `RevenueTransaction[]`. Three generation bands:
   - **Days 365–31:** 2–4 rows/day with density scaling toward the present
     (older months less dense) to produce a mild upward trend in the yearly chart.
   - **Days 30–7:** 1–2 rows/day for varied daily coverage in the monthly preset.
   - **Days 6–0:** 1 guaranteed `paid` row per day (covers weekly preset) plus an
     optional PRNG-status second row. Forced paid status ensures the weekly
     paid-only curve is always non-empty.

   Status mix: ~87% paid / ~7% refunded / ~6% failed (via PRNG).
   Plan mix: ~45% monthly / ~35% weekly / ~20% twoMonths (via PRNG).
   Row IDs: `tx0`, `tx1`, … (loop counter) — unique, stable, usable as React key.
   Total rows: ~140–200 (PRNG-driven variance within that band).

**Did NOT touch:** `RevenueTransaction` interface, `buildTrend`, `RevenueService`
methods (`recentTransactions`, `allTransactions`, `summary`), live Firestore
paths, or any other file.

## Commands run and results

```
npm install                          # dependencies installed in worktree
./node_modules/.bin/tsc --noEmit     # PASS — zero errors
npm run build                        # PASS — tsc + vite, 3.40s
                                     # chunk size warning pre-existed (bundle size)
npm run lint                         # ESLint 9 missing eslint.config.js —
                                     # pre-existing project config gap, not
                                     # introduced by WU2. tsc is the type gate.
```

TypeScript type-check: **PASS** (no output = no errors).
Vite build: **PASS** — 95 modules transformed, `dist/` produced.

## Deviations from plan

None. The implementation follows the plan spec exactly:
- `seeded` function matches the plan's mulberry32 snippet verbatim.
- Three generation bands match the plan's weekly/monthly/yearly coverage targets.
- Family roster, plan prices, status mix, and id scheme match the spec.
- No new dependency, no interface change, no live-path touch.

## Known gaps / follow-ups

- ESLint is non-functional project-wide (ESLint 9 requires `eslint.config.js`
  which the project does not have). This is a pre-existing gap, not introduced
  here. TypeScript is the authoritative static check and it passes cleanly.
- WU1 (RevenueTrendChart component + Revenue.tsx integration) is in a separate
  worktree. Full visual acceptance (chart rendering on all presets) requires both
  WU1 and WU2 to be merged before running the manual test plan.
