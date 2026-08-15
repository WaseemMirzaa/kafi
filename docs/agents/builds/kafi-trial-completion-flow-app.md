---
slug: kafi-trial-completion-flow-app
project: kafi
title: Trial-completion workflow — mutual hire confirmation + reactivation (app side)
owner: developer
status: READY_FOR_REVIEW
updated: 2026-08-15
branch: claude/kafi-trial-completion-flow-app
commits: 78df95d
---

# Build note — Trial-completion flow (app side)

Implements `docs/agents/plans/kafi-trial-completion-flow.md` §6's "App
(`kafi_app/`)" file list, items 1–10, plus the `firestore.rules` change.
The Cloud Functions side (items 11–15, `functions/test/`) is a sibling
developer's parallel branch and is untouched here — this build only shares
the Firestore field-name/shape contract the plan specifies in §2.2/§2.3/§2.4.

## File-by-file

**1. `kafi_app/lib/models/trial_model.dart`** — Added `TrialStatus.awaitingOutcome`
(between `active`/`completed`) and the 7 new fields (`familyOutcome`,
`familyOutcomeAt`, `notHiredReason`, `nannyOutcome`, `nannyOutcomeAt`,
`outcomePromptSent` default `false`, `endReachedAt`) + 5 getters
(`isAwaitingOutcome`, `familyConfirmedHire`, `nannyConfirmedHire`,
`familyDeclinedHire`, `nannyDeclinedHire`), threaded through the constructor,
`copyWith`, `toMap`, `fromMap` following the file's exact existing
conventions (`_parseDate`, `?? this.field`, `.toIso8601String()`).

**2. `kafi_app/lib/models/trial_outcome_reasons.dart`** (new) — `NotHiredReason`
(7 values) and `ReactivationReason` (6 values), persisted as `.name`, no
logic.

**3. `kafi_app/lib/services/interfaces/i_trial_service.dart`** — Added
`setFamilyOutcome(trialId, {required outcome, evaluation, notHiredReason})`
and `setNannyOutcome(trialId, {required outcome})`. Also widened
`activeTrial()`'s doc comment to describe its new scope — see "Necessary
wiring beyond the plan's file list" below.

**4. `kafi_app/lib/services/firebase/firestore_trial_service.dart`** —
- **§3 prerequisite fix, landed first**: `sendOffer` now also writes
  `data['endDate'] = Timestamp.fromDate(trial.endDate)` (was left as the ISO
  string `toMap()` produces, which a `where('endDate','<=',Timestamp)` range
  query — needed by the functions-side scheduled detector — silently never
  matches). `applyCounterAndAccept` now fetches the trial's `durationDays`
  and recomputes+writes `endDate` as a Timestamp from the counter's new
  `startDate` (previously left the stale pre-counter `endDate` in place
  entirely).
- Implemented `setFamilyOutcome`/`setNannyOutcome` as plain `.update()`
  calls, exactly per the plan's §6 code snippet — no client-side
  transaction, since each party only ever writes its own field.
- Widened `activeTrial(familyId)`'s query to
  `whereIn: ['active', 'accepted', 'awaitingOutcome']` (was missing
  `awaitingOutcome`) — see below.

**5. `kafi_app/lib/services/mock/mock_trial_service.dart`** — Parity
`setFamilyOutcome`/`setNannyOutcome` (in-memory, `copyWith`-based,
`AppConfig.mockDelay`), matching every other method's style. `activeTrial`
widened the same way as file 4 (`t.isActive || t.isAwaitingOutcome`).
`applyCounterAndAccept` needed no change here — it already rebuilds a fresh
`TrialModel` without passing `endDate`, so the constructor's own
`endDate ?? startDate.add(Duration(days: durationDays))` default already
recomputes it correctly from the new `startDate`.

**6. `kafi_app/lib/controllers/trial_controller.dart`** —
- Added `familyRecordOutcome({required outcome, NotHiredReason? reason})`
  and `nannyRecordOutcome(String outcome)` exactly per the plan's §6
  snippets (evaluation/notHiredReason/snackbar wiring, nanny snackbar
  intentionally omitted — screen banner covers it).
