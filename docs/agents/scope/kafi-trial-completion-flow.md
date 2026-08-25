---
slug: kafi-trial-completion-flow
project: kafi
title: Trial-completion workflow with mutual hire confirmation, nanny outcome capture, and hired-nanny reactivation
owner: project-manager
status: READY_FOR_ARCH
updated: 2026-08-15
epic: kafi-profile-trial-overhaul (phase 3 of 3 — parallel with kafi-nanny-profile-fields and kafi-family-profile-fields)
---

## Requirements (verbatim from Waseem)

**Family** — after the trial ends, show a simple notification: "How did the
trial go?" Show two large options: "We hired her" / "Keep searching". If "We
hired her" is selected, end the flow with no additional questions. If "Keep
searching" is selected, show an *optional* reason (skippable): Not the right
match / Salary / Schedule / Location / Nanny declined / Found someone else /
Other.

**Nanny** — after the trial ends, show "What happened after your trial?" —
"I got the job" / "I'm still looking". If "I'm still looking", immediately
make her profile available in search again. If "I got the job", show "Great!
We're waiting for the family to confirm." Once **both** the family and nanny
confirm they hired each other: mark the nanny as Hired, hide her profile from
search, keep the account/all profile info saved.

**Returning Hired Nanny** — when a hired nanny returns, show "Looking for a
job again?" with a "Make My Profile Available" button. On tap, ask "Why are
you looking again?": Job didn't work out / Family ended the employment / I
decided to leave / Temporary job ended / Other / Prefer not to say. After
selection, make the profile available in search immediately.

## Decision locked in during scoping (do not re-litigate)

**Mutual confirmation gates Hired status.** The family's "We hired her" is a
*pending* signal, not an instant hire — replacing today's single-tap instant
hire. The nanny is only marked Hired (and only then hidden from search) once
she *also* confirms "I got the job". Design the state machine so a mismatch
(e.g. family says hired, nanny never responds or says "still looking") does
**not** mark her Hired — she stays visible/available until both sides agree.

## Current state (investigated; verify before planning — line numbers may drift)

All paths relative to `kafi_app/` unless noted (Cloud Functions are in
`functions/src/`).

### What exists today
- **`TrialModel`** (`lib/models/trial_model.dart`): `TrialStatus` enum (line
  4) — `pending, countered, accepted, declined, active, completed,
  cancelled`. **No distinct "hired" status** — outcome is a free-form
  `outcome` `String?` field (observed values `'hired'`/`'failed'`, no enum),
  plus `outcomeAt` (`DateTime?`). **No per-party confirmation fields exist at
  all** (only `nannyConfirmedPayment`, which is about payment receipt, not
  hire confirmation). `isActive`/`isAccepted` getters (lines 159–169) are
  purely status-based — **nothing on this model is date-driven**;
  `endDate.difference(DateTime.now())` (`remaining`, line 163) is only used
  for the countdown display, never compared anywhere to auto-transition
  status.
- **`TrialController.setOutcome()`** (`lib/controllers/trial_controller.dart:533-565`):
  called directly (no confirmation dialog) from `trial_screen.dart`'s
  "Hire!"/"Not this time" buttons. On `outcomeLabel: 'hired'` +
  `isFamily == true`, immediately calls `_createHireFromTrial()` (lines
  571–600), which creates a `hires/{hire_<trialId>}` doc with
  `HireStatus.active` right away — **this is the instant single-sided hire
  that must become the pending/gated flow**. After `setOutcome` runs,
  `selected.value = null` and the trial screen falls back to its empty state
  immediately (no outcome-summary screen exists).
- **`trial_screen.dart`** `_outcomeBar()` (lines 501–578): family sees
  "Hire!"/"Not this time" only while `t.isActive`; nanny sees only a "Cancel
  trial" button, and only while `status` is `pending`/`accepted` — **once
  status is `active`, the nanny has zero outcome-related UI, all the way
  through and past the end date** (`_remainingLabel` just freezes at `'0d 0h
  0m'` once negative — no "overdue" signal of any kind).
