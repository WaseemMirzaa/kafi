---
slug: kafi-listing-filters
project: Nannies app (Kafi admin)
title: Separate nationality / city / status dropdown filters on nannies and families listings
owner: architect-reviewer
status: REVIEW_PASS
updated: 2026-06-07
---

# Review: kafi-listing-filters

## Verdict

**REVIEW_PASS** (re-review after fix round 1) — 0 Critical, 0 Major, 0 Minor.
Implementation matches the plan and all 8 acceptance criteria pass.

The single Major from round 1 (dead "Joined" date filter on AllFamilies) is
genuinely resolved. Re-review trace below; original round-1 analysis retained
under "Findings" for the record.

### Re-review verification (round 1 fix)
- `getDate: (f) => f.createdAt` is present in AllFamilies' `useListControls`
  options (line 81). ✔
- No cast/`any` introduced — `grep` for `as any|as Date|: any|<any>` in the file
  returns nothing; `FamilyRow.createdAt` is `Date | undefined` (firestore.ts line
  153), matching `getDate?: (item: T) => Date | undefined` (useListControls.ts
  line 7) exactly. ✔
- Date filtering is now live: with `getDate` set, the hook's date branch
  (useListControls.ts lines 29–34) evaluates `from`/`to` against `createdAt`, so
  the "Joined from/to" inputs in `FilterBar` actually filter families. ✔
- No regression in the rest of the file — re-read confirms the WU2 migration is
  otherwise byte-for-byte the version that already passed (dropdowns, `extraFilter`
  AND semantics, search over name/nationality/city, stats over `items`,
  `Pagination`, empty state, CSV reads `lc.filtered`, block/trial/View). ✔
- `cd admin-panel && npm run build` clean: tsc 0 errors, 893 modules transformed,
  only the pre-existing chunk-size warning. ✔

Reviewed the integrated branch `feat/kafi-listing-filters` (both WUs merged,
commits `1e6af1e` + `07a301b`, plus the round-1 fix). Read all four changed files
against the plan and verified the data layer (`firestore.ts`) directly.

---

## Plan adherence — file by file

### `components/ui/ListControls.tsx` — PASS
`distinctOptions<T>` matches the plan's signature, body, and placement exactly
(generic, pure, "all" first, distinct + locale-`base`-sorted, skips
null/undefined/whitespace). No `any`. No other change to the file. Correct.

### `pages/nannies/AllNannies.tsx` — PASS
- `nationality`/`city` state added next to `status` (lines 43–44). ✔
- `extraFilter` ANDs status+nationality+city, deps `[status, nationality, city]`
  (lines 66–72). ✔
- `nationalityOptions`/`cityOptions` memoized over `items` (lines 91–98). ✔
- `onClear` resets all three dropdowns (line 149). ✔
- `FilterSelect` order Status → Nationality → City inside `FilterBar`
  (lines 153–160). ✔
- `getDate: (n) => n.createdAt` retained; CSV still reads `lc.filtered`; stats,
  block, pagination, nav untouched. ✔

### `pages/nannies/VerifyDocuments.tsx` — PASS
- `nationality`/`city` state added next to `docStatus` (lines 47–48). ✔
- `extraFilter` ANDs docStatus(some-document-matches)+nationality+city, correct
  deps (lines 95–101). ✔
- Options memoized over `items`; `onClear` resets all three (line 210). ✔
- `FilterSelect` order Document status → Nationality → City (lines 214–221). ✔
- `getDate: (n) => n.createdAt` retained; popup / approve / reject / doc-reject
  flows and the "All caught up" vs "No nannies match your filters" empty-state
  split (lines 226–230) all preserved. ✔

### `pages/families/AllFamilies.tsx` — MOSTLY PASS, 1 Major
Migration to `FilterBar`/`useListControls` is otherwise faithful: bespoke header
`<input type="search">` removed (actions is now just Export CSV, lines 120–124);
`SUB_STATUSES` constant + `subStatusOptions` built via `statusLabel` so labels
match the badges (lines 35–41, 93–96); nationality/city via `distinctOptions`;
`extraFilter` ANDs all three with correct deps; search matches
name/nationality/city; stats stay over `items`; table uses `lc.pageItems`;
empty state "No families match your filters."; `Pagination` added; CSV exports
`lc.filtered`; block/unblock, trial badge, `View →` identical. All correct.

**The one deviation:** `getDate` was omitted from `useListControls` (line 79–83),
so the `FilterBar` still renders the "Joined from / Joined to" date inputs but
they are completely inert — see Finding 1.

---

## Findings

### Finding 1 — MAJOR — [RESOLVED in fix round 1] Dead "Joined" date filter on AllFamilies; plan deviation on a false premise

> **Resolution (verified):** `getDate: (f) => f.createdAt` added at AllFamilies
> line 81 exactly as prescribed, no cast, build clean. The date range now filters
> by `createdAt`. Original analysis below kept for the record.

**Where:** `admin-panel/src/pages/families/AllFamilies.tsx`, `useListControls`
call (lines 79–83) and the `FilterBar` `dateLabel="Joined"` (line 142). Flow:
families listing → date-range filter.