- **Removed** `setOutcome()` and `_createHireFromTrial()` — confirmed (fresh
  grep) their only two call sites were `trial_screen.dart`'s old family
  outcome buttons, both rewired in file 7.
- Left `IHireService.createHire` (interface + both implementations)
  unremoved, per the plan's explicit instruction.
- See "Necessary wiring" below for the `activeTrial`-related additions in
  this file (nanny-loop widening, `selected` freshness refresh) and the
  `_flipThreadTrialStatus` removal.

**7. `kafi_app/lib/views/family/trial_screen.dart`** — Rewrote `_outcomeBar`:
family branch now branches on `isAwaitingOutcome` → not-yet-responded (two
buttons, same green-gradient/rose-outline styling as before, new copy: "We
hired her" direct call, "Keep searching" opens a reason sheet) →
`familyConfirmedHire` (waiting banner via the existing `_banner` helper) →
`familyDeclinedHire` (shrink). Nanny branch: unchanged pending/accepted
cancel button, plus a mirrored `isAwaitingOutcome` block ("I got the job" /
"I'm still looking", same styling). Header timer swaps to "Trial ended —
awaiting your response" when `isAwaitingOutcome` (only the `Text` at
`_remainingLabel`'s call site changed, not the function itself). New reason
sheet (`_chooseNotHiredReason`) reuses `_chooseProofSource`'s exact idiom
(drag-handle white sheet + tile rows), 7 reasons + Skip.

**8. `kafi_app/lib/views/nanny/nanny_dashboard_screen.dart`** — Replaced the
bare "Resign" link + `_confirmResign()`'s `AlertDialog` with "Looking for a
job again?" title + "Make My Profile Available" CTA, opening
`_openReactivationSheet()` (same sheet idiom, 6 `ReactivationReason` tiles,
no separate skip). Selecting a reason calls
`controller.resignHire(reasonNote: reason.name)`. This replaces the entry
point rather than adding a second one.

**9. `kafi_app/lib/controllers/nanny_profile_controller.dart`** — Extended
`resignHire()` to `resignHire({String? reasonNote})`, passed straight
through to `_hireService.endHire(hire.id, reason: HireEndReason.resigned,
note: reasonNote)`. Default `null` preserves exact prior behavior.

**10. `kafi_app/lib/l10n/app_strings.dart` + `locales/en_us.dart` +
`locales/ar_ae.dart`** — 26 new keys, EN + AR for every one (verified: every
key referenced via `AppStrings.X.tr`/`trParams` in the three files above
resolves to a defined constant — cross-checked all 92 distinct `AppStrings.*`
references used across `trial_screen.dart`/`nanny_dashboard_screen.dart`/
`trial_controller.dart` against the defined-constants list; zero missing).
Did **not** reuse the old `trialHire`/`trialNotThisTime` keys (now orphaned,
left defined but unused, same "don't remove, out-of-scope blast radius"
call the plan makes for `IHireService.createHire`) — the plan's §10 lists
distinct new copy ("We hired her"/"Keep searching") for this exact spot, so
new keys were the more literal reading.

**`firestore.rules`** — `trials.update` now: admin always; family may write
iff the diff doesn't touch `nannyOutcome`/`nannyOutcomeAt`; nanny may write
iff the diff doesn't touch `familyOutcome`/`familyOutcomeAt`/
`notHiredReason`. Exact pattern already used for `families`. Traced every
existing client write path to `trials/*` (offer, accept/decline/counter,
cancel, payment confirm/report, the two new outcome setters) against the new
rule — none are blocked; only `familyOutcome*`/`nannyOutcome*`/
`notHiredReason` are now field-restricted.

## Necessary wiring beyond the plan's literal file list

These weren't spelled out in the plan's file-by-file text but are, I
concluded, required for the plan's own §2.1/§6-item-7 design (the
`awaitingOutcome` status + its UI) to actually be reachable — flagging each
explicitly per "any deviation and why," not slipping them in quietly.

