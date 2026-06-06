---
slug: kafi-listing-filters
project: Nannies app (Kafi admin)
title: Separate nationality / city / status dropdown filters on nannies and families listings
owner: project-manager
status: READY_FOR_BUILD
updated: 2026-06-07
---

# Scope: kafi-listing-filters

## Objective

Add **separate dropdown filters per filter type** to the admin-panel listing
screens, matching the dimensions shown in the Dashboard breakdowns
(nationality, city). Nanny screens (**All nannies** and **Verify documents**)
each gain a **Nationality** dropdown and a **City** dropdown alongside their
existing Status dropdown. The **All families** listing gains a **Nationality**
dropdown, a **City** dropdown, and a **Subscription status** dropdown; to host
them it adopts the same shared `FilterBar` pattern the nanny screens already
use (search + dropdowns in one bar) instead of its current lone header search
input. All dropdown options are derived dynamically from the loaded rows
(distinct values, alphabetical, with an "All" default), filters combine with
AND, and CSV export continues to export the filtered result.

## Modules & flows affected

- `admin-panel/src/pages/nannies/AllNannies.tsx` — add Nationality + City
  `FilterSelect`s; extend `extraFilter` in `useListControls`; reset them in
  `onClear`.
- `admin-panel/src/pages/nannies/VerifyDocuments.tsx` — same Nationality + City
  `FilterSelect`s added to its existing `FilterBar`/`useListControls`.
- `admin-panel/src/pages/families/AllFamilies.tsx` — migrate from header search
  input to the shared `FilterBar` + `useListControls` pattern; add Nationality,
  City, and Subscription-status `FilterSelect`s; keep block/unblock, stats,
  CSV export, and row rendering unchanged.
- `admin-panel/src/components/ui/ListControls.tsx` and
  `admin-panel/src/hooks/useListControls.ts` — reuse as-is; small shared
  helper for "distinct option list from rows" may be added if the architect
  prefers (single utility, no new patterns).

## Work breakdown

| WU | Description | Files | Mode |
| -- | ----------- | ----- | ---- |
| WU1 | Nationality + City dropdowns on All nannies + Verify documents | `pages/nannies/AllNannies.tsx`, `pages/nannies/VerifyDocuments.tsx` | INDEPENDENT |
| WU2 | All families: FilterBar migration + Nationality / City / Subscription-status dropdowns | `pages/families/AllFamilies.tsx` | INDEPENDENT |

Shared "distinct options" helper (if the architect specifies one) goes in ONE
work unit's file set (architect assigns) to keep partitions non-overlapping.

## Acceptance criteria

- [ ] All nannies: separate Nationality and City dropdowns next to the existing
      Status dropdown; each defaults to "All"; selections combine with AND
      (with each other, status, search, and date range); Clear resets all.
- [ ] Verify documents: same Nationality and City dropdowns wired into its
      existing filter bar; AND semantics; Clear resets all.
- [ ] All families: shared `FilterBar` replaces the lone header search input;
      separate Nationality, City, and Subscription-status dropdowns; search
      still matches name/nationality/city; AND semantics; Clear resets all.
- [ ] Dropdown options are derived from the loaded data (distinct, sorted,
      "All …" first) — no hardcoded nationality/city lists.
- [ ] Empty-state messages show when filters match nothing; CSV export exports
      exactly the filtered rows on all three screens.
- [ ] Existing behavior preserved: status filter (nannies), stats cards,
      block/unblock, pagination, row rendering, navigation links.
- [ ] Design matches existing `FilterBar`/`FilterSelect` styling — no new
      visual patterns or one-off styles.
- [ ] `npm run build` (tsc + vite) passes; no `any`; no new dependencies.

## Out of scope

- Dashboard breakdown cards (read-only; they only informed the filter
  dimensions).
- Nanny/Family detail pages, Subscriptions, Disputes, Trials screens.
- Server-side/Firestore query filtering (filtering stays client-side on the
  already-loaded list, consistent with current pattern).
- New filter types beyond nationality, city, and family subscription status.
- Multi-select dropdowns (single-select per dropdown, like existing Status).

## Risks / open questions

- AllFamilies currently lacks `useListControls`; migration adds a date filter
  visually as part of `FilterBar` — architect to decide whether to wire it to
  `createdAt` (if available on `FamilyRow`) or configure the bar without the
  date inputs if the data doesn't support it.
- Mock family data may have few distinct nationalities/cities; acceptable —
  dropdowns reflect real data.
