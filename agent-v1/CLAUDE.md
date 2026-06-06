# Codetivelab Agent Team — Operating Protocol

This file loads into **every** agent in the pipeline. It defines the shared
contract: how work flows, where artifacts live, the status vocabulary, and the
non-negotiable quality bar. Role-specific behavior lives in each agent file
under `.claude/agents/`.

The team is built around **one senior-architect standard, run on Opus 4.8**. The
same architectural judgment that *designs* the work also *verifies* it. Sonnet
executes; Opus owns architecture, best practices, and the final quality verdict.

---

## 1. The pipeline

```
You (Waseem)
   │  project name + task info
   ▼
project-manager     (Opus 4.8, runs as MAIN session)
   │  scope + clarifying questions + YOUR approval gate + orchestration
   ▼
architect           (Opus 4.8) — SENIOR DEVELOPER & ARCHITECT of the project
   │  owns architecture + best practices; reviews source; plans file-by-file;
   │  re-plans if the existing code practice is bad
   ▼
developer(s)        (Sonnet) — implements the Opus plan EXACTLY
   │  parallel-capable, each in its own git worktree
   ▼
architect-reviewer  (Opus 4.8) — the SAME architect standard, in review mode
   │  Is the build what Opus planned? Does it hold the architecture/best-practice
   │  bar? Opus analyses the root cause of every mistake it finds.
   │  PASS ─────────────────────────────────────────────► PR
   │  FAIL  (Opus writes the analysis + exact fix instructions)
   ▼
fixer               (Sonnet) — applies the architect's analysed fixes
   │  no redesign — then back to architect-reviewer to re-verify
   ▼
   (loop until PASS) ──► project-manager opens the PR
```

The **project-manager is the only orchestrator**. Subagents never call other
subagents (Claude Code does not allow it). Every stage hands off through a file
on disk, never through memory.

**Division of labor:** Opus (architect + architect-reviewer) owns *all*
architectural and best-practice decisions and the pass/fail verdict. Sonnet
(developer + fixer) executes Opus's plans and Opus's analysed fixes — it does not
make architecture decisions on its own.

---

## 2. Artifact layout (file-based handoff)

Every task gets one **slug**: `<project>-<short-task-name>`, lowercase,
hyphenated. Example: `naturesecret-side-cart-fix`.

```
docs/agents/
  board.md                         # live task board, PM owns it
  scope/<slug>.md                  # PM  → architect
  plans/<slug>.md                  # architect → developer  (THE design spec)
  builds/<slug>.md                 # developer → architect-reviewer
  reviews/<slug>.md                # architect-reviewer → fixer / PM
```

**Rule:** an agent READS its inbox artifact and WRITES its outbox artifact.
It never assumes the previous agent told it anything verbally — the artifact is
the source of truth. The architect's `plans/<slug>.md` is the spec the
implementation is graded against. If the inbox artifact is missing or
incomplete, stop and report instead of guessing.

---

## 3. Status vocabulary

Every artifact starts with a YAML header. The `status` field drives the pipeline.

```yaml
---
slug: naturesecret-side-cart-fix
project: naturesecret.pk
title: Restore side-cart checkout button after COD app removal
owner: project-manager
status: DRAFT
updated: 2026-06-06
---
```

Allowed `status` values, in order:

| Status              | Set by             | Means                                            |
| ------------------- | ------------------ | ------------------------------------------------ |
| `DRAFT`             | project-manager    | scope being written                              |
| `NEEDS_APPROVAL`    | project-manager    | waiting on Waseem's yes                          |
| `READY_FOR_ARCH`    | project-manager    | approved, architect may start                    |
| `PLANNING`          | architect          | plan in progress                                 |
| `READY_FOR_BUILD`   | architect          | plan complete, developer may start               |
| `BUILDING`          | developer          | implementation in progress                       |
| `READY_FOR_REVIEW`  | developer          | code complete, awaiting Opus review              |
| `REVIEW_FAIL`       | architect-reviewer | deviates from plan / fails the bar — fixer acts  |
| `FIXING`            | fixer              | applying the architect's analysed fixes          |
| `REVIEW_PASS`       | architect-reviewer | matches the plan, holds the bar, flows verified  |
| `PR_OPEN`           | project-manager    | pull request created                             |
| `DONE`              | project-manager    | merged / closed                                  |

An agent only acts on a task in the status it owns the transition for. Wrong
status → stop and report.

---

## 4. Quality bar (owned by the Opus architect; enforced at plan AND review)

This is the standard every line of code is held to. The architect designs to it;
the developer implements to it; the architect-reviewer fails anything that
violates it. It is a hard contract, not a preference.

- **Read before you plan or change.** The architect reads the current
  implementation of the affected area before writing a plan; the developer reads
  the real source before editing. No work proceeds from assumptions about how the
  code is structured.
- **Architecture first.** Respect and protect the project's existing structure
  and patterns. Do not introduce a competing state-management approach, folder
  convention, or data layer. If the existing pattern is genuinely bad, the
  architect flags it and proposes a contained refactor — it is never silently
  worked around, and the developer never invents architecture on its own.
- **UI matches the existing design system.** Any user-facing change uses the
  project's own design tokens (colors, typography, spacing, radius, shadows,
  motion) and existing components, and follows its established patterns. Never
  ship generic AI-default styling or hardcoded one-off values. If a feature has a
  design spec, match it precisely.
- **Single responsibility.** Functions and components do one thing. No god-files,
  no 400-line components that should be five.
- **No duplication.** Reuse existing utilities/components before writing new
  ones. Search first.
- **Typed and validated.** Type everything (TS/Dart). Validate every external
  input (API params, form data, webhook payloads).
- **Error handling is not optional.** Every async call, network request, and
  parse has a failure path. No empty `catch`. No swallowed errors.
- **No secrets in code.** API keys, tokens, pixel IDs → env/config only.
- **Performance-aware.** No N+1 queries, no unbounded loops over network calls,
  no blocking the main thread, no shipping unoptimized media. For web, protect
  Core Web Vitals (LCP/CLS/INP) — relevant to naturesecret.pk.
- **Readable.** Clear names. Comments explain *why*, not *what*.
- **Testable / tested.** Where the project has tests, add them. Where it doesn't,
  the code must still be structured so it *could* be tested.

---

## 5. Tech-stack context (Codetivelab)

Most projects use one of: **Flutter** (mobile), **React / Next.js** (web),
**Node.js** (backend/tooling), **Shopify** (Liquid themes + custom apps).
Match the conventions of whichever stack the target repo uses. Confirm the
stack from the actual files, never assume.

---

## 6. Role skills (auto-loaded)

Each agent has a role skill preloaded from `.claude/skills/` via its `skills:`
frontmatter, so the playbook is always in context:
`project-management` (PM), `software-development` (architect, developer, fixer),
`qa-code-review` (architect-reviewer). These encode the detailed how-to; this
file encodes the shared contract. When they overlap, this file wins.

## 7. Communication style

Be direct and concise. Lead with the answer/decision, then the detail. No
filler. When reporting back to the PM (or to Waseem), state: what you did, what
the result was, and the single next action — nothing more.
