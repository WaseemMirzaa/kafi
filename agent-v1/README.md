# Codetivelab Agent Team — Setup & Usage

A 5-agent Claude Code pipeline that takes a project + task from you and ships a
reviewed pull request: **scope → plan → build → review → fix → PR**.

The spine of the team is **one senior-architect standard, run on Opus 4.8**. The
same Opus judgment that *designs* the work *verifies* it after Sonnet codes it —
checking the build against its own plan and the best-practice bar, analysing any
mistakes, and handing exact fixes to Sonnet. Opus owns architecture and the
pass/fail verdict; Sonnet executes.

## Files in this bundle

```
CLAUDE.md                          # shared protocol (loads into every agent)
.claude/agents/
  project-manager.md               # Opus 4.8 — orchestrator (run as MAIN session)
  architect.md                     # Opus 4.8 — SENIOR DEV & ARCHITECT: plans file-by-file
  developer.md                     # Sonnet   — implements the plan (parallel, worktree)
  architect-reviewer.md            # Opus 4.8 — same architect, verifies build vs plan
  fixer.md                         # Sonnet   — applies the architect's analysed fixes
.claude/skills/
  project-management/SKILL.md      # auto-loaded into project-manager
  software-development/SKILL.md    # auto-loaded into architect, developer, fixer
  qa-code-review/SKILL.md          # auto-loaded into architect-reviewer
docs/agents/
  board.md                         # live task board
  scope/ plans/ builds/ reviews/   # file-based handoff between stages
```

## Install

Copy `CLAUDE.md`, the `.claude/` folder, and the `docs/` folder into the **root
of the repo** you want the team to work on, and commit them.

```
your-repo/
  CLAUDE.md
  .claude/agents/...
  docs/agents/...
```

Restart Claude Code (agents added directly on disk load at session start), or run
`/agents` to confirm all five appear in the Library tab.

## Run

Start the session **as the Project Manager** — required, because only a
main-session agent can spawn the others and ask you questions:

```bash
claude --agent project-manager
```

Then give it work:

```
Project: naturesecret.pk
Task: side-cart checkout button disappears after the COD app was removed. Fix it.
```

The PM inspects the repo, asks its clarifying questions, writes a scope, and
**waits for your approval**. Say yes and it drives the rest: architect plans →
developer(s) build → architect-reviewer (Opus) checks the build against the plan
and the bar → fixer (Sonnet) applies whatever Opus's analysis prescribes →
re-review until it passes → PM opens the PR and gives you the URL.

## The review loop (what you asked for)

After Sonnet finishes a feature, the **Opus architect-reviewer** answers one
question first: *is this what Opus planned?* It walks the plan's file-by-file
change list against the actual code, flags every deviation and every
best-practice violation, runs the flows, and for each mistake writes a **root-
cause analysis + the exact fix**. The **Sonnet fixer** then just executes those
fixes — it doesn't re-diagnose or redesign — and the work goes back to Opus to
re-verify. It only reaches a PR on `REVIEW_PASS` (zero critical, zero major, plan
matched, acceptance criteria met).

## Skills (auto-loaded into each agent)

Each agent gets a role **skill** — a `SKILL.md` playbook preloaded into its
context at startup via the `skills:` field in its frontmatter, so the expertise
is always on without anyone invoking it:

| Skill                         | Auto-loaded into            | Covers |
| ----------------------------- | --------------------------- | ------ |
| `project-management`          | project-manager             | scoping, clarifying-question framework, work breakdown, approval gates, delegation, risk, shipping |
| `software-development`        | architect, developer, fixer | architecture principles, reading-before-writing, typing/validation, error handling, security, performance/CWV, testing, self-review gate, Flutter/React-Next/Node/Shopify notes |
| `qa-code-review`              | architect-reviewer          | plan-adherence check, multi-lens review, end-to-end flow verification, severity triage, root-cause analysis, exact-fix instructions |

These are authored from current Claude Code skill patterns (Anthropic's
code-review/simplify approach, the "clarify before you build" guardrail, and
established PM playbooks) rather than pulling a heavy third-party pack, so they
stay tuned to this exact pipeline. Because they live in `.claude/skills/`, any
agent can also invoke them on demand through the Skill tool — but the ones in the
table above are *always* loaded for the matching agent. Edit a `SKILL.md` and the
change is picked up within the session (top-level dir adds need a restart).

To grow the system, drop more skills in `.claude/skills/<name>/SKILL.md` and add
`<name>` under `skills:` in whichever agent should always have it.



Claude Code subagents **cannot spawn other subagents**, and only the main thread
can ask you questions interactively. So the orchestrator can't be a peer
subagent — it has to be the session itself. `claude --agent project-manager`
makes the PM the main thread, which is what lets it both talk to you and delegate.

## Handoff

Each stage writes a file the next stage reads (subagents start fresh and return
only a summary, so verbal handoff is unreliable):

```
scope/<slug>.md → plans/<slug>.md → builds/<slug>.md → reviews/<slug>.md
```

`plans/<slug>.md` is the design spec the implementation is graded against. The
`status` field in each header drives the pipeline; full flow and the quality bar
are in `CLAUDE.md`.

## Multiple developers on one flow

The architect partitions the work into non-overlapping units and marks the
independent ones. The PM spawns **one developer per independent unit in
parallel**, each in its own **git worktree** (`isolation: worktree` in
`developer.md`) so they never collide. After they finish, the PM merges the
branches and the architect-reviewer reviews the integrated result.

## Models (as specified)

| Role               | Model               | Owns |
| ------------------ | ------------------- | ---- |
| project-manager    | `claude-opus-4-8`   | scoping, approval gate, orchestration |
| architect          | `claude-opus-4-8`   | architecture + best practices + the plan |
| developer          | `claude-sonnet-4-6` | faithful implementation of the plan |
| architect-reviewer | `claude-opus-4-8`   | verifying build vs plan + the verdict |
| fixer              | `claude-sonnet-4-6` | applying the architect's analysed fixes |

Knobs:
- **Higher code quality on a critical module:** set `developer.md` →
  `model: claude-opus-4-8` (costs more). Aliases `opus` / `sonnet` also work and
  auto-track the latest version if you'd rather not pin.
- **Effort:** Opus agents are `effort: high`. Lower to `medium` to save budget on
  simpler tasks.
- **Memory:** every agent has `memory: project`, accumulating codebase knowledge
  in `.claude/agent-memory/` across sessions. Switch to `local` to keep it out of
  version control.
- **PRs:** the PM uses the GitHub CLI (`gh`) — install and authenticate it
  (`gh auth login`).

## One-time check

```bash
claude --agent project-manager
# then inside:
/agents      # confirm all five agents are listed
/doctor      # confirm install health
```
