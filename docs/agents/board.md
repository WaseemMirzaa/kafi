# Portfolio Board

The project-manager keeps this current across all active work. Epics list the
big features; Tasks list the individual cycles (a phase of an epic, or a
standalone change).

## WIP limit: ~2–3 concurrent tasks. Past that, throughput is illusory.

## Epics (large features / modules)

| Epic | Project | Status | Phases done / total | Doc |
| ---- | ------- | ------ | ------------------- | --- |
| _(example)_ nanny-profile-module | Nannies app | IN_PROGRESS | 2 / 5 | epics/nanny-profile-module.md |

## Tasks (active + recent)

| Slug | Project | Epic / phase | Branch | Status | Updated | Artifacts |
| ---- | ------- | ------------ | ------ | ------ | ------- | --------- |
| kafi-dashboard-revert-revenue-filters | Nannies app (Kafi admin) | — (standalone) | feat/kafi-dashboard-revert-revenue-filters | PR_OPEN | 2026-06-07 | scope · plan · build · review · [PR #1](https://github.com/WaseemMirzaa/kafi/pull/1) |
| kafi-revenue-trend-chart | Nannies app (Kafi admin) | — (standalone) | feat/kafi-revenue-trend-chart | PR_OPEN | 2026-06-07 | scope · plan · build · review · [PR #2](https://github.com/WaseemMirzaa/kafi/pull/2) |
| kafi-listing-filters | Nannies app (Kafi admin) | — (standalone) | feat/kafi-listing-filters | READY_FOR_ARCH | 2026-06-07 | scope |

<!--
Task status flow:
DRAFT -> NEEDS_APPROVAL -> READY_FOR_ARCH -> PLANNING -> READY_FOR_BUILD
-> BUILDING -> READY_FOR_REVIEW -> (REVIEW_FAIL -> FIXING -> READY_FOR_REVIEW)*
-> REVIEW_PASS -> PR_OPEN -> DONE

Epic status:  DRAFT -> APPROVED -> IN_PROGRESS -> DONE
Phase status: PLANNED -> ACTIVE -> MERGED

Concurrency: one branch/worktree per task; unique slugs; never two writers on one
file. Run separate concurrent tasks as separate PM sessions, monitored with
`claude agents`.

Opus owns: architect (plan) + architect-reviewer (verify vs plan + verdict).
Sonnet owns: developer (build) + fixer (apply analysed fixes).
-->