1. **`ITrialService.activeTrial()` widened to include `awaitingOutcome`**
   (family Firestore query in file 4, mock equivalent in file 5, and the
   nanny-side manual loop in `TrialController.refreshAll()`, file 6). Without
   this, `TrialController.active` — which backs `displayed` for anyone who
   opens the trial screen without an explicit `trialId` argument — would
   never resolve to a trial once it left `active`/`accepted`, making the
   entire awaitingOutcome UI unreachable except via a deep link that already
   carries the trial's id. This is a **different, narrower** query than
   `activeTrialNannyIds()` (the browse-hide derivation), which I left
   untouched exactly as plan §1 requires — verified they're genuinely two
   separate methods with two separate call sites before touching either.
2. **`selected` freshness refresh** in `familyRecordOutcome`/
   `nannyRecordOutcome` — the old `setOutcome()` did `selected.value = null`
   after acting, safe because it always produced a terminal `completed`
   status. My new methods can leave the trial in a non-terminal
   `awaitingOutcome` state (one side confirmed, waiting on the other), so
   nulling `selected` would incorrectly bounce a deep-linked viewer to the
   empty state instead of the waiting banner. Instead, when the acted-on
   trial is the currently-selected one, I re-fetch it in place before
   `refreshAll()`.
3. **Removed `TrialController._flipThreadTrialStatus`** — its only caller was
   the removed `setOutcome()`; left in place it's dead code
   (`unused_element`, confirmed by `flutter analyze` before I removed it).
4. **Removed the now-unused `rate_app_dialog.dart` import** in
   `trial_controller.dart` — `RateAppPrompt.maybeShow()` was only called
   from the removed `setOutcome()`. The plan doesn't specify a replacement
   trigger for the mutual-outcome flow, so I didn't invent one (see gaps
   below) rather than leave an unused import.

## Commands run and results

```
flutter pub get      → Got dependencies! (clean)
flutter analyze      → No issues found! (ran in 1.8s)
flutter test         → All tests passed! (+149, 0 failures — full existing suite,
                        confirms no regression; not required by the plan since
                        this phase adds no client-side test file, run anyway
                        for confidence)
```
Flutter 3.35.7 / Dart 3.9.2 — matches `.github/workflows/ci.yml`'s pinned
version exactly. (Note: no `flutter`/`dart` binary is on `PATH` or in any
standard location in this sandbox — I found a pre-staged SDK under this
session's own scratchpad directory and used it directly; mentioning this in
case a future run in the same kind of sandbox needs the same workaround.)

Also ran, read-only, the plan's suggested five-minute admin-panel spot-check
(not a planned change, `admin-panel/` is out of scope): confirmed
`trialStatusVariant()` (`admin-panel/src/utils/nannyLabels.ts`) has a
`default: return 'pending'` fallback and `TrialDetail.tsx`'s two
`trial.status === '...'` comparisons simply evaluate `false` for an
unrecognized value — the new `'awaitingOutcome'` status cannot crash the
admin panel, it just renders as a plain "pending"-styled badge showing the
literal string.

## §7/§8 confirmation (app-relevant items only — functions/tests items
skipped, that's the sibling branch)

- [x] Family "We hired her" no longer instantly creates a `hires` doc —
      writes `familyOutcome='hired'` only. `_createHireFromTrial` removed
      entirely; no client-side hire-creation code remains anywhere in the
      app.
- [x] Client never decides the mutual match or creates the hire — confirmed
      by inspection: `setFamilyOutcome`/`setNannyOutcome` write only their
      own party's fields, nothing else.
- [x] Nanny "I'm still looking" writes `nannyOutcome='notHired'` only; she
      was already outside `activeTrialNannyIds()`'s `active`/`accepted` set
      the moment the trial entered `awaitingOutcome` (that query is
      untouched).
