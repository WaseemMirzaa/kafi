---
name: review-worktree-merge-risk
description: How to verify integrations when developer worktrees were based on an older commit than the feature-branch HEAD (ort auto-merge of full-file rewrites)
metadata:
  type: feedback
---

When developer worktrees are based on an older commit (e.g. the repo's initial
commit) instead of the feature-branch HEAD, the PM merges full-file rewrites via
git ort auto-merge. These merges can silently produce orphaned blocks, duplicated
functions, or lost intent from intermediate commits.

**Why:** Seen on `kafi-dashboard-revert-revenue-filters` — both worktrees branched
off `2bb67f8` (initial) not feature HEAD `d6c4423`; Dashboard.tsx and Revenue.tsx
were resolved by taking the rewritten versions wholesale, so intermediate
`ee8a1e3` changes had to be re-verified as preserved-by-intent rather than
preserved-by-merge.

**How to apply:** On any review where the build note flags a base mismatch:
1. `grep` for conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`) in the merged files.
2. `grep` for duplicate top-level declarations (the page/component function,
   `load`, handlers) — duplicate-merge symptom.
3. Diff the relevant region against BOTH ancestor versions
   (`git show <base>:path`, `git show <intermediate>:path`) to confirm the
   intended layout/behavior from each ancestor survived.
4. Confirm every behavioral item the intermediate commit added is still present
   (count actionTo links, onAction/CSV handlers, computed fields).
5. Verify orphaned methods: a wholesale rewrite may leave a service method with
   no callers — flag as Minor dead code, not a blocker.
Trust the tree, not the merge — re-derive coherence from the source.
