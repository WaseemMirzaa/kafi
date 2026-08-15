---
slug: kafi-trial-completion-flow
project: kafi
title: Architect review (re-review) — Trial-completion workflow (mutual hire confirm + reactivation)
owner: architect-reviewer
status: REVIEW_PASS
updated: 2026-08-15
epic: kafi-profile-trial-overhaul (phase 3 of 3)
reviewed_branch: claude/kafi-trial-completion-flow @ e5f19cf (integrated: app + functions)
base: origin/main @ ec2125b
prior_verdict: REVIEW_FAIL (2 Critical + 1 Major) @ dd9620a
---

## Verdict

**REVIEW_PASS.** All three blocking findings from the first pass (C1, C2, M1) are
genuinely resolved, each verified by independently reproducing the evidence — not
by trusting the build notes. Zero Critical, zero Major remain. The four
first-pass Minors (m1–m4) are unchanged and remain non-blocking (they were never
required to be fixed).

Scope of the two fix rounds is tight and exactly as expected — since the reviewed
state (`16ee564`) only **three** non-doc files changed, all purely additive:

```
firestore.indexes.json                             |  8 ++  (C2)
functions/src/triggers/trial.ts                    | 22 ++  (M1)
kafi_app/lib/controllers/notification_controller.dart |  1 +  (C1)
```

No other file — and in particular no other Dart file — was touched, so nothing in
the first pass's "What's right" section could have regressed, and the only new
Dart surface is the single `case` line that resolves C1.

---

## Fix verification (independently reproduced)

### C1 — Non-exhaustive `switch` — RESOLVED
- **Fix:** `notification_controller.dart:224` adds
  `case NotificationType.trialOutcomePending:` to the existing trial group,
  falling into `_openRouteForRole(Routes.chat); return;` — exactly the one-line
  placement I prescribed (route it like every other trial notification).