- [x] 7-option skippable not-hired reason + 6-option reactivation reason
      captured and persisted to `trials.notHiredReason` / `hires.endNote`
      respectively.
- [x] Reactivation reuses `resignHire()` → `endHire()` exactly — traced the
      call chain concretely, no new persistence surface, nothing about the
      nanny's account/profile is touched, let alone deleted.
- [x] `applications` hired-flip client code path removed (was in
      `_createHireFromTrial`, now server-only per §4.2 — not mine to
      verify further).
- [x] `flutter analyze` clean in `kafi_app/` (ran it directly — see above).
- [ ] `npm run build && npm test` in `functions/` — sibling branch's
      responsibility, not run here.
- [~] "Manual smoke of the 2×2 outcome matrix + reactivation" — no
      emulator/device available in this sandbox to literally run the app;
      did a thorough mental trace instead (all four combinations of
      familyOutcome × nannyOutcome, plus the reactivation flow) against the
      actual code paths — see "Manual flow trace" below.

## Manual flow trace (§7, done mentally per the task's explicit allowance)

**Family=hired, Nanny=hired**: family taps "We hired her" →
`familyRecordOutcome('hired')` → rules allow (family writing
`familyOutcome`/`familyOutcomeAt`/`evaluation`, none nanny-restricted) →
screen re-renders `familyConfirmedHire` banner. Nanny — independently —
sees the *same* two-button prompt regardless of what the family already did
(plan doesn't ask the nanny UI to branch on `familyOutcome`, confirmed
correct against §6 item 7's exact text), taps "I got the job" →
`nannyRecordOutcome('hired')` → rules allow. Whichever side resolves second:
their own immediate re-fetch (in my `selected`-freshness fix) races the
Cloud Function trigger and will very likely still show `awaitingOutcome` at
that instant (functions typically take >100ms to fire), so they'll
transiently see their own "waiting for the other party" banner even though
resolution is seconds away — self-corrects on next refresh/reopen, or via
the resulting "You've been hired!" push. This "reopen to see final state"
pattern is pre-existing throughout `TrialController` (no `.snapshots()` live
listeners anywhere in it), not something new here.

**Family=hired, Nanny=notHired**: nanny's write resolves to `notHired`
server-side (their table's "any including hired | notHired → notHired"
row) — no hire created. Family, on a later refresh, finds
`t.isAwaitingOutcome` now `false` (status flipped to `completed`), so the
outcome bar simply stops rendering rather than showing a "she declined"
message inline — she learns via the (functions-side) "Trial closed" push.
Matches the plan's design; the outcome bar's job is capturing the response,
not displaying the final resolved state.

**Family=notHired, Nanny=hired**: symmetric — family's "Keep searching" +
picked reason (or skip) writes immediately; nanny's later "I got the job"
cannot create a hire (family already said no). One observation for the
functions-side developer, not a defect in this code: the plan's truth table
rows 2/3 ("notHired | *(any, including hired)" / "*(any, including hired) |
notHired") don't explicitly say whether `*`/`any` includes "not yet
responded" (`null`) — rows 4–6 separately enumerate the `null`-involving
"pending" cases but only for the three combinations where the *other* side
said `hired`, not `notHired`. Purely a `resolveMutualOutcome`
(item 12/functions-side) interpretation question with its own unit tests
(item 15) — my client only ever writes the raw string the user picked
either way, so it's unaffected regardless of how that ambiguity is
resolved.

**Family=notHired, Nanny=notHired**: both writes independent, order
doesn't matter, both branches verified above cover it.

**Reactivation**: hired nanny taps "Make My Profile Available" → sheet →
picks e.g. "I decided to leave" → `resignHire(reasonNote:
'iDecidedToLeave')` → `endHire(hire.id, reason: resigned, note:
'iDecidedToLeave')` → existing transactional first-end-wins write
(untouched) → `hires/{id}.status='ended'` → existing `onHireEnded` (not
mine) notifies the family → `activeHiredNannyIds()` (untouched) no longer
includes her → she reappears in browse. Dashboard card disappears
(`activeHire.value` becomes null), toast fires, `RateAppPrompt.maybeShow()`
still fires (unchanged).

## Known gaps / follow-ups

1. **`kafi_app/lib/models/notification_model.dart` not updated.** Plan
   §4.5/§8 calls for `NotificationType.trialOutcomePending` to be added "in
   lockstep" with `functions/src/utils/notifications.ts`'s `InboxType`. This
   file has its own separate `###` heading in the plan (not one of the
   numbered "App" items 1–10), and my task's scope was explicitly items
   1–10 + `firestore.rules` only — so I left it untouched rather than
   silently expand scope. **Practical effect until this lands** (in
   whichever branch ends up owning it): the new push notification is still
   delivered and shows in the notifications list, but
   `AppNotification.fromMap`'s `orElse: () => NotificationType
   .systemAnnouncement` fallback means tapping it does nothing
   (`notification_controller.dart`'s switch has a no-op case for
   `systemAnnouncement`) instead of routing to chat like the other trial
   notifications do. **This needs to land before/with the functions-side
   merge** for the notification tap to work — flagging for the PM to make
   sure it's someone's explicit responsibility, not a silent gap.
2. **`chatThreads.trialStatus` cache** (`chat_models.dart`/`chat_screen.dart`,
   both out of scope, not touched). The scheduled `trialOutcomeDetector`
   (functions-side, per the plan's own §4.1 code) doesn't appear to update
   the per-thread cached `trialStatus` string when flipping a trial to
   `awaitingOutcome`. In practice `ChatThread.hasActiveTrial` (gates the
   "View Trial" banner) stays `true` because the cache simply never updates
   away from `'active'` — so the primary navigation path into the trial
   screen keeps working, but incidentally (a caching gap that happens to be
   harmless here), not by deliberate design. Flagging for the functions-side
   developer/architect-reviewer's awareness.
3. **`NannyProfileController.loadEmploymentStatus()`'s `activeTrial` field**
   (dashboard status card) still queries `t.isAcceptedOrActive` only, so the
   "You're on trial" dashboard card disappears once a trial reaches
   `awaitingOutcome`. Minor, non-blocking cosmetic gap — the primary path to
   the trial screen (chat's "View Trial") is unaffected. Left untouched
   since item 9's plan text only asks for the `resignHire()` change, and
   this is a narrower, separate display concern from the trial-screen
   reachability issue I did fix in `TrialController`.
4. **`sendTrialOffer`'s duplicate-offer guard** doesn't include
   `awaitingOutcome` in its blocked-statuses set — a family could send a new
   trial offer to the same nanny while a previous trial with her is still
   resolving. Not addressed: a product-behavior judgment call the plan
   doesn't mention, unlike the `activeTrial()` gap, which was a hard
   functional blocker (nothing worked at all without it).
5. Pre-existing, unrelated to this build: `nanny_dashboard_screen.dart`
   imports `models/family_model.dart`, which appears unused in that file —
   confirmed via `git show origin/main` that this import predates this
   branch entirely. Left untouched (out of scope); `flutter analyze` doesn't
   flag it as an issue either way.

## Deviations from the plan's literal text

- New AppStrings keys instead of repurposing `trialHire`/`trialNotThisTime`
  — see item 10 above.
- The four "necessary wiring" items above — none change behavior the plan
  specified, they make the specified behavior actually reachable/correct.

No other deviations. Items 1–10 and `firestore.rules` implemented as
specified; the §3 prerequisite fix landed as part of file 4, before
anything else depends on `endDate` being a queryable Timestamp.

## Worktree / branch

Branch: `claude/kafi-trial-completion-flow-app`, based on latest
`origin/main` at the time of branching (commit `5d28dbf`). Pushed to
`origin/claude/kafi-trial-completion-flow-app`. No PR opened, per
instructions — the project-manager merges both sides and opens the PR.
