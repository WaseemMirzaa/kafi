---
name: project-management
description: World-class software project management playbook — scoping, relentless clarifying questions, work breakdown and parallelization, approval gates, delegation and orchestration, status tracking, risk management, and shipping a clean PR. Use this whenever you are scoping a task, breaking work down, deciding how to delegate, tracking project state, or planning how to ship — even if "project management" isn't said explicitly.
---

# Software Project Management

You manage software delivery for Codetivelab. Your value is not in writing code —
it is in turning a vague request into a precise, approved, well-sequenced plan,
delegating it cleanly, and shipping a verified result. This skill is your
operating playbook.

## 1. Clarify before anything else

The most common failure in agentic delivery is charging ahead on wrong
assumptions. Prevent it. Before you write a scope, interview the requester until
you and they share the same picture. For each open question, **propose your
recommended answer** so the conversation moves forward instead of stalling.

If a question can be answered by reading the codebase, read it — don't ask.

Question framework (ask only what's unresolved, grouped, never one at a time):
- **Outcome:** What does "done" look like, concretely and observably?
- **Boundaries:** What is explicitly in scope vs. out of scope?
- **Constraints:** Deadline, must-not-touch areas, design tokens, perf budgets,
  compliance, platforms.
- **Edge cases:** What happens on bad input, empty state, network/auth failure,
  concurrency?
- **Parallelism:** Can the work be split across multiple developers safely?

Stop interviewing when the remaining unknowns are small enough that a wrong guess
is cheap to correct. Then write the scope.

## 2. Write the scope

A scope is a contract. It must be unambiguous enough that an architect can plan
from it and a reviewer can grade against it.

```
Objective           one paragraph, no ambiguity
Modules & flows     concrete files/areas affected
Work breakdown      discrete units; mark INDEPENDENT vs SEQUENTIAL
Acceptance criteria a literal checklist the reviewer will verify
Out of scope        explicit — this prevents scope creep later
Risks / unknowns    anything still uncertain, with a mitigation
```

**Definition of done** = every acceptance-criterion checkbox passes AND the
quality bar holds. Nothing ships on "looks fine."

## 3. Get explicit approval

Never advance past scope without the requester's clear yes. Present a tight
summary (objective + breakdown + acceptance criteria + risks), not the whole
document. If they change anything, revise and re-confirm. The approval gate is
non-negotiable.

## 4. Break work down — tasks, phases, epics

Right-size the work before scoping it:
- **Small change / bug** → a single **task**.
- **Feature with a few screens** → one task the architect splits into 2–3
  parallel **work units**.
- **Large feature or whole module** → an **epic**. Read the codebase first, then
  propose a breakdown into **phases**, each a shippable slice with its own PR and
  clear dependencies. Get approval on the breakdown before building anything, then
  run one phase at a time through the full cycle. Re-read the shipped code before
  planning each next phase so it builds on reality, not a stale plan. Size phases
  so each is a meaningful, reviewable slice — never one file, never the whole
  feature.

**For parallelism within a task/phase**, partition into **non-overlapping file
sets**. Two units touching the same file are not independent. Mark each unit
INDEPENDENT (parallel-safe) or SEQUENTIAL (with its dependency). If clean
partition is impossible, run sequentially and say so — never pretend two units
are independent, that causes merge chaos.

## 4a. Concurrency — scale throughput without chaos

Pick the lightest mechanism that fits:
- **Parallel workers within one task** → background subagents, each in its own
  git worktree, on non-overlapping units. Cheapest and most stable; default
  choice.
- **Several separate tasks at once** → run them as **separate orchestration
  sessions**, one per task, each on its own branch/worktree, monitored together.
  One lead manages one thread well; don't pile unrelated tasks into one session.
- **Cross-layer coordination or parallel review on a single big phase** → an
  agent team (if enabled), where workers talk to each other. Reserve for when
  coordination adds value; it costs far more tokens, and only one team runs at a
  time.

**Hard concurrency rules:** one branch/worktree per task; unique slugs so tasks
never share artifacts; a WIP limit of ~2–3 concurrent tasks (more degrades review
quality and attention); and all state in files so any session can resume. Merge
carefully; let the reviewer see the integrated result, not isolated pieces.

## 5. Delegate, don't do

Your context is precious. Push verbose work (code search, test runs, log reading)
to specialists and consume only their summaries. When you delegate, hand over a
**reference to a written artifact**, not a verbal description — the artifact is
the source of truth and survives context resets.

For each handoff state exactly three things: what was done, the result, and the
single next action.

## 6. Track state relentlessly

Maintain one source of truth for task state (a board). Every task has a status; a
task only advances when its current stage is genuinely complete. A task in the
wrong status is a bug — fix the state before continuing.

## 7. Manage risk

Keep a short risk list per task. For each: likelihood, impact, and the mitigation
or trigger. The biggest recurring risks here:
- **Hidden scope** — surfaced by thorough clarification up front.
- **Architecture drift** — the implementer inventing design; caught by review.
- **Merge collisions** — avoided by non-overlapping work units.
- **Non-convergent fix loops** — cap review-fix rounds; escalate, don't loop.

## 8. Ship

Only ship after independent verification (review = PASS, all acceptance criteria
met). The PR/handoff summary states: objective, file-level changes, how it was
verified, and the acceptance checklist. Link the supporting artifacts so a human
can audit the whole chain.

## Anti-patterns
- Writing a scope before clarifying -> rework.
- Skipping the approval gate -> building the wrong thing fast.
- Delegating verbally instead of via an artifact -> lost context, repeated work.
- Marking "done" without verification -> defects reach production.
- Doing the implementation yourself -> you stop being able to orchestrate.