- **Independent exhaustiveness proof (not the analyzer's say-so):** I grepped the
  `NotificationType` enum (`notification_model.dart`) and the `_handleTap` switch
  and hand-matched them. The enum has **22** values; the switch covers them in
  five case-groups totalling **1 + 2 + 9 + 4 + 6 = 22**, with **no `default`**.
  Every value — including the new `trialOutcomePending` — has a `case`. A Dart 3
  non-exhaustive-`switch`-statement compile error is therefore impossible; this is
  authoritative regardless of tooling. The secondary UX dead-end (the
  "How did the trial go?" tap that previously fell through to a no-op) is also
  closed: the notification now routes into chat, reaching the "View Trial" banner.
- **Analyze/test note (environment limitation, disclosed):** the Flutter/Dart SDK
  is **not installed in this re-review sandbox** (only a `~/.pub-cache` remains;
  `flutter`/`dart` are absent from PATH and the filesystem), so I could not re-run
  `flutter analyze`/`flutter test` this pass as I did in the first. I did not
  paper over this — instead I closed it by logical implication that is tighter
  than the analyzer for this specific defect: (a) my first pass established
  `flutter analyze` reported **exactly one** error, the C1 non-exhaustive switch;
  (b) this fix removes precisely that error and introduces no other Dart change
  (verified: the two fix rounds touched only this one `.dart` line); therefore
  `flutter analyze` is now "No issues found!". The four test files that "failed to
  compile" in pass 1 did so **solely** because the app-wide compile error blocks
  all Dart compilation — with the switch exhaustive they compile, and no test
  logic changed. Build note's "flutter analyze: No issues found! / flutter test:
  149 passed" is consistent with this chain.

### C2 — Missing `{status, endDate}` composite index — RESOLVED
- **Fix:** `firestore.indexes.json` now contains, on `trials` / `COLLECTION`
  scope, `[{status ASCENDING}, {endDate ASCENDING}]` — field-for-field what I
  specified.
- **Independently reproduced:** I re-parsed the file (`python3 -m json.tool` →
  valid JSON) and enumerated all `trials` composites programmatically. The set is
  now the original five **plus** `[('status','ASCENDING'),('endDate','ASCENDING')]`.
  This is exactly the index `trialOutcomeDetector`'s
  `.where('status','==','active').where('endDate','<=',now)` needs (equality +
  single range on a different field), so the query no longer throws
  `FAILED_PRECONDITION` at runtime. No code changed; the detector's
  active→awaitingOutcome path is now viable in production.

### M1 — Chat "on trial" badge retirement — RESOLVED (per plan §9)
Verified the `trial.ts` diff line-by-line against §9's specification; every clause
matches:
- **Single write, one place:** exactly one `trialStatus` write exists in all of
  `functions/src` (`trial.ts:364`); grep confirms it is **not** duplicated in
  `onTrialOutcomeResolved` or anywhere else. Placed inside `onTrialEnded`,
  immediately after the `lastTrialEndedAt` stamp (`trial.ts:344-346`) and before
  the `completed`/`cancelled` notification split (`trial.ts:374`) — the precise
  insertion point §9.5 dictates.
- **Correct lookup:**
  `chatThreads.where('trialId','==',event.params.trialId).limit(1)` — the
  `trialId`-based lookup §9.2 chose, **not** the tentative `familyId+nannyId`
  query from my first pass. I confirmed the premise holds: `linkTrialToThread`
  (`firestore_chat_service.dart:223-231`) writes `trialId` onto the thread doc, so
  the equality match resolves the linked thread. Being single-field equality, it
  is served by Firestore's automatic index — and indeed the index diff added
  **only** the C2 composite; **no new index** was introduced for M1, exactly as
  §9.2 requires.
- **Correct field/value:** writes **only** `{ trialStatus: after.status }`.
  Entry is gated by `wasActive && isTerminal` (`trial.ts:333-336`), so
  `after.status` is always one of `completed`/`cancelled`/`declined`; each flips
  `ChatThread.hasActiveTrial` false (`chat_models.dart:123-124` — true only for
  `'active'`/`'accepted'`), retiring the green pill + "View Trial" banner. It does
  not touch `trialId`, `lastMessage`, or `lastMessageAt`.
- **Best-effort, can't fail the trigger:** wrapped in `try/catch` that logs via
  `console.error` (not a bare/empty catch) and swallows — an unlinked thread
  yields an empty result and no throw, so the entitlement recompute and the
  notifications that follow are never undone. Mirrors the application-lookup
  swallow precedent in the same file.
- **Build reproduced:** `cd functions && npm run build && npm test` →
  **build clean, 37/37 pass, zero regressions** (I ran it myself after a clean
  `npm install`; the change compiles and touches no unit-tested helper, as §9.6
  expected).

*(Env note for the PM: this sandbox's `functions/` arrived with no `node_modules`
and a stale `lib/src`; the first `npm run build` therefore threw a spurious TS5011
and tests couldn't find `../lib`. After `rm -rf lib && npm install`, build and
tests are clean. This was purely a fresh-worktree bootstrap artifact, not a code
defect — flagged so nobody mistakes it for a regression.)*

---

## Regression check — nothing in "What's right" disturbed

Diffed the reviewed state (`16ee564`) against `e5f19cf`: the only changes are the
three additive fixes above. The M1 block is inserted **between** existing blocks
in `onTrialEnded` and is best-effort, so it alters no prior behavior — the
terminal-transition guard, the `activeTrialNannyIds` recompute, the
`lastTrialEndedAt` stamp, and the outcome-aware notification split all remain
byte-identical below it. The 2×2 outcome matrix, reactivation trace, rules
hardening, `activeTrial()` widen, and design-system conformance validated in pass
1 are untouched. No new deviation introduced.

## Minor findings (still open, still non-blocking — unchanged from first pass)
- **m1** `onTrialOutcomeResolved`'s applications lookup has no
  `orderBy('createdAt' desc)`. Safe approximation; leave or defer to an index task.
- **m2** `NannyProfileController.loadEmploymentStatus()` still gates the dashboard
  "You're on trial" card on `isAcceptedOrActive` (disappears at `awaitingOutcome`).
  Cosmetic; the chat "View Trial" path (now that C1/M1 are fixed) still reaches it.
- **m3** `sendTrialOffer`'s duplicate-offer guard doesn't include
  `awaitingOutcome`. Product judgment call, not spec'd — note to PM.
- **m4** `AppStrings.trialHire`/`trialNotThisTime` + `IHireService.createHire`
  (+impls) now unused. Deliberate blast-radius scoping; optional cleanup later.

None block; none were required to change and none changed.

---

## To the PM (3-line summary)
- Verdict: **REVIEW_PASS** — 0 Critical, 0 Major; C1/C2/M1 each independently
  re-verified resolved, only 4 pre-existing non-blocking Minors remain.
- Reproduced myself: `functions` build clean + **37/37** tests; C1 switch proven
  exhaustive by hand (22/22 enum values, no default); C2 index present & valid;
  M1 matches plan §9 exactly (single `trialId`-lookup write in `onTrialEnded`,
  no new index).
- One disclosure, not a blocker: Flutter SDK is absent from this re-review
  sandbox, so `flutter analyze`/`flutter test` were verified by static proof +
  the tight one-line diff rather than re-executed — the C1 defect (non-exhaustive
  switch) is settled authoritatively by the enum/switch grep. Clear to open the PR.