- **No date-driven trial-end detection exists anywhere.** Confirmed
  exhaustively: `functions/src/triggers/scheduled.ts` is the *only* file using
  `onSchedule` in the whole functions tree, and defines exactly 3 jobs —
  `trialStartingReminder` (checks *upcoming* starts, not ends),
  `subscriptionExpiringReminder`, `subscriptionExpiredEnforcer`. **None check
  `endDate <= now` for trials.** A trial can sit in `active` status
  indefinitely past its end date until the family manually taps a button. This
  phase must add a new scheduled function for this.
- **`functions/src/triggers/trial.ts`**: `onTrialEnded` (line 193) is
  Firestore-triggered (fires off a status *write*, not a clock) on transition
  into a terminal status. When `after.status === 'completed'` it sends an
  **identical, generic** "trial complete" push to both parties regardless of
  hire/not-hire outcome (lines 217–254) — never says "you were hired" or "you
  weren't selected" to the nanny explicitly. `onHireCreated`
  (`functions/src/triggers/stats.ts:87-110`) fires on `hires/{id}` creation
  and separately pushes the nanny "🎉 You've been hired!" — this whole
  notification chain needs to be redesigned around the new
  end-of-trial → dual-prompt → mutual-confirm → hire sequence; expect to
  touch/replace parts of both `onTrialEnded` and the hire-creation trigger,
  and to add the new "Keep searching" reason capture and the nanny's "still
  looking"/"got the job" prompts as new writes.
- `NotificationType.trialEndingSoon` exists in
  `lib/models/notification_model.dart:11` and the matching
  `InboxNotifType` union entry exists in
  `functions/src/utils/notifications.ts:81`, but **nothing ever writes it** —
  confirmed zero producers. Available to use if the design calls for an
  advance "your trial ends soon" nudge (not explicitly required by the spec,
  optional).
- **Nanny hidden-from-search is fully *derived*, not stored.**
  `IHireService.activeHiredNannyIds()`
  (`lib/services/firebase/firestore_hire_service.dart:42-55`, queries
  `hires` where `status == active`) and `ITrialService.activeTrialNannyIds()`
  (`lib/services/firebase/firestore_trial_service.dart:48-60`, queries
  `trials` where `status in [active, accepted]`) are unioned in
  `BrowseController._engagedNannyIds()`
  (`lib/controllers/browse_controller.dart:105-119`, both queries
  `.limit(1000)`, fail-open on error) and used to filter browse results. **This
  means: ending a `hires` doc (status → not-active) or a `trials` doc leaving
  `active`/`accepted` automatically makes a nanny reappear in browse — no
  separate "make available" flag/toggle exists or is needed for the
  underlying visibility mechanism.** `NannyModel` has no "hired" status field
  of its own; the only tangential field is the self-reported, disconnected
  `AvailabilityStatus` enum (`availableNow, availableFrom, onTrial`,
  `nanny_model.dart:17,273`), used only for match-score dimming in
  `match_service.dart` (~lines 198–199), never auto-written by any hire/trial
  event today.
