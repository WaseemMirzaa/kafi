---
slug: kafi-trial-completion-flow
project: kafi
title: Architect review — Trial-completion workflow (mutual hire confirm + reactivation)
owner: architect-reviewer
status: REVIEW_FAIL
updated: 2026-08-15
epic: kafi-profile-trial-overhaul (phase 3 of 3)
reviewed_branch: claude/kafi-trial-completion-flow (integrated: app + functions)
base: origin/main @ ec2125b
---

## Verdict

**REVIEW_FAIL.** 2 Critical, 1 Major, plus minors. The plan was implemented
faithfully and well on both branches in isolation — but the two developer-flagged
gaps are **both real and both block**, and each surfaces only in the *integrated*
result (which is exactly why this stage reviews the merge, not the sibling
branches). One of them breaks compilation of the entire Flutter app.

Verified by running, not trusting the build notes:
- `functions`: `npm run build` clean; `npm test` **37/37 pass** (22 existing + 15
  new in `trial_outcome.test.js` — the mismatch case and the boundary cases are
  covered). Zero regressions.
- `kafi_app`: `flutter analyze` → **1 error** (see Critical-1); `flutter test`
  → **4 test files fail to compile** on the same error. Flutter 3.35.7 / Dart
  3.9.2, matching `.fvmrc`.

The plan-adherence, architecture, rules-hardening, and 2×2-matrix trace are all
correct (details in the "What's right" section) — the failures are integration
gaps the plan's file list didn't assign to either developer, not defects in the
work either developer was told to do.

---

## Critical findings (must fix)

