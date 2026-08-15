---
slug: kafi-trial-completion-flow-functions
project: kafi
title: Trial-completion workflow — Cloud Functions (scheduled detector, mutual-confirm resolver, outcome-aware notifications)
owner: developer
status: READY_FOR_REVIEW
updated: 2026-08-15
branch: claude/kafi-trial-completion-flow-functions
plan: docs/agents/plans/kafi-trial-completion-flow.md
---

# Build note — Trial-completion flow, Cloud Functions side

Implements exactly `docs/agents/plans/kafi-trial-completion-flow.md` §6's
"Cloud Functions (`functions/src/`)" file list, items **11–15**, plus the
one-line lockstep addition to `kafi_app/lib/models/notification_model.dart`.
Nothing else was touched — no other `kafi_app/` file, no `firestore.rules`
(both are the sibling app-side developer's branch, per the task boundary).

## Files changed

### `functions/src/triggers/scheduled.ts` (plan item 11)
- Added `import { recomputeActiveTrialNannyIds } from './trial';`.
- Added `isTrialDueForOutcome(trial, nowMs): boolean` — pure, exported. Exact
  signature from §5: `status==='active' && endDate<=nowMs && !outcomePromptSent`.
  Accepts `endDate` as either `FirebaseFirestore.Timestamp` (`.toMillis()`) or
  a native `Date` (`.getTime()`), per the declared union type.
- Added `trialOutcomeDetector` — `onSchedule('every 1 hours', ...)`, modeled
  on the existing `trialStartingReminder` in the same file: Timestamp range
  query (`status=='active' && endDate<=now`), `.limit(200)`, fires both
  prompts via `writeInbox`/`sendNotification`, then flips
  `status:'awaitingOutcome'`, stamps `endReachedAt`, sets
  `outcomePromptSent:true` (per-doc idempotency). Also calls
  `recomputeActiveTrialNannyIds(familyId)` after that update, per §4.4.

### `functions/src/triggers/trial.ts` (plan item 12)
- `recomputeActiveTrialNannyIds`: added `export`; widened the query from
  `status in ['active','accepted']` to
  `status in ['active','accepted','awaitingOutcome']` (§4.4 — otherwise an
  unsubscribed family loses chat access the moment the trial clock runs out,
  exactly when both sides most need to talk). Updated its doc comment to
  explain the widen and that it's now exported for `scheduled.ts`.
- Added `resolveMutualOutcome(familyOutcome?, nannyOutcome?): 'hired' |
  'notHired' | 'pending'` — pure, exported, exact truth table from §2.3
  (`notHired` on either side wins outright; both `hired` → `hired`; anything
  else → `pending`).
- Added `onTrialOutcomeResolved` — `onDocumentUpdated('trials/{trialId}')`.
  Fires only when `after.status === 'awaitingOutcome'` and
  `familyOutcome`/`nannyOutcome` changed. Computes the verdict via
  `resolveMutualOutcome`; `'pending'` is a no-op. On a decided verdict, a
  transaction re-reads the trial and bails if it's no longer
  `awaitingOutcome` (first-resolution-wins, mirrors `onHireEnded`'s guard and
  `FirestoreHireService.endHire`'s transactional pattern), then writes
  `status:'completed'`, `outcome:'hired'|'failed'`, `outcomeAt`,
  `completedAt` — the same field shape `FirestoreTrialService.recordOutcome`
  already writes (confirmed by reading that file: `outcomeLabel:'hired'`/
  `'failed'` are literally the two strings `trial_screen.dart` already
  sends). On `verdict==='hired'`, after commit: looks up
  `getFamily`/`getNanny` for display names (no client auth context in a
  background function) and creates `hires/{hire_<trialId>}` with the same 14
  fields `HireModel.toMap()` produces (confirmed field-for-field against
  `hire_model.dart`), `startedAt`/`createdAt` as `serverTimestamp()`. Then
  best-effort looks up a matching `applications` doc
  (`familyId`+`nannyId`, optionally `jobPostId`) and flips it exactly as
  `FirestoreApplicationService.markHired` does (`status:'hired'`,
  `respondedAt: serverTimestamp()`), swallowing errors. Sends no
  notifications itself (left to `onTrialEnded`, §4.3).
- `onTrialEnded`'s `completed` branch: now outcome-aware.
  `outcome==='hired'` → family only gets "✅ Hire confirmed" / "You and
  {nanny} confirmed the hire — she's now marked Hired." (nanny gets nothing
  here — she already gets `onHireCreated`'s "🎉 You've been hired!" off the
  `hires/{id}` doc `onTrialOutcomeResolved` just created — this is the fix
  for the double-push-on-hire problem). `outcome==='failed'` → family gets
  "Trial closed" / neutral copy; nanny gets an honest "Trial update" /
  "...visible in search again." copy (replacing the old always-generic,
  sometimes-misleading pair). `outcome` undefined/unrecognized → today's
  original generic copy, verbatim, unchanged (defensive fallback for any
  path this phase doesn't control). The `cancelled` branch and the
  terminal/`activeTrialNannyIds`-recompute guard above the branch are
  **untouched**.

### `functions/src/utils/notifications.ts` (plan item 13)
- Added `'trialOutcomePending'` to the `InboxType` union, between
  `'trialEndingSoon'` and `'trialCompleted'`. No other change —
  `writeInbox`/`sendNotification`/`buildInboxDoc` reused as-is.

### `functions/src/index.ts` (plan item 14)
- Exported `onTrialOutcomeResolved` (from `./triggers/trial`) and
  `trialOutcomeDetector` (from `./triggers/scheduled`), inserted into the
  existing import/export lists.

### `functions/test/trial_outcome.test.js` (plan item 15, new)
- Matches `stats.test.js`/`notifications.test.js` exactly: `'use strict'`,
  `node:test`/`node:assert`, requiring the **compiled** output
  (`require('../lib/triggers/trial.js')`, `require('../lib/triggers/
  scheduled.js')`).
- `resolveMutualOutcome`: both-hired→hired; family-hired+nanny-notHired→
  notHired; family-notHired+nanny-hired→notHired (the mismatch case);
  both-notHired→notHired; family-hired+nanny-silent→pending;
  nanny-hired+family-silent→pending; both-silent→pending. 7 tests, all six
  §5-specified scenarios plus the symmetric one-sided case.
- `isTrialDueForOutcome`: due (active+past+unprompted); not due
  (status≠active); not due (endDate in future); not due
  (`outcomePromptSent` already true); boundary endDate===now (due);
  boundary endDate one-ms-past (due); plus two extra cases beyond the §5
  minimum — accepts a native `Date` (the signature's declared union type),
  and not-due when `endDate` is missing entirely (defensive branch). 8
  tests. `endDate` is exercised as a `{toMillis()}`-shaped double for most
  cases (what a real Firestore read hands back) since production `trial`
  docs carry real `Timestamp`s, not `Date`s.

### `kafi_app/lib/models/notification_model.dart` (lockstep, one line)
- Added `trialOutcomePending` to `NotificationType`, in the same position
  (between `trialEndingSoon` and `trialCompleted`) as the `InboxType`
  addition above, per §4.5's "mirror the Flutter NotificationType enum
  names" comment already in `notifications.ts`. No other change to this
  file.

## Commands run and results

```
cd functions && npm install         # clean install, 244 packages (node_modules was empty)
cd functions && npm run build       # tsc — clean, zero errors
cd functions && npm test            # node --test test/*.test.js
```

Final test run: **37/37 passing** — 22 pre-existing (`contact.test.js`,
`notifications.test.js`, `stats.test.js`, `translate.test.js`, all
unmodified and still green — no regression) + 15 new
(`trial_outcome.test.js`). Build and test were also re-run clean immediately
before writing this doc, after all edits landed.

This matches CI exactly (`.github/workflows/ci.yml`'s `functions` job:
`npm ci && npm run build && npm test`, no separate lint step for this
package).

## §7 acceptance-criteria trace (functions-relevant items only)

- "Hired status + search-hide reached only once both `familyOutcome` and
  `nannyOutcome` are `'hired'`, resolved server-side... a mismatch never
  creates a hire" — ✓ `onTrialOutcomeResolved` + `resolveMutualOutcome`,
  unit-tested.
- "New scheduled `trialOutcomeDetector` detects `endDate<=now` on `active`
  trials and fires both prompts via the existing `writeInbox`/
  `sendNotification` pair" — ✓.
- "Redundant/generic notification chain replaced: hired → nanny gets exactly
  one push... not-hired → both parties get one specific, honest push each" —
  ✓ `onTrialEnded`'s enhanced `completed` branch.
- "`applications/{appId}` hired-flip moved to the mutual-confirm gate...now
  fired only by `onTrialOutcomeResolved`" — ✓ (the old client-side flip in
  `_createHireFromTrial` is the sibling app branch's removal, item 6 — not
  mine to touch, but the new server-side flip that replaces it is in place).
- "`npm run build && npm test` (with the new `trial_outcome.test.js`) both
  pass" — ✓, see above.
- App-only acceptance items (UI copy/buttons, `flutter analyze`) — not
  verified here; out of this branch's scope.

## §8 definition-of-done (functions-relevant items only)

- [x] Files 11–15 implemented; `onTrialOutcomeResolved` and
      `trialOutcomeDetector` exported from `index.ts`.
- [x] `notification_model.dart` and `notifications.ts` `InboxType` updated in
      lockstep (one new value, same position in both).
- [x] `npm run build && npm test` green in `functions/`.
- [ ] `firestore.rules` hardening — sibling app-branch scope, not mine.
- [ ] `flutter analyze` clean in `kafi_app/` — sibling app-branch's gate;
      see "Known gaps" below for one thing to check there.
- [ ] Manual smoke of the 2×2 matrix / scheduled detector / reactivation —
      needs both branches merged (app UI + rules on one side, this on the
      other) to exercise end-to-end; not runnable from this branch alone.

## Deviations from the plan (and why)

None material. Two small, plan-silent implementation choices worth flagging
for the reviewer:

1. **Applications lookup doesn't use `orderBy('createdAt', desc)`.** The
   client's `_createHireFromTrial` fetches all of the family's applications
   (already ordered `createdAt desc` via `getApplicationsForFamily`) and
   takes the first `nannyId`(+`jobPostId`) match — i.e. the *most recent* one
   when several could match. My server-side lookup queries
   `applications` where `familyId==X && nannyId==Y` (pure equality, capped
   `.limit(10)`) and takes `Array.find`'s first result, **without** an
   `orderBy`. Adding the `orderBy` would need a new composite index
   (`familyId, nannyId, createdAt DESC`) that doesn't exist yet in
   `firestore.indexes.json` (out of my file list). Since this step is
   explicitly best-effort/swallow-errors already, and in the dominant case
   there is at most one relevant application (deterministic
   `{jobId}_{nannyId}` doc id, or `after.jobPostId` disambiguates it when
   set), I judged this an acceptable, narrower-scope approximation rather
   than pulling `firestore.indexes.json` into this branch. Flagging
   explicitly rather than silently diverging.
2. **Added `.limit(10)`** to that same applications query (not specified in
   the plan) as a defensive bound — matches this codebase's existing
   convention of capping every list query (`activeHiredNannyIds`,
   `activeTrialNannyIds` both cap at 1000; this one's realistic cardinality
   is a single family/nanny pair's applications, so 10 is generous).

Everything else — field shapes, copy strings, function signatures, query
predicates, transaction/idempotency design — was implemented to match the
plan and the existing code it explicitly points at, verified by reading each
referenced file (`firestore_trial_service.dart`, `hire_model.dart`,
`firestore_hire_service.dart`, `application_model.dart`,
`firestore_application_service.dart`, `trial_controller.dart`) before
writing the Cloud Function equivalents.

## Known gaps / follow-ups (not fixed here — outside items 11–15 + the one
notification_model.dart line)

1. **Missing Firestore composite index for `trialOutcomeDetector`.**
   `firestore.indexes.json` has an index for `trials` on `{status ASC,
   startDate ASC}` (backing the existing `trialStartingReminder`) but none
   for `{status ASC, endDate ASC}`, which `trialOutcomeDetector`'s query
   needs (`where('status','==','active').where('endDate','<=',now)` is an
   equality + range filter on different fields — that combination requires
   a composite index in Firestore). Without it, the deployed function will
   throw `FAILED_PRECONDITION: The query requires an index` at runtime (it
   still compiles and unit-tests clean — the pure `isTrialDueForOutcome`
   helper is what's tested, per §5's design, so this gap doesn't show up in
   `npm test`). `firestore.indexes.json` isn't in my assigned file list
   (§6 items 11–15), so I didn't touch it — flagging for the PM/architect to
   add a
   `{collectionGroup:"trials", fields:[{fieldPath:"status",order:"ASCENDING"},
   {fieldPath:"endDate",order:"ASCENDING"}]}` entry before this deploys to a
   real Firestore project. First-deploy will also prompt Firebase to
   auto-suggest this exact index via a console link in the error log, if
   missed before deploy.
2. **`kafi_app/lib/controllers/notification_controller.dart`'s tap-routing
   switch is now non-exhaustive.** Its `switch (notif.type)` (around line
   202) has no `default:` and, before this change, covered all 21
   `NotificationType` values. My one-line lockstep addition
   (`trialOutcomePending`) makes it 22 without a matching `case`, which Dart
   analyzer's `missing_enum_constant_in_switch` diagnostic will flag
   (default severity: warning — `flutter analyze` does not report "clean"
   with it present). Tapping a `trialOutcomePending` notification would
   currently fall through the switch and do nothing (no crash, just no
   navigation). This file is in neither my scope (11–15) nor the plan's
   listed app items 1–10 — it's a small omission in the plan's file list,
   the same class of gap the plan itself flagged for the admin panel ("a
   five-minute look, not a planned change"). Suggested fix (one line, for
   whoever picks it up — likely grouped with the plan's app-branch work
   since it's a `kafi_app/` file): add
   `case NotificationType.trialOutcomePending:` grouped with
   `trialStartingSoon`/`trialEndingSoon`/`trialCompleted` (same
   `_openRouteForRole(Routes.chat)` behavior). Checked
   `notifications_screen.dart`'s two `NotificationType` switches
   (icon/color) — both already have a `default:` clause, so those are fine
   as-is.
3. Trials created before the app-side `endDate`-as-Timestamp prerequisite
   fix (plan §3, sibling branch) keep a string `endDate` and are silently
   excluded from `trialOutcomeDetector`'s query — this is the plan's own
   documented, accepted gap (§3), not something introduced here; repeating
   it here only so it's visible from the functions side too.

## Worktree / branch

Branch: `claude/kafi-trial-completion-flow-functions`, pushed to
`origin/claude/kafi-trial-completion-flow-functions`. Originally branched
from `origin/main` at `5d28dbf` (fetched fresh at the start of this
session); `origin/main` advanced twice more while this build was in
progress (`a377012` gitignore housekeeping, `ec2125b` restoring the
pipeline's `.claude/agents/`/`.claude/skills/` files — neither touches
`functions/` or `kafi_app/lib/models/`), so the branch was rebased onto the
final `origin/main` tip (`ec2125b`) before pushing — one clean commit
(`ec0730a`), no conflicts, build/test re-verified green after the rebase.
Worktree: `/home/user/kafi/.claude/worktrees/agent-adb77b83ab6ee4283`.
