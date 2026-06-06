# Codetivelab Agent Team — Usage Guide

Everything you need to set up, log in to GitHub, and run the 5-agent pipeline:
**scope → plan → build → review → fix → PR**, with Opus as the senior
architect/QA and Sonnet doing the coding and fixing.

---

## Part 1 — One-time setup

Do these once per machine.

### 1.1 Prerequisites

| Tool        | Check it's there        | If missing |
| ----------- | ----------------------- | ---------- |
| Claude Code | `claude --version`      | `curl -fsSL https://claude.ai/install.sh \| bash` (Win: `irm https://claude.ai/install.ps1 \| iex`) |
| Git         | `git --version`         | macOS: `brew install git` · Win: `winget install Git.Git` · Linux: `sudo apt install git` |
| GitHub CLI  | `gh --version`          | see 1.2 below |

Claude Code needs a paid plan (Pro/Max) or Console credits — the free tier
doesn't include it.

### 1.2 Install the GitHub CLI (`gh`)

The Project Manager opens pull requests with `gh`, so it must be installed and
logged in.

```bash
# macOS
brew install gh

# Windows (open a NEW terminal afterwards — the installer updates PATH)
winget install GitHub.cli

# Linux (Debian/Ubuntu)
sudo apt install gh
```

Confirm: `gh --version`.

### 1.3 Log in to GitHub from the terminal

Run:

```bash
gh auth login
```

Answer the prompts in this order:

1. **What account do you want to log into?** → `GitHub.com`
   (use `GitHub Enterprise Server` only if your repo is self-hosted).
2. **Preferred protocol for Git operations?** → `HTTPS` (simplest).
3. **Authenticate Git with your GitHub credentials?** → `Yes`.
4. **How would you like to authenticate?** → `Login with a web browser`.
5. A **one-time code** appears (e.g. `AB12-CD34`). Press Enter — your browser
   opens `github.com/login/device`. Paste the code, approve, done.

The token is saved securely in your system credential store. Verify:

```bash
gh auth status
```

You should see "Logged in to github.com account <your-username>".

**No browser on the machine (server/SSH/CI)?** Use a token instead:

1. Create one at `github.com/settings/tokens` → *Generate new token (classic)*.
2. Tick the scopes **`repo`**, **`workflow`**, **`read:org`** (missing scopes make
   PR/Action commands fail silently).
