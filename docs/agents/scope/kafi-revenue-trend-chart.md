---
slug: kafi-revenue-trend-chart
project: Nannies app (Kafi admin)
title: Professional Recharts revenue-trend graph on Revenue page, driven by enriched mock data
owner: project-manager
status: PR_OPEN
updated: 2026-06-07
---

# Scope: kafi-revenue-trend-chart

## Objective

Replace the current div-based "Revenue trend" bar visual on the admin-panel
Revenue page with a professional Recharts **area chart** (brand-rose gradient
fill, smooth curve, hover tooltip with `AED X,XXX` formatting, clean axes) that
re-renders from the same filtered transaction data the page already derives —
so it changes correctly when the Period preset (weekly / monthly / yearly /
custom) or the from/to date range changes. To make the chart meaningful in mock
mode, enrich `mockTransactions` in the mock service layer with ~12 months of
realistic transaction history so the chart, stat cards, plan split, and recent
transactions table all stay mutually consistent and react to the filters
together.

## Modules & flows affected

- `admin-panel/src/pages/business/Revenue.tsx` — swap the div-bar trend block
  inside the "Revenue trend" `TableCard` for the new chart component; keep the
  existing `buildRangeTrend` bucketing (daily ≤31-day span, monthly otherwise)
  or refine it per the architect's plan. Filters, stat cards, plan split, and
  transactions table logic stay as-is.
- `admin-panel/src/components/charts/` — currently empty; new
  `RevenueTrendChart` component lives here (Recharts `AreaChart`, typed props).
- `admin-panel/src/services/firestore.ts` — enrich `mockTransactions` (mock
  layer only; no change to the live Firestore query path or the
  `RevenueTransaction` shape). Data spans ~12 months with a realistic mix of
  plans (weekly/monthly/twoMonths) and statuses (mostly paid, a few
  refunded/failed), dense enough that weekly, monthly, and yearly views each
  show a non-flat curve.

## Work breakdown

| WU | Description | Files | Mode |
| -- | ----------- | ----- | ---- |
| WU1 | `RevenueTrendChart` Recharts component + integrate into Revenue page trend card | `components/charts/RevenueTrendChart.tsx`, `pages/business/Revenue.tsx` | INDEPENDENT |
| WU2 | Enrich `mockTransactions` with ~12 months of realistic data | `services/firestore.ts` (mock block only) | INDEPENDENT |

WU1 and WU2 touch disjoint files → parallelizable (two developers, worktrees).

## Acceptance criteria

- [ ] "Revenue trend" card renders a Recharts area chart: rose-gradient fill
      matching existing design tokens (`from-rose-dark to-rose` palette), smooth
      monotone curve, X-axis labels (DD/MM daily or MMM YYYY monthly), Y-axis
      with compact AED values, hover tooltip showing the bucket label and
      `AED X,XXX`.
- [ ] Chart data is derived from the same filtered `paid` transactions the
      stat cards use — switching Period to weekly/monthly/yearly or editing the
      custom from/to dates visibly changes the chart, and chart totals are
      consistent with the "Revenue in range" stat.
- [ ] Empty state preserved: "No data for selected period." when no paid
      transactions fall in range.
- [ ] Mock mode shows a meaningful, non-flat curve on **all three** presets
      (weekly, monthly, yearly).
- [ ] Mock enrichment touches only the mock data block — live Firestore path,
      `RevenueTransaction` type, CSV export, plan split, and transactions table
      logic unchanged (they may *display* more mock rows, which is expected).
- [ ] No new dependencies (recharts ^2.12.7 already installed); chart is typed
      (no `any`), responsive (`ResponsiveContainer`), and renders without
      console errors.
- [ ] `npm run build` (tsc + vite) passes; `npm run lint` passes on changed files.

## Out of scope

- Dashboard page charts (this is Revenue page only).
- Live Firestore data changes, backend/cloud functions, indexes.
- New filter options or changes to FilterBar/FilterSelect behavior.
- Plan-split or transactions-table redesign.
- Charts elsewhere in the admin panel (no speculative shared chart library
  beyond the one component).

## Risks / open questions

- Sparse old mock data meant weekly view was often empty — enrichment must
  guarantee recent-7-day coverage (architect to specify deterministic
  generation, not random-per-load, so the UI is stable between reloads).
- Recharts is in package.json but unused so far — first usage may surface
  bundle/TS config quirks; build check in acceptance criteria covers this.
- Custom ranges >31 days bucket monthly; very long custom ranges should not
  overflow the X-axis (label thinning via Recharts `interval` handles this).
