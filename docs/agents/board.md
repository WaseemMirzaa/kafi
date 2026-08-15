# Portfolio Board

The project-manager keeps this current across all active work. Epics list the
big features; Tasks list the individual cycles (a phase of an epic, or a
standalone change).

## WIP limit: ~2–3 concurrent tasks. Past that, throughput is illusory.

## Epics (large features / modules)

| Epic | Project | Status | Phases done / total | Doc |
| ---- | ------- | ------ | ------------------- | --- |
| _(example)_ nanny-profile-module | Nannies app | IN_PROGRESS | 2 / 5 | epics/nanny-profile-module.md |
| kafi-profile-trial-overhaul | Kafi mobile (Flutter) + functions | APPROVED | 0 / 3 (all 3 ACTIVE, parallel) | epics/kafi-profile-trial-overhaul.md |

## Tasks (active + recent)

| Slug | Project | Epic / phase | Branch | Status | Updated | Artifacts |
| ---- | ------- | ------------ | ------ | ------ | ------- | --------- |
| kafi-dashboard-revert-revenue-filters | Nannies app (Kafi admin) | — (standalone) | feat/kafi-dashboard-revert-revenue-filters | READY_FOR_REVIEW | 2026-06-07 | scope · plan · build |
| mobile-auth-onboarding-backend | Kafi mobile (Flutter) | — (standalone) | claude/quirky-goldberg-7jxx5a | BUILT (partial) | 2026-06-21 | plan · build |
| kafi-nanny-profile-fields | Kafi mobile (Flutter) | kafi-profile-trial-overhaul / phase 1 | claude/kafi-nanny-profile-fields | READY_FOR_BUILD | 2026-08-15 | scope · plan |
| kafi-family-profile-fields | Kafi mobile (Flutter) + admin | kafi-profile-trial-overhaul / phase 2 | claude/kafi-family-profile-fields | READY_FOR_BUILD | 2026-08-15 | scope · plan |
| kafi-trial-completion-flow | Kafi mobile (Flutter) + functions | kafi-profile-trial-overhaul / phase 3 | claude/kafi-trial-completion-flow-{app,functions} | READY_FOR_BUILD | 2026-08-15 | scope · plan |

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
