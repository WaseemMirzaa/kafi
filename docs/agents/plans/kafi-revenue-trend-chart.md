---
slug: kafi-revenue-trend-chart
project: Nannies app (Kafi admin)
title: Professional Recharts revenue-trend area chart on Revenue page, driven by enriched mock data
owner: architect
status: READY_FOR_BUILD
updated: 2026-06-07
---

# Plan: kafi-revenue-trend-chart

## 0. Source read (done before planning)

- `admin-panel/src/pages/business/Revenue.tsx` — full read. The trend is already
  computed by `buildRangeTrend(paid, from, to)` into
  `{ label, amount, pct }[]`, exposed as `derived.trend` with `derived.hasTrendData`.
  It is rendered inside the `<TableCard title="Revenue trend">` block at lines
  268–286 as a flex column of div bars using `bg-gradient-to-t from-rose-dark to-rose`
  with the empty-state string "No data for selected period." at line 271.
- `admin-panel/src/services/firestore.ts` — `RevenueTransaction` interface (lines
  1380–1388), `mockTransactions` array (lines 1390–1401, 10 rows spanning ~5
  months relative to `Date.now()`), `buildTrend()` helper (lines 1403–1427, used
  only by `RevenueService.summary()` mock branch — NOT by the Revenue page),
  `RevenueService.allTransactions()` (the method the page calls; mock branch
  returns `[...mockTransactions]` sorted desc). `useMock()` gate at line 19.
- `admin-panel/src/components/charts/` — empty.
- `recharts` resolves to installed `2.15.4` (satisfies `^2.12.7`). No new dep.
- Design tokens confirmed in `tailwind.config.js`: `rose.DEFAULT #FF8FAB`,
  `rose.dark #FF5C8A`, `navy #1E2A4A`; muted text `#8090B0`, border `#EBEEF8`,
  track `#F0F1FA` (per memory). The existing bar gradient is rose-dark→rose.

**Code practice verdict: SOUND.** The page already separates data derivation
(`buildRangeTrend` + the `derived` memo) from presentation (the div-bar block).
Swapping the presentation for a Recharts component is a clean, contained change
with no refactor required. No scope risk to escalate.

---

## 1. Architecture summary

- **WU1** introduces one presentational component,
  `components/charts/RevenueTrendChart.tsx`, that takes the *already-computed*
  `derived.trend` array (`{ label, amount, pct }[]`) plus a bucket-mode hint and
  renders a Recharts `AreaChart`. It owns zero data logic — all bucketing stays
  in `Revenue.tsx`'s `buildRangeTrend`. Data flow is unchanged:
  `allTransactions() → inRange memo → derived memo (buildRangeTrend) → chart`.
  Switching Period/dates already re-runs `derived`, so the chart re-renders for
  free. The only edit to `Revenue.tsx` is replacing the div-bar JSX (lines
  273–283) with `<RevenueTrendChart …>` and passing the bucket mode.
- **WU2** only enlarges the `mockTransactions` literal so the same pipeline has
  ~12 months of dense, deterministic history. No new function, no signature
  change, no live-path touch.
- New module boundary: `components/charts/` becomes the home for chart
  primitives. We add exactly one component now (no speculative shared abstraction
  — out of scope per the scope doc).
- WU1 and WU2 edit **disjoint files** (`Revenue.tsx` + new chart file vs.
  `firestore.ts`) and are therefore `INDEPENDENT` / parallelizable.

---

## 2. Reuse map

- **Bucketing logic:** reuse the existing `buildRangeTrend` in `Revenue.tsx`
  exactly — do NOT duplicate it in the chart. The chart consumes its output.
- **Empty state:** keep the existing conditional and string
  `"No data for selected period."` in `Revenue.tsx` (do not move it into the
  chart) so behavior is identical to today.
- **Design tokens (mandatory — no new colors):**
  - Gradient fill: `rose.dark #FF5C8A` (top, ~0.35 opacity) → `rose.DEFAULT #FF8FAB`
    (bottom, ~0 opacity), matching the current `from-rose-dark to-rose` bar.
  - Line/stroke: `#FF5C8A` (`rose.dark`).
  - Axis tick text + tooltip muted text: `#8090B0`.
  - Grid / axis lines: `#EBEEF8` (card border token).
  - Tooltip container: white bg, `1px solid #EBEEF8`, `rounded-lg`, navy
    (`#1E2A4A`) value text — match `TableCard`/`Row` visual language.
  - Font: inherit the app font (Fredoka via Tailwind) — set tick `fontSize: 8`
    and tooltip text via inline style classes using the same `text-[8px]` /
    `text-[10px]` scale used elsewhere on the page.
- **Card wrapper:** reuse the existing `<TableCard title="Revenue trend">` — the
  chart renders *inside* it; do not add a second card or border.