3. Save the token somewhere safe (you can't view it again), then:

```bash
gh auth login --with-token < mytoken.txt
# or paste interactively:
gh auth login   # choose "Paste an authentication token"
```

### 1.4 Set your Git identity (once)

So commits are attributed correctly:

```bash
git config --global user.name  "Waseem"
git config --global user.email "you@example.com"   # the email on your GitHub account
```

### 1.5 Drop the agent bundle into your repo

Copy `CLAUDE.md`, the `.claude/` folder, and the `docs/` folder into the **root**
of the repo you want the team to work on:

```
your-repo/
├── CLAUDE.md
├── .claude/
│   ├── agents/      (project-manager, architect, developer, architect-reviewer, fixer)
│   └── skills/      (project-management, software-development, qa-code-review)
└── docs/agents/     (board.md + scope/ plans/ builds/ reviews/)
```

Commit them so the whole team setup is versioned with the project:

```bash
git add CLAUDE.md .claude docs
git commit -m "Add Codetivelab agent team"
```

### 1.6 Verify the install

```bash
cd your-repo
claude --agent project-manager
```

Inside Claude Code:

```
/agents     → confirm all 5 agents appear (project-manager, architect,
              developer, architect-reviewer, fixer)
/doctor     → confirm install health
```

Type `exit` (or Ctrl-D) to leave.

---

## Part 2 — Running the pipeline

### 2.1 Start as the Project Manager

Always launch the session **as the PM** — it's the only agent that can both ask
you questions and spawn the others:

```bash
cd your-repo
claude --agent project-manager
```

### 2.2 Give it a project + task

Just tell it what you'd tell a person. Terse is fine:

```
Project: naturesecret.pk
Task: the side-cart checkout button disappears after the COD app was removed. Fix it.
```

### 2.3 Answer its questions, then approve

The PM will:
1. Inspect the repo and the affected modules/flows.
2. Ask you a small batch of **clarifying questions** (definition of done, scope
   boundaries, edge cases, whether to split across parallel developers).
3. Write a **scope** and show you a tight summary.

Reply with changes if needed, or approve:

```
Approved. Go ahead.
```

**Nothing proceeds past this gate without your yes.**

### 2.4 What happens automatically after approval

```
architect (Opus)          → reads the source, writes a file-by-file plan,
                            re-plans if the existing code practice is bad
developer(s) (Sonnet)     → implement the plan exactly (in parallel + isolated
                            git worktrees if the plan allows)
[PM merges the worktrees]
architect-reviewer (Opus) → checks the build AGAINST the plan + the quality bar,
                            runs the flows, and analyses the root cause of any
                            mistake
   ├─ PASS → PR
   └─ FAIL → fixer (Sonnet) applies the exact fixes → back to the reviewer
PM → opens the pull request and gives you the URL
```

You can walk away during this. Come back and the PM reports the PR link.

### 2.5 Track progress any time

- **Task board:** open `docs/agents/board.md` — one row per task with its status.
- **Artifacts** (the paper trail) live under `docs/agents/`:
  `scope/<slug>.md` → `plans/<slug>.md` → `builds/<slug>.md` → `reviews/<slug>.md`.
- **Live agents:** inside the session, run `/agents` → **Running** tab to see who's
  working; press **Ctrl-B** to background a long task and keep typing.

### 2.6 Review and merge the PR

The PM opens the PR but does **not** merge it — that's your call. Review it:

```bash
gh pr view --web         # open the PR in your browser
gh pr checkout <number>  # pull it locally to test
gh pr merge <number>     # merge when you're happy (or merge in the browser)
```

The PR body summarizes the objective, file-level changes, how it was verified,
and the acceptance-criteria checklist, with links to the scope/plan/review.

---

## Part 3 — Common operations

**Run several developers on one flow.** Tell the PM up front: "split this across
parallel developers if you can." The architect partitions the work into
non-overlapping file sets; the PM runs one developer per set (each in its own
worktree) and merges them before review.

**Continue a previous task.** Re-launch as PM and reference the slug:
"Continue `naturesecret-side-cart-fix` — the reviewer left two majors."

**One-off questions without spawning the team.** Use a normal Claude Code session
(`claude`) for quick edits; use `claude --agent project-manager` when you want the
full pipeline.

**Raise code quality on a critical module.** Edit `.claude/agents/developer.md`
→ change `model: claude-sonnet-4-6` to `model: claude-opus-4-8` (slower/pricier,
higher quality). Revert when done.

**Tune the playbooks.** The agents' standards live in `.claude/skills/*/SKILL.md`
and `CLAUDE.md`. Edit those to change behavior across the whole team — changes are
picked up within the session for existing skill files.

**Save budget on simple tasks.** Lower `effort: high` to `medium` in the Opus
agents' frontmatter.

---

## Part 4 — Troubleshooting

| Symptom | Fix |
| ------- | --- |
| `claude: command not found` right after install | Close the terminal completely and open a new one (PATH update). On Linux add `export PATH=$HOME/.local/bin:$PATH` to `~/.zshrc`/`~/.bashrc`. |
| `gh: command not found` on Windows after install | Open a **new** Windows Terminal window (not just a tab). |
| PM can't open a PR / `gh` auth error | Run `gh auth status`; if not logged in, redo `gh auth login`. Ensure token scopes include `repo` + `workflow`. |
| PR command fails with "no commits" | The work must be on a feature branch with commits. Ask the PM to commit on `feat/<slug>` before creating the PR. |
| Agents don't show in `/agents` | You added files on disk mid-session — restart Claude Code, or recreate via the `/agents` UI. Confirm files are in `.claude/agents/` at the repo root. |
| Skill content not applied | Confirm the `skills:` list in the agent's frontmatter matches the folder name under `.claude/skills/`. Top-level dir additions need a restart. |
| Parallel developers collide on files | The architect's partition wasn't clean — tell the PM to run those units sequentially instead. |
| Fix↔review loop won't converge | The PM caps rounds (~3) and escalates. If it's an architecture problem, send it back to the architect, not the fixer. |

---

## Quick reference

```bash
# setup (once)
gh auth login                         # log in to GitHub
git config --global user.name  "..."  # set commit identity
git config --global user.email "..."

# run the team
cd your-repo
claude --agent project-manager        # start the PM session
#   then: "Project: <name>  Task: <what you want>"
#   answer questions → "Approved." → it ships a PR

# inside the session
/agents        # list / monitor agents
/doctor        # health check
Ctrl-B         # background a running task
exit           # leave

# review the PR
gh pr view --web
gh pr checkout <number>
gh pr merge <number>
```