### C1 — Non-exhaustive `switch` breaks `flutter analyze` AND app compilation
- **Where:** `kafi_app/lib/controllers/notification_controller.dart:202`
  (`_handleTap`'s `switch (notif.type)`), triggered by the lockstep enum
  addition in `notification_model.dart` (functions-branch, merged in).
- **What & evidence:** `flutter analyze` reports, as an **error** (not a
  warning): `The type 'NotificationType' isn't exhaustively matched by the switch
  cases since it doesn't match the pattern 'NotificationType.trialOutcomePending'
  • non_exhaustive_switch_statement`. `flutter test` then fails to compile 4 test
  files with the identical Dart compile error. In Dart 3 a non-exhaustive
  `switch` **statement** over an enum is a compile-time error, so this is not
  cosmetic — the app (and CI) does not build. Acceptance criterion "`flutter
  analyze` clean" **FAILS**.
- **Why it only appears now (integration analysis):** the app branch added the
  switch-consuming code paths but *not* the new enum value (that file was the
  functions dev's, added for lockstep); the functions branch added the enum value
  but never compiles Flutter. Each branch was individually green. The
  non-exhaustiveness is only realized when the enum (functions branch) and the
  switch (pre-existing) coexist — i.e. after the merge. Neither developer's
  assigned scope (app items 1–10 / functions items 11–15) owned
  `notification_controller.dart`; the plan's file list omitted it. Both
  developers flagged it correctly.
- **Secondary effect (UX dead-end):** even ignoring the compile error, the
  inbox doc is written with `type:'trialOutcomePending'` and parses to
  `NotificationType.trialOutcomePending`; with no matching `case` and no
  `default:`, tapping the "How did the trial go?" / "What happened after your
  trial?" notification falls through the switch to the end of the method and
  **does nothing** — the primary entry point into the outcome UI is a no-op.
- **Root cause:** resolution moved server-side and a new notification type was
  introduced, but the client tap-router — the code that turns that notification
  into navigation — was outside both work-unit boundaries and was never wired.
- **Exact fix (one line, mechanical):** in `notification_controller.dart`, add
  `case NotificationType.trialOutcomePending:` to the existing trial group at
  lines 216–224 (with `trialOfferReceived`/`trialStartingSoon`/`trialEndingSoon`/
  `trialCompleted`), so it falls into `_openRouteForRole(Routes.chat); return;`.
  This matches how every other trial notification routes (into chat, whose "View
  Trial" banner reaches the trial screen). Re-run `flutter analyze` (must be "No
  issues found!") and `flutter test` (must be green) to confirm.

### C2 — Missing `{status, endDate}` composite index makes the detector throw in production
- **Where:** `firestore.indexes.json` (unchanged by this branch); consumed by
  `functions/src/triggers/scheduled.ts` `trialOutcomeDetector` (line 80-86):
  `.where('status','==','active').where('endDate','<=',now)`.
- **What & evidence:** I read the actual `firestore.indexes.json`. Its `trials`
  composites are `{familyId,offeredAt}`, `{nannyId,offeredAt}`,
  `{familyId,status}`, `{status,startDate}`, `{status,reminderSent,startDate}`.
  There is **no** `{status,endDate}` index. An equality filter on `status` plus a
  range filter on a *different* field (`endDate`) requires a dedicated composite
  index; without it Firestore rejects the query at runtime with
  `FAILED_PRECONDITION: The query requires an index`. It compiles and unit-tests
  clean because §5's design only tests the pure `isTrialDueForOutcome` helper, not
  the live query — so `npm test` cannot catch this.
- **Impact:** `trialOutcomeDetector` is the sole entry point into the entire
  mutual-confirm gate. Every hourly run throws, no trial ever transitions
  `active → awaitingOutcome`, and the whole feature is inert in production. The
  acceptance criterion "a new scheduled Cloud Function detects `endDate<=now`…"
  fails on a real deploy. Hence Critical, despite being a one-line config add.
- **Root cause:** `firestore.indexes.json` sits outside both work-unit file lists
  (app 1–10 / functions 11–15); the plan added a new Timestamp range query
  (§4.1) without adding the backing index to its own change list. The functions
  dev flagged it precisely.
- **Exact fix:** add to `firestore.indexes.json`'s `indexes` array:
  ```json
  {
    "collectionGroup": "trials",
    "queryScope": "COLLECTION",
    "fields": [
      { "fieldPath": "status", "order": "ASCENDING" },
      { "fieldPath": "endDate", "order": "ASCENDING" }
    ]
  }
  ```
  No code change. (Deploy will still succeed even before backfill — pre-fix
  string-`endDate` trials are silently excluded, the plan's accepted §3 gap.)

---

## Major findings (should fix)

### M1 — Chat "on trial" badge no longer retires after a trial resolves (regression)
- **Where:** removal of `TrialController._flipThreadTrialStatus` (app branch,
  necessary-wiring item 3) with no server-side replacement in
  `functions/src/triggers/trial.ts`.
- **What & evidence:** In `origin/main`, `_flipThreadTrialStatus` was called
  from `setOutcome` on the family's Hire/Not-this-time tap and wrote the linked
  `chatThreads/{id}.trialStatus` to the terminal status (`completed`/`declined`),
  which retired `ChatThread.hasActiveTrial` (`chat_models.dart:124` — true only
  for `'active'`/`'accepted'`) and removed the green "on trial" pill + "View
  Trial" banner. That client path is now gone; resolution to `completed` happens
  server-side in `onTrialOutcomeResolved`, and neither it, `onTrialEnded`, nor
  `trialOutcomeDetector` updates `chatThreads.trialStatus`. Grepped
  `functions/src` — zero writes to `trialStatus`/`linkTrialToThread`. Net effect:
  after a nanny is hired or a trial fails, the family's chat list keeps showing
  the stale "on trial" badge/banner indefinitely.
- **Severity rationale:** purely cosmetic (navigation and the server-owned chat
  *unlock* via `families.activeTrialNannyIds` are unaffected — that's a different
  mechanism and is correctly recomputed), but it is a genuine behavioral
  **regression** vs. `origin/main` for the exact flow this phase changes. The
  functions dev noted the caching gap but under-assessed it as "harmless."
- **Root cause (architect-level, not a mechanical miss):** the plan relocated
  outcome resolution from client to server (correctly) but did not relocate the
  thread-badge retirement the removed client path used to perform. The plan
  explicitly scoped `chat_models.dart`/`chat_screen.dart` as "Not touched," so
  there was no home defined for this responsibility server-side.
- **Routing:** this needs an **architect decision on placement**, not a blind
  fixer patch — deciding whether/where the server should retire the thread badge
  (most likely: in `onTrialOutcomeResolved` and the `cancelled`/`failed` paths of
  `onTrialEnded`, query `chatThreads` by `familyId`+`nannyId`, best-effort update
  `trialStatus` to the terminal value, mirroring the removed client behavior).
  Route back through the PM to the architect to confirm the location and whether a
  `{familyId,nannyId}` chatThreads index (already present per
  `firestore.indexes.json`) suffices, then hand the concrete instruction to the
  fixer. Do not have the fixer invent this.

---

## Adjudication of the two flagged gaps and the wiring self-report (as requested)

1. **Composite index** — REAL, Critical. See C2. Genuinely absent; genuinely
   throws `FAILED_PRECONDITION` in production while passing `npm test`.
2. **Non-exhaustive notification switch** — REAL, Critical (worse than flagged).
   The developers described it as an analyzer *warning* / silent no-op; it is in
   fact a compile **error** in Dart 3 that fails `flutter analyze` and
   `flutter test`. Confirmed current behavior: falls through to end of method →
   no navigation, no crash — but the app does not build. See C1.
3. **`activeTrial()` widen (self-reported wiring)** — CORRECT and safe, verified
   against the diff:
   - `i_trial_service.dart` has two genuinely distinct methods with distinct call
     sites: `activeTrial(String familyId)` (single trial backing
     `TrialController`, line 13) vs `activeTrialNannyIds()` (browse-hide
     derivation, line 17).
   - `awaitingOutcome` was added to `activeTrial`'s `whereIn` in
     `FirestoreTrialService` (line 40-45), the mock (`t.isActive ||
     t.isAwaitingOutcome`), and the nanny-side loop in
     `TrialController.refreshAll()` — all three, consistently.
   - `activeTrialNannyIds()` and `BrowseController._engagedNannyIds()` /
     `FirestoreHireService` are **untouched** (empty diff confirmed). So
     `awaitingOutcome` does **not** leak back into browse visibility — she is out
     of both engaged sets the instant the clock runs out and stays visible until a
     `hires` doc is created, exactly per plan §1. No leak.

---

## 2×2 outcome matrix + reactivation trace (code-read, cross-checked against runtime)

- **both-hired:** family writes `familyOutcome='hired'` (rules allow — doesn't
  touch nanny fields); nanny writes `nannyOutcome='hired'`; second write fires
  `onTrialOutcomeResolved`, `resolveMutualOutcome`→`'hired'`, transaction sets
  `completed`/`outcome='hired'` (first-resolution-wins guard present), Admin-SDK
  creates `hires/hire_<trialId>` — field-for-field matches `HireModel.toMap()`
  (verified all 14 fields incl. `salaryAed:0`, `employmentType: trialType ??
  'live-in'`, server timestamps). `onHireCreated` sends the single "You've been
  hired!" push; `onTrialEnded` sends only the family "Hire confirmed" push (no
  nanny double-push). Search-hide via existing `activeHiredNannyIds()`. ✓ Nothing
  client-side creates the hire (`_createHireFromTrial` fully removed). ✓
- **family-hired / nanny-still-looking:** nanny `notHired` →
  `resolveMutualOutcome`→`'notHired'` → `completed`/`outcome='failed'`, no hire.
  She was already out of both engaged sets at `awaitingOutcome`, stays visible. ✓
  Mismatch row unit-tested (`family notHired + nanny hired` and vice versa). ✓
- **detector idempotency:** `outcomePromptSent` gate in both the pure helper and
  the doc update; unit-tested (not-due-when-already-prompted, boundary
  exactly-now / one-ms-past). ✓
- **reactivation:** 6-option sheet → `resignHire(reasonNote: reason.name)` →
  `endHire(hire.id, reason: resigned, note: reasonNote)` (existing transactional
  first-end-wins) → `hires.status='ended'` → `onHireEnded` notifies family →
  `activeHiredNannyIds()` drops her → reappears in browse. Reason persisted on
  the existing `hires.endNote`; nothing on her account/profile is deleted. ✓
- **rules hardening (§6):** verified line-by-line
  (`firestore.rules:224-229`). A nanny writing `familyOutcome` hits
  `hasAny(['familyOutcome',...])`→ nanny branch false, family branch false (not
  her uid) → **denied**; a family writing `nannyOutcome` symmetrically denied.
  Existing trial writes (offer/accept/decline/counter/cancel/payment) touch none
  of the restricted keys → not blocked. Forgery of the other party's confirm
  signal is genuinely prevented. ✓

---

## What's right (so the fixer doesn't churn it)

- `TrialModel` (enum value + 7 fields + 5 getters) threaded through
  ctor/`copyWith`/`toMap`/`fromMap` using existing conventions — exact per §2.
- §3 prerequisite fix correct: `endDate` written as `Timestamp` in `sendOffer`
  and recomputed+`Timestamp` in `applyCounterAndAccept` (with a sane
  `durationDays ?? 7` fallback); mock's constructor default already recomputes.
- `firestore_trial_service` outcome setters are plain `.update()`s writing only
  the caller's own side — matches §6 and the rules model.
- UI (both screens) reuses the existing design system: `KafiColors.grn/grnD`
  gradient, `roseD`, `cardBorder`, `KafiTheme.fredoka/nunito`, and the existing
  `_chooseProofSource` bottom-sheet idiom (drag handle + tile rows). Reason-label
  `switch` **expressions** are exhaustive. No hardcoded one-off styling.
- `resolveMutualOutcome` truth table exactly per §2.3; `notHired`-wins mismatch
  correct. No trigger storm: the three `trials` update triggers each guard
  correctly (self-write to `completed` re-enters `onTrialOutcomeResolved` but
  short-circuits on `status!=='awaitingOutcome'`; `onTrialResponse` ignores
  `completed`; `onTrialEnded` fires exactly once). Verified by trace.
- `recomputeActiveTrialNannyIds` widened to include `awaitingOutcome` (chat
  unlock) and called from the detector — the correct, narrow widen; browse-hide
  derivation deliberately left out.

## Minor findings (non-blocking; fixer may batch with the above)

- **m1** `onTrialOutcomeResolved`'s applications lookup has no
  `orderBy('createdAt' desc)` (would need a new `{familyId,nannyId,createdAt}`
  index). Best-effort + `jobPostId` disambiguation + realistic single-match
  cardinality make this a safe approximation; leave as-is or note for a later
  index task. (functions dev flagged.)
- **m2** `NannyProfileController.loadEmploymentStatus()` still gates the
  dashboard "You're on trial" card on `isAcceptedOrActive`, so it disappears at
  `awaitingOutcome`. Cosmetic; the chat "View Trial" path (once M1/C1 are fixed)
  still reaches the screen. (app dev flagged, gap 3.)
- **m3** `sendTrialOffer`'s duplicate-offer guard doesn't include
  `awaitingOutcome` — a family could offer a fresh trial while a prior one is
  still resolving. Product judgment call, not spec'd; note to PM. (app dev gap 4.)
- **m4** Orphaned-but-retained: `AppStrings.trialHire`/`trialNotThisTime` and
  `IHireService.createHire` (+ impls) are now unused. Deliberate per plan
  (blast-radius scoping); acceptable. Optional cleanup later.

---

## To the PM (3-line summary)
- Verdict: **REVIEW_FAIL** — 2 Critical, 1 Major.
- Biggest blocker: the merged branch **does not compile** — a Dart-3
  non-exhaustive `switch` in `notification_controller.dart:202` (from the new
  `trialOutcomePending` enum) fails `flutter analyze` and `flutter test`; C2
  (missing `{status,endDate}` Firestore index) leaves the detector dead in prod.
- C1 and C2 are one-line mechanical fixes for the fixer; M1 (chat-badge
  retirement regression) needs an architect placement decision before the fixer
  touches it — route it back through you.