- **AED formatting:** reuse the page's existing `Number.toLocaleString()` idiom
  (e.g. `AED ${v.toLocaleString()}`); Y-axis uses a compact formatter (see WU1).

---

## 3. File-by-file change list

### WU1 — Chart component + page integration

#### CREATE `admin-panel/src/components/charts/RevenueTrendChart.tsx`

A typed, presentational Recharts area chart. No data access, no hooks beyond
render.

**Props (exact contract — developer invents nothing):**

```ts
export interface TrendPoint {
  label: string;   // bucket label, e.g. "07/06" (daily) or "Jun 2026" (monthly)
  amount: number;  // AED total for the bucket
  pct: number;     // 0..100 (already computed by buildRangeTrend; unused by chart but kept for shape parity)
}

export interface RevenueTrendChartProps {
  data: TrendPoint[];
  /** Bucket granularity, used only to thin X-axis labels. */
  mode: 'daily' | 'monthly';
}
```

**Implementation requirements:**

- Default export `RevenueTrendChart`. Use named Recharts imports:
  `ResponsiveContainer, AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip,
  defs`-via-JSX (`<defs><linearGradient/></defs>`).
- Fixed height container: wrap in a `<div className="h-40 w-full">` (matches the
  current `h-40` block) and a `<ResponsiveContainer width="100%" height="100%">`.
- `<AreaChart data={data} margin={{ top: 8, right: 8, left: -8, bottom: 0 }}>`.
- `<defs>` with `<linearGradient id="revTrendFill" x1="0" y1="0" x2="0" y2="1">`:
  stop 0% `#FF5C8A` stopOpacity 0.35, stop 100% `#FF8FAB` stopOpacity 0.
- `<CartesianGrid vertical={false} stroke="#EBEEF8" strokeDasharray="3 3" />`.
- `<XAxis dataKey="label" tick={{ fontSize: 8, fill: '#8090B0' }}
  tickLine={false} axisLine={{ stroke: '#EBEEF8' }} interval={xAxisInterval}
  minTickGap={8} />` where `xAxisInterval` is computed to thin labels on long
  ranges: `const xAxisInterval = data.length > 14 ? Math.ceil(data.length / 12) - 1 : 0;`
  (guarantees ≤ ~12 visible ticks; handles long custom daily/monthly ranges so
  the axis never overflows — addresses the scope risk).
- `<YAxis tick={{ fontSize: 8, fill: '#8090B0' }} tickLine={false}
  axisLine={false} width={34} tickFormatter={compactAed} />` where `compactAed`
  is a module-level pure function:
  `(v: number) => v >= 1000 ? \`\${(v / 1000).toFixed(v % 1000 === 0 ? 0 : 1)}k\` : String(v)`.
- `<Tooltip content={<TrendTooltip />} cursor={{ stroke: '#EBEEF8' }} />` — use a
  **custom tooltip component** (see below) so we control formatting and styling
  with our tokens; do NOT use the default tooltip.
- `<Area type="monotone" dataKey="amount" stroke="#FF5C8A" strokeWidth={2}
  fill="url(#revTrendFill)" dot={false} activeDot={{ r: 3, fill: '#FF5C8A' }}
  isAnimationActive={false} />` — `isAnimationActive={false}` keeps render
  deterministic and avoids console-noise/test flakiness; smooth curve via
  `type="monotone"` satisfies the "smooth curve" criterion.
- **Custom tooltip** — local component inside the file:

  ```tsx
  function TrendTooltip({ active, payload, label }: TooltipProps<number, string>) {
    if (!active || !payload || payload.length === 0) return null;
    const amount = payload[0].value ?? 0;
    return (
      <div className="rounded-lg border border-[#EBEEF8] bg-white px-2 py-1 shadow-sm">
        <div className="text-[8px] font-bold text-[#8090B0]">{label}</div>
        <div className="text-[10px] font-extrabold text-navy">
          AED {Number(amount).toLocaleString()}
        </div>
      </div>
    );
  }
  ```

  Import `TooltipProps` type from `recharts` so it is fully typed (no `any`).
- **Typing:** no `any` anywhere. `compactAed` and `TrendTooltip` are typed.
- **Edge cases:** the component does not handle empty data — the page only
  mounts it when `derived.hasTrendData` is true (empty state stays in the page).
  Still, guard the tooltip (`payload.length === 0`) as above. A single data
  point renders a flat short area without error (acceptable).

#### MODIFY `admin-panel/src/pages/business/Revenue.tsx`

1. **Import** the new component (top, with the other component imports):
   `import RevenueTrendChart from '../../components/charts/RevenueTrendChart';`
