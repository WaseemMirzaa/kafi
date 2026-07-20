---
epic: nanny-profile-module
project: Nannies app
title: Full nanny profile module (build, view, availability, rate)
owner: project-manager
status: DRAFT            # DRAFT -> APPROVED -> IN_PROGRESS -> DONE
updated: 2026-06-06
---

## Objective
One paragraph: what the whole feature/module delivers and why.

## Architecture notes (from reading the current code)
How it fits the existing app: data layer, navigation, auth, design system/tokens
to reuse. Filled in by the architect/PM after reading the codebase — never from
assumptions.

## Phases
Each phase is a shippable slice with its own PR. Run one at a time; re-read
shipped code before planning the next.

| # | Phase | Slug | Depends on | Parallelizable inside? | Status |
|---|-------|------|-----------|------------------------|--------|
| 1 | Data layer (schema, model, CRUD service) | nanny-profile-data | — | no | PLANNED |
| 2 | Edit profile (nanny side) | nanny-profile-edit | 1 | yes (form / schedule) | PLANNED |
| 3 | View profile (parent side) | nanny-profile-view | 1 | no | PLANNED |
| 4 | Integration + edge/empty/error states | nanny-profile-integrate | 2,3 | no | PLANNED |
| 5 | Polish (motion, perf, a11y) | nanny-profile-polish | 4 | yes | PLANNED |

Phase status: PLANNED -> ACTIVE -> MERGED.

## Out of scope
Explicit list — protects the epic from creep.

## Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| Profile schema churn affects later phases | high | lock contracts in Phase 1 review |
