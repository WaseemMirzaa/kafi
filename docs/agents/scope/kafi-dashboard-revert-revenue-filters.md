---
slug: kafi-dashboard-revert-revenue-filters
project: kafi-admin-panel
title: Revert dashboard design (keep logic), add global period filters to Revenue page
owner: project-manager
status: PR_OPEN
updated: 2026-06-07
---

# Scope — kafi-dashboard-revert-revenue-filters

## Objective

On a feature branch off `main`: (1) revert the admin Dashboard's **visual design**
to its pre-`ee8a1e3` state (restore the original revenue-card row layout) while
**preserving every logic/behavioral update** from `ee8a1e3` — live data fetching,
computed "New today", TableCard `actionTo` navigation, `onAction` CSV exports,
live sidebar badges; (2) bring the Revenue page (`business/Revenue.tsx`) in line
with the other pages by adding a **single global filter bar** (Weekly / Monthly /
Yearly presets + custom from/to date range) that drives **all** sections: stat
cards, revenue trend, Plan revenue split, and Recent transactions; (3) commit the
pre-existing uncommitted chat/dispute/trial UI changes as a **separate commit**
on the same branch. Ship as one PR.

## Modules & flows affected

| Area | Files |
| ---- | ----- |
| Dashboard design revert | `admin-panel/src/pages/Dashboard.tsx` |
| Revenue filters | `admin-panel/src/pages/business/Revenue.tsx`, `admin-panel/src/services/firestore.ts` (RevenueService), reuse of `components/ui/ListControls.tsx` + `hooks/useListControls.ts` |
| Pre-existing chat work (commit only, no new code) | `components/chat/ConversationsPanel.tsx`, `components/chat/MessageThread.tsx`, `pages/disputes/DisputeDetail.tsx`, `pages/trials/TrialDetail.tsx` |

## Work breakdown

- **WU0 (PM, sequential, first):** Create branch `feat/kafi-dashboard-revert-revenue-filters`.
  Commit the uncommitted chat/dispute/trial changes as one commit ("admin: chat
  popup + collapsible dispute details"). Commit the uncommitted Dashboard partial
  revert as a second WIP baseline commit so developers/architect work from it.
- **WU1 (developer, INDEPENDENT):** Dashboard design revert. Restore the original
  4-card revenue row **layout/design**; keep live data logic feeding values where
  the original layout has a slot (exact mapping decided by architect). Preserve
  all `actionTo`/`onAction`/`exportCsv` wiring and computed "New today". Do not
  touch `AdminUI.tsx` TableCard props (carry the wiring).
- **WU2 (developer, INDEPENDENT):** Revenue page global filter bar using existing
  `FilterBar`/`FilterSelect`/`useListControls` primitives. Presets: Weekly,
  Monthly, Yearly + custom date range. All four sections recompute from **paid
  transactions within the selected range** — including Plan revenue split (its
  basis changes from "current active subscriptions" to "paid txns by plan in
  period"). Service layer must return enough transaction history for Yearly
  (current `recentTransactions()` cap of 50 must not silently truncate results).

WU1 ∥ WU2 are parallelizable (non-overlapping files except none expected; if the
architect finds `firestore.ts` overlap, run sequentially).

## Acceptance criteria

- [ ] Dashboard revenue row visually matches the pre-`ee8a1e3` design.
- [ ] All `ee8a1e3` behavior still works: TableCard links navigate (nannies/verify, nannies, families, trials), 4 CSV export buttons download, sidebar badges live, "New today" computed.
- [ ] Revenue page has ONE global filter bar (Weekly / Monthly / Yearly / custom date range) styled with existing ListControls components — no new one-off styling.
- [ ] Changing the filter updates stat cards, trend chart, Plan revenue split, and Recent transactions consistently from paid transactions in range.
- [ ] Yearly / wide date ranges are not truncated by the 50-transaction fetch cap.
- [ ] Works in mock mode and live Firestore mode; TypeScript build passes.
- [ ] Chat/dispute/trial changes land as their own commit, described in the PR body.

## Out of scope

- Any redesign of the Revenue page beyond adding the filter bar (page already follows AdminUI pattern).
- Sidebar, AdminUI.tsx component changes (TableCard props stay as committed).
- Flutter app, Firebase functions, other admin pages.
- New chat/dispute features beyond committing what's already in the working tree.

## Risks / open questions

- "Keep all logic updates" on Dashboard: assumption = original card **layout**,
  live **values** where they map; architect finalizes the mapping. The existing
  uncommitted partial revert restored hardcoded values — architect may adjust it.
- Plan revenue split semantics change (subscriptions → transactions in period);
  numbers will differ from before. Approved by Waseem.
- Chat changes ride in the same PR as a separate commit; flagged in PR body as
  unrelated to the revenue work.