2. **Expose bucket mode from the derive step.** `buildRangeTrend` already
   branches on `spanDays <= 31`. Surface that decision so the chart can thin
   labels correctly. Two acceptable approaches — implement **Approach A** (least
   invasive):
   - **Approach A (required):** add a tiny pure helper next to `buildRangeTrend`:

     ```ts
     /** Bucket granularity for a given inclusive range (mirrors buildRangeTrend). */
     function trendMode(from: string, to: string): 'daily' | 'monthly' {
       if (!from || !to) return 'monthly';
       const fromMs = new Date(from).getTime();
       const toMs = new Date(to).getTime() + 86400000 - 1;
       const spanDays = Math.max(1, Math.round((toMs - fromMs) / 86400000));
       return spanDays <= 31 ? 'daily' : 'monthly';
     }
     ```

     Then in the `derived` memo, add `const mode = trendMode(from, to);` and
     include `mode` in the returned object alongside `trend`/`hasTrendData`.
     Map it to the component prop: `mode === 'daily' ? 'daily' : 'monthly'`.
   - Do not refactor `buildRangeTrend` itself; the duplicated 3-line span calc is
     acceptable and intentionally kept local for WU isolation. (Note in review:
     this is a deliberate, minimal mirror, not accidental duplication.)
3. **Replace the div-bar block.** In the `<TableCard title="Revenue trend">`
   body (current lines 269–285), keep the outer `<div className="px-[11px] py-4">`
   and the `!derived.hasTrendData` empty-state branch (unchanged string
   "No data for selected period."). Replace only the `else` branch (the
   `<div className="h-40 flex items-end gap-2 overflow-x-auto">…</div>` mapping)
   with:

   ```tsx
   <RevenueTrendChart data={derived.trend} mode={derived.mode} />
   ```

4. No other change to `Revenue.tsx` — stat cards, plan split, transactions
   table, filters, CSV export untouched.

**Error/edge handling for this file:** unchanged. Loading and `error` states
already handled. Empty range still shows the empty-state string.

### WU2 — Mock data enrichment

#### MODIFY `admin-panel/src/services/firestore.ts` (mock block only)

Replace the `mockTransactions` array literal (lines 1390–1401) with a
**deterministic generator** producing ~12 months of history. Do NOT touch the
`RevenueTransaction` interface, `buildTrend`, `RevenueService` methods, or any
live/Firestore path.

**Requirements:**

- **Deterministic, not random-per-load.** Use a fixed seed and a small pure PRNG
  (mulberry32-style) so the same rows render on every reload — the scope
  explicitly forbids random-per-load. Anchor all dates to `Date.now()` at module
  load via day offsets (the page filters by relative presets, so dates must be
  relative to "now", consistent with the existing rows).

  ```ts
  // Deterministic PRNG so mock revenue is stable across reloads.
  function seeded(seed: number): () => number {
    let a = seed >>> 0;
    return () => {
      a |= 0; a = (a + 0x6d2b79f5) | 0;
      let t = Math.imul(a ^ (a >>> 15), 1 | a);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }
  ```

- **Generation shape:** build `mockTransactions` by iterating day offsets from
  365 down to 0. Target ~140–200 total rows so all three presets are non-flat:
  - **Weekly (last 7 days):** guarantee coverage — force at least one `paid` row
    on each of day offsets 0..6 (scope risk: weekly was often empty). Use the
    PRNG to pick plan/amount, but the *presence* of a row in the last 7 days is
    guaranteed, not probabilistic.
  - **Monthly (last 30 days):** dense — roughly 0–2 rows/day so the daily-bucket
    monthly view shows a varied curve.
  - **Yearly (12 months):** ensure every one of the last 12 calendar months has
    several rows with month-to-month variation (a mild upward trend is fine and
    realistic) so the monthly-bucket curve is clearly non-flat.
  - **Plan mix:** weekly (89), monthly (239), twoMonths (369) AED — amounts MUST
    match the plan price (consistency with plan-split + stat cards). Pick plan
    via PRNG weighting (e.g. ~45% monthly, ~35% weekly, ~20% twoMonths).
  - **Status mix:** mostly `paid`; sprinkle a few `refunded` and `failed`
    (~5–8% each) via PRNG. The forced last-7-day rows must be `paid` (so the
    weekly *paid* curve — what the chart uses — is non-empty).
  - **familyId/familyName:** reuse the existing small family roster already in
    the array (`f1` Al Mansoori Family, `f2` James & Sarah K., `f3` Lin Chen,
    `f4` Mohammed Al Rashid). Pick via PRNG. Keep `familyId`↔`familyName` pairing
    consistent (define a const lookup array of the 4 families and index it).
  - **id:** stable unique string per row, e.g. `tx${index}` from the generation
    loop counter (must be unique — used as React `key` in the txns table).
  - **createdAt:** `new Date(Date.now() - dayOffset * 86400000)` (optionally jitter
    the time-of-day deterministically; not required).