- **Ending a hire already exists and already un-hides the nanny** (via the
  derived mechanism above): nanny-side "Resign" —
  `NannyProfileController.resignHire()`
  (`lib/controllers/nanny_profile_controller.dart:231-241`) →
  `_hireService.endHire(hire.id, reason: HireEndReason.resigned)`, surfaced on
  `nanny_dashboard_screen.dart`'s `_statusCard()` (lines 241–355). Family-side
  "End employment" — `ChatController.endActiveHire()`
  (`lib/controllers/chat_controller.dart:48-68`,
  `reason: HireEndReason.terminated`), from the chat header. **The "Returning
  Hired Nanny" flow should call the same underlying hire-ending mechanism**
  (likely `resignHire()` or a close variant) rather than invent a second,
  parallel "available/hidden" flag — the reason-capture UI ("Why are you
  looking again?") is new, but it should feed into (or replace/extend) the
  existing resign path, not bypass it.
- `applications/{appId}` also gets a `hired` status flip
  (`_apps.markHired`, called from `_createHireFromTrial`) — check whether this
  needs to move to the new mutual-confirm gate too (it currently fires at the
  same instant as the old single-sided hire).

### What's genuinely new here (no existing analog)
- Any per-party hire-confirmation state on `TrialModel` (or wherever the
  architect decides it belongs — could be new fields on `TrialModel`, or a new
  status value, or a small new sub-collection/doc — architect's call).
- The scheduled Cloud Function that detects `endDate <= now` on
  active/un-resolved trials and kicks off the end-of-trial sequence.
- The family's "How did the trial go?" notification-triggered prompt + the
  optional "Keep searching" reason capture (7 options).
- The nanny's "What happened after your trial?" prompt + the "waiting for
  family to confirm" interim state/message.
- The "Returning Hired Nanny" screen/banner ("Looking for a job again?" →
  "Make My Profile Available" → reason picker, 6 options) — likely surfaces on
  `nanny_dashboard_screen.dart` alongside/replacing the existing "Resign"
  affordance when her status is Hired; architect's call on exact placement.

## Explicit scope boundaries

**In scope**: `TrialModel`, `TrialController`, `trial_screen.dart` (family +
nanny outcome UI), `nanny_dashboard_screen.dart` (reactivation entry point),
`functions/src/triggers/trial.ts`, `functions/src/triggers/scheduled.ts` (new
scheduled function), `functions/src/triggers/stats.ts` (hire-creation
notification, if the mutual-confirm redesign requires moving where it fires),
`ApplicationModel`/application-hired-flip if it needs to move to the new gate,
`functions/src/utils/notifications.ts` (new `InboxType` entries as needed),
any new reason-enum/model this requires (e.g. a "not hired reason" and a
"reactivation reason" enum/constant list — 7 and 6 options respectively, both
verbatim from the requirements above).

**Out of scope**: nanny/family profile *field* changes (phases 1–2 — this
phase only touches trial/hire state, not the profile screens those own,
though it does read `NannyModel`/`FamilyModel`). Do not add a stored
"available/hidden" boolean on `NannyModel` that duplicates the existing
derived mechanism — reuse it. Payments/billing are unrelated and untouched.

## Acceptance criteria

- Family's "We hired her" no longer instantly creates a `hires` doc — it
  records a pending family-side confirmation only.
- Hired status (and the resulting search-hide, via the existing derived
  mechanism) is only reached once **both** parties have confirmed; a family
  "hired" + nanny "still looking" (or no nanny response) never marks her
  Hired.
- Nanny selecting "I'm still looking" makes her immediately visible in
  browse again (verify this actually flows through the existing
  `activeTrialNannyIds`/`activeHiredNannyIds` derivation — i.e. the trial's
  status genuinely leaves `active`/`accepted`, it isn't just a UI-only flag).
- A new scheduled Cloud Function detects `endDate <= now` for trials still
  awaiting an outcome and fires the family "How did the trial go?" and nanny
  "What happened after your trial?" prompts (via the existing
  `writeInbox`/`sendNotification` pattern in `functions/src/utils/notifications.ts`,
  consistent with every other notification in the app).
- "Keep searching" reason (7 options, optional/skippable) and "reactivation"
  reason (6 options) are captured and persisted somewhere reviewable (at
  minimum on the trial/hire-end record — visible to admin/support is a plus
  but not required unless trivial).
- "Returning Hired Nanny" flow reuses the existing hire-ending mechanism
  under the hood; ending it still preserves the nanny's account/profile data
  (nothing deleted, only status/derived-visibility changes) — this must hold
  for both the resign-driven and the new reactivation-driven paths.
- `flutter analyze` (CI) and Cloud Functions `npm run build && npm test`
  (CI) both pass; add/update functions tests for the new scheduled function
  and the redesigned notification triggers, matching the existing test
  coverage style in `functions/`.