**What's wrong & how I observed it.** The plan (section 3 WU2, line 194, and DoD
line 270) is explicit: `getDate: (f) => f.createdAt` with `dateLabel="Joined"`.
The implementation keeps `dateLabel="Joined"` and wires `from`/`to` into
`FilterBar`, so the two date pickers render — but with no `getDate`,
`useListControls` never evaluates the date branch (`hook` line 29:
`if (getDate && ...)`). The result: a user picks a Joined-from/to range, nothing
happens. A rendered control that silently does nothing violates the quality bar
(no dead UI) and is a direct deviation from the plan's stated wiring.

The build note (deviation section) justifies the omission with two claims, **both
false**:
1. *"the current `FamilyRow` interface does not include a `createdAt` field"* —
   it does: `firestore.ts` line 153, `createdAt?: Date` (with the doc comment
   "When the account was created"). The plan's source-read (line 20) was correct.
2. *"Adding `getDate: (f) => f.createdAt` would introduce an `any`"* — it would
   not. `f.createdAt` is typed `Date | undefined`, which is exactly the shape
   `getDate?: (item: T) => Date | undefined` expects. No cast, no `any`, and
   `tsc` passes (verified — integrated `npm run build` is clean).

The only true part of the note is that the **mock** families (`mockFamilies`,
lines 491–544) don't populate `createdAt`, so in mock mode a date bound would
match nothing. But (a) the real Firestore path `parseFamily` **does** map it
(line 891: `createdAt: toDateOrUndef(data.createdAt)`), so in production the
filter is fully functional; and (b) the plan already anticipated and accepted
empty-on-missing behavior ("Rows without `createdAt` are simply excluded when a
date bound is set ... acceptable", line 195) — identical to how the two nanny
pages already behave, which this review passed. So mock emptiness is not a reason
to drop the wiring; it is the documented, accepted behavior.

**Root cause.** The developer made an architecture/scope call it was not
authorized to make (Sonnet does not decide to drop planned wiring), and based it
on an unverified assumption about the type instead of reading `firestore.ts`. The
"would introduce `any`" reasoning is a misread of the optional `Date` type. Net
effect: a planned, type-safe, production-functional feature was downgraded to a
dead control to avoid a non-existent problem.

**Exact fix.** In `admin-panel/src/pages/families/AllFamilies.tsx`, add the
`getDate` line to the `useListControls` options object (currently lines 79–83):

```ts
  const lc = useListControls(items, {
    search: (f, q) => [f.fullName, f.nationality, f.city].some((s) => s?.toLowerCase().includes(q)),
    getDate: (f) => f.createdAt,
    extraFilter,
    pageSize: 8,
  });
```

No other change. Keep `dateLabel="Joined"`. Do NOT add a cast — `f.createdAt` is
already `Date | undefined`. Then re-run `cd admin-panel && npm run build` to
confirm tsc stays clean (it will).

No data-layer change is required for this task: the field, the interface, and the
real-path mapper all already exist. (If the team later wants the date filter to
exercise in mock mode too, populating `createdAt` on the four `mockFamilies`
entries is a trivial, separate follow-up — out of scope here and not a blocker.)

---

## Acceptance criteria

| # | Criterion | Result | Evidence |
|---|-----------|--------|----------|
| 1 | All nannies: Nationality + City next to Status; "All" default; AND with each other/status/search/date; Clear resets all | PASS | AllNannies lines 43–44, 66–72, 149, 153–160; `getDate` line 79 |
| 2 | Verify documents: same dropdowns into existing bar; AND; Clear resets all | PASS | VerifyDocuments lines 47–48, 95–101, 210, 214–221 |
| 3 | All families: shared FilterBar replaces lone search; Nationality/City/Subscription dropdowns; search matches name/nationality/city; AND; Clear resets all | PASS | Dropdowns + search + AND all correct; date range now live via `getDate: (f) => f.createdAt` (line 81) — Finding 1 resolved. |
| 4 | Options derived from data (distinct, sorted, "All …" first); no hardcoded nationality/city lists | PASS | `distinctOptions` used for both dims on all 3 pages; only the fixed subscription-status union is enumerated, which the plan mandates |
| 5 | Empty-state messages when filters match nothing; CSV exports exactly filtered rows on all 3 screens | PASS | Empty states present (AllNannies 165–167, VerifyDocuments 226–230, AllFamilies 151–153); CSV reads `lc.filtered` on AllNannies (101) + AllFamilies (103); VerifyDocuments has no CSV by design |
| 6 | Existing behavior preserved (status filter, stats, block/unblock, pagination, rows, nav) | PASS | Verified per-file above; stats stay over `items`; flows untouched |
| 7 | Design matches existing FilterBar/FilterSelect; no new patterns/one-off styles | PASS | Only `FilterBar`/`FilterSelect`/`Pagination` used; no inline `<select>`, no one-off classes |
| 8 | `npm run build` passes; no `any`; no new deps | PASS | Integrated build clean (893 modules, tsc 0 errors); grep shows no `any`/cast in the 4 files; chunk-size warning is pre-existing |

8 of 8 pass. Criterion 3 now passes after Finding 1's one-line fix (verified).

---

## Re-review checklist (for when the fixer returns)
- Confirm `getDate: (f) => f.createdAt` is present in AllFamilies' `useListControls`.
- Confirm no `any`/cast was introduced.
- Confirm `npm run build` still clean.
- Re-tick acceptance criterion 3.