- **Implementation note:** define the generator as a module-level IIFE or a
  named function called once to initialize the `const mockTransactions:
  RevenueTransaction[]`. Keep it fully typed (`RevenueTransaction[]`), no `any`.
  Place the `seeded` helper and family roster const directly above the
  `mockTransactions` declaration (so WU2 stays within the mock block region and
  does not collide with WU1's files).

- **Do NOT change** `buildTrend`'s default `months = 6` or the
  `RevenueService.summary()` mock literal — those feed the Dashboard summary,
  which is out of scope. (They will simply aggregate more rows, which is fine and
  expected per the scope's "may display more mock rows".)

**Error/edge handling:** generator is pure and total; no external input to
validate. Guarantee no duplicate `id`s (loop counter ensures uniqueness).

---

## 4. Work units & parallelization

| WU  | Files                                                                                 | Mode          | Depends on |
| --- | ------------------------------------------------------------------------------------- | ------------- | ---------- |
| WU1 | CREATE `components/charts/RevenueTrendChart.tsx`, MODIFY `pages/business/Revenue.tsx` | `INDEPENDENT` | —          |
| WU2 | MODIFY `services/firestore.ts` (mock block only)                                      | `INDEPENDENT` | —          |

No file overlap → safe to build in parallel in separate worktrees, then merge.
WU1 is testable on its own against the existing 10-row mock (curve will be
sparse but correct); WU2 makes it visually rich. Final acceptance runs both
merged.

---

## 5. Refactor callouts

None. Existing separation of data (memo + `buildRangeTrend`) and presentation is
sound; the change slots into it cleanly. The one deliberate 3-line mirror
(`trendMode`) is intentional WU-isolation, called out so review does not flag it
as accidental duplication.

---

## 6. Test plan

Manual (mock mode is the demo path; project has no chart unit tests):

1. **Build/lint gate (blocking):** `npm run build` (tsc + vite) passes;
   `npm run lint` passes on `RevenueTrendChart.tsx`, `Revenue.tsx`,
   `firestore.ts`. No `any`, no unused imports.
2. **Weekly preset:** select Period → Weekly. Chart shows a non-flat area over
   ~7 daily buckets (DD/MM labels). No "No data" message.
3. **Monthly preset:** ~30 daily buckets, varied curve, DD/MM labels, X-axis
   thinned (≤ ~12 visible ticks, no overlap).
4. **Yearly preset:** 12 monthly buckets (MMM YYYY), clearly non-flat / trending.
5. **Custom range >31 days:** monthly bucketing; very long range thins labels and
   does not overflow the X-axis.
6. **Consistency:** sum of chart buckets equals the "Revenue in range" stat card
   (both derive from the same `derived.paid`). Spot-check one preset.
7. **Tooltip:** hover shows bucket label + `AED X,XXX` (thousands separator),
   navy value text, rose active dot, white bordered container.
8. **Empty state:** pick a custom range with no paid txns (e.g. far-future
   dates) → "No data for selected period." renders, no chart, no console error.
9. **Determinism:** reload twice on the same preset → identical curve.
10. **Console clean:** no Recharts warnings/errors in devtools.

## 7. Definition of done (gradable checklist)

- [ ] `RevenueTrendChart.tsx` created in `components/charts/`, default export,
      typed `RevenueTrendChartProps` (`data: TrendPoint[]`, `mode`), no `any`.
- [ ] Recharts `AreaChart` in `ResponsiveContainer`, `type="monotone"` smooth
      curve, gradient fill `#FF5C8A → #FF8FAB` (rose tokens), 2px rose-dark
      stroke, `dot={false}`, rose `activeDot`.
- [ ] Custom tooltip: bucket label + `AED X,XXX`, navy value, `#EBEEF8` border,
      white bg; muted `#8090B0` ticks; `#EBEEF8` grid; compact `k` Y-axis;
      X-axis label thinning via computed `interval` for long ranges.
- [ ] `Revenue.tsx` renders `<RevenueTrendChart data={derived.trend}
      mode={derived.mode} />` inside the existing `Revenue trend` `TableCard`,
      replacing the div-bar block; `trendMode` helper added; empty-state string
      "No data for selected period." preserved; stat cards / plan split /
      transactions table / filters / CSV export unchanged.
- [ ] Chart re-renders on Period (weekly/monthly/yearly/custom) and from/to
      changes; chart totals consistent with "Revenue in range".
- [ ] `mockTransactions` enriched to ~12 months via a **deterministic** seeded
      generator: last-7-days paid coverage guaranteed; every recent month
      populated; plan amounts match prices (89/239/369); mostly paid with a few
      refunded/failed; unique `id`s; `familyId`↔`familyName` consistent.
- [ ] `RevenueTransaction` interface, `buildTrend`, `RevenueService` methods, and
      all live Firestore paths unchanged.
- [ ] No new dependency added. `npm run build` and `npm run lint` pass; no
      console errors/warnings.
