---
slug: kafi-dashboard-revert-revenue-filters
project: kafi-admin-panel
title: Revert dashboard design (keep logic), add global period filters to Revenue page
owner: developer
status: READY_FOR_REVIEW
updated: 2026-06-07
---

# Build — kafi-dashboard-revert-revenue-filters

## Worktree branch

`worktree-agent-ac0b3ebbc2fac3052`

Note: The worktree branch is based on `2bb67f8` (initial commit). The feature
branch `feat/kafi-dashboard-revert-revenue-filters` exists at `d6c4423` with the
`ee8a1e3` + `23cb82d` commits on top. Git write operations (add/commit/merge) are
blocked in this sandbox session, so the WU1 implementation is written to the
worktree's working tree as an unstaged change. The diff is visible via
`git diff HEAD admin-panel/src/pages/Dashboard.tsx` in the worktree. The PM will
need to stage and commit, or merge the feature branch into this worktree.

---

## WU1 — `admin-panel/src/pages/Dashboard.tsx`

**Status:** READY_FOR_REVIEW

### What was implemented

The dashboard was rebuilt from the `d6c4423` feature-branch baseline (partial
revert with hardcoded revenue row). WU1 applies the three-step plan on top:

1. **`byPlan` state added** (line 166):
   `useState<{ plan: string; subs: number; revenue: number }[]>([])`.

2. **`setByPlan(rev.byPlan)` wired in `load()`** (line 187): added immediately
   after `setMonthlyVat(rev.vat)` inside the existing `Promise.all` resolution
   block. `rev` is the resolved `RevenueService.summary()` value already
   destructured in the array. No other changes to the load/error/finally flow.

3. **Hardcoded revenue row replaced with live-mapped RevCards** (lines 290-313):
   - `planMeta` constant defined at module scope (outside component): maps plan
     key to `{ label, color }` for the three fixed plans. Labels/prices are fixed
     business constants (89/239/369), not fetched data.
   - `maxRevenue` and `planOf()` computed inside the component body before the
     JSX return. `maxRevenue = Math.max(...byPlan.map(p => p.revenue), 1)` — the
     `1` guard prevents divide-by-zero when `byPlan` is empty on first render.
   - `Object.entries(planMeta).map(([key, meta]) => ...)` produces the three plan
     RevCards. `planOf(key)` looks up live data; `?? 0` ensures "AED 0" / "0
     active" when a plan has no transactions in the summary.
   - Loading state: `loading ? '—' : ...` for amount; `loading ? '' : ...` for sub.
   - VAT RevCard: uses live `monthlyVat`, `borderRose`, `pct={100}`, unchanged.
   - Grid wrapper `div className="grid grid-cols-2 lg:grid-cols-4 gap-2 px-[18px] pb-3"`
     is identical to the original layout — visual structure unchanged.

4. **Full `ee8a1e3` logic restored** from the feature branch baseline:
   - `exportCsv` import added from `../utils/csv`.
   - `TableCard` component upgraded with `actionTo?: string` and `onAction?: () => void`
     props, routing via `<Link to={actionTo}>` or `<button onClick={onAction}>`.
   - Four CSV export `onAction` handlers wired: nanny nationality, nanny-by-city,
     subscription breakdown, family nationality.
   - `"All nannies"` table: `actionTo="/nannies"`.
   - `"Recent family accounts"` table: `actionTo="/families"`.
   - `"Active trials"` table: `actionTo="/trials"`.
   - `newTodayCount` computed from `families.filter(f => f.createdAt && f.createdAt >= todayStart).length`
     (real date comparison against midnight today; replaces the `= 0` placeholder).

### Files changed

| File | Change |
| ---- | ------ |
| `admin-panel/src/pages/Dashboard.tsx` | WU1 implementation as described above |

### Files NOT touched (WU2 scope)

- `admin-panel/src/pages/business/Revenue.tsx` — untouched
- `admin-panel/src/services/firestore.ts` — untouched

---

## Build / type-check results

The sandbox environment blocked `npm install`, `npm run build`, `npx tsc --noEmit`
and all git write operations. Manual type review performed:

- All state types match `RevenueSummary.byPlan` shape from `firestore.ts` line 1373.
- `planOf` return type is `{ plan: string; subs: number; revenue: number } | undefined`;
  all access uses `?.` / `?? 0` — no unsafe narrowing.
- `maxRevenue` is always >= 1 (Math.max guard) — no division by zero.
- `planMeta` typed as `Record<string, { label: string; color: string }>` — correct
  for `Object.entries` usage.
- `exportCsv` generic infers from the `sorted` tuple arrays (`[string, number][]`)
  exactly as the feature branch's existing pattern does.
- `noUnusedLocals`/`noUnusedParameters` (strict tsconfig): all declared variables
  verified to be used in JSX.
- No new imports beyond `exportCsv` (which is already in the feature branch).

**Recommended reviewer action:** run `cd admin-panel && npm run build` (or
`tsc --noEmit`) after staging the worktree diff to confirm build green.

---

## Deviations from plan

None in logic or contracts. One process deviation only:

**Git write operations blocked in sandbox:** `git add`, `git commit`, `git merge`,
`git cherry-pick`, and `npm install`/`npm run build` were all denied by the
sandbox. The implementation is on disk as an unstaged modification. The PM should
stage + commit the single file:

```
git add admin-panel/src/pages/Dashboard.tsx
git commit -m "feat(WU1): kafi-dashboard-revert-revenue-filters — live byPlan/vat, ee8a1e3 logic"
```

**Worktree base commit mismatch:** This worktree started at `2bb67f8` (initial
commit), not `d6c4423` (feature branch HEAD). Rather than cherry-picking (blocked),
the WU1 implementation was written as a complete file incorporating both the
`ee8a1e3` baseline logic AND the WU1 additions — functionally equivalent to
applying the WU1 diff on top of `d6c4423`.

---

## Known gaps / follow-ups

- TypeScript build result unconfirmed (sandbox restriction). Manual review shows
  no type errors; reviewer should run `tsc --noEmit` to confirm.
- WU2 (Revenue.tsx + firestore.ts) is NOT implemented here — separate work unit
  per the plan, non-overlapping files.
