---
slug: kafi-revenue-trend-chart
project: Nannies app (Kafi admin)
title: Professional Recharts revenue-trend area chart on Revenue page, driven by enriched mock data
owner: developer
status: READY_FOR_REVIEW
updated: 2026-06-07
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
