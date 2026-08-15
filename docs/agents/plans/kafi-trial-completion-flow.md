---
slug: kafi-trial-completion-flow
project: kafi
title: Trial-completion workflow with mutual hire confirmation, nanny outcome capture, and hired-nanny reactivation
owner: architect
status: PLANNING
blocker: SCOPE_PREMISE_INACCURATE — the scope's "Current state (investigated)" section describes a hire/employment + search-visibility subsystem that does not exist in the repo. This materially enlarges the work (build vs. adapt) and makes three of the scope's explicit hard constraints impossible as literally worded. Requires PM + Waseem re-confirmation before READY_FOR_BUILD. See §0.
updated: 2026-08-15
epic: kafi-profile-trial-overhaul (phase 3 of 3 — parallel with kafi-nanny-profile-fields and kafi-family-profile-fields)
---

# Plan — Trial completion, mutual hire confirmation, reactivation

## 0. BLOCKER — read before building (scope premise is inaccurate)

I read the actual source before planning (CLAUDE.md §4). The scope doc's
requirements (the verbatim Waseem block) are real and implementable, but its
**"Current state (investigated)" section describes code that does not exist.**
Every claim below was verified by direct file reads, `ls`, `stat`, and `find`
(the repo's content-search was returning phantom line references for some
paths — e.g. it cited `functions/src/triggers/stats.ts:87` and
`firestore.rules:305`, both of which do not exist; `firestore.rules` is 193
lines and there is no `stats.ts`. All facts here come from authoritative reads,
not search).

### 0.1 Scope claim vs. verified reality

| Scope doc claims exists | Verified reality |
| --- | --- |
| `hires/{id}` collection, `IHireService`, `firestore_hire_service.dart`, `HireStatus`, `HireEndReason` | **None exist.** No `IHireService`, no `firestore_hire_service.dart`, no `HireStatus`/`HireEndReason` enums anywhere in `kafi_app/`. |
| `TrialController.setOutcome → _createHireFromTrial()` creating a `hires` doc (instant single-sided hire) | **`_createHireFromTrial` does not exist.** `setOutcome` (`trial_controller.dart:329-340`) only calls `_trials.recordOutcome`, which writes `status=completed` + a free-form `outcome` label to the trial doc. **No hire object is ever created, client- or server-side.** |
| `IHireService.activeHiredNannyIds()` + `ITrialService.activeTrialNannyIds()` unioned in `BrowseController._engagedNannyIds()` to hide engaged nannies from search | **No such derivation exists.** `browse_controller.dart` has no `_engagedNannyIds`. `browseNannies` (`firestore_job_service.dart:14-63`) filters only `nannies.where('status','==','approved')` (+ optional nationality/jobType). **On-trial and would-be-hired nannies are NOT hidden from browse today.** `families/{id}.activeTrialNannyIds` is a **family-doc** field used only by `firestore.rules` (`hasActiveTrialWith`) for chat/subscription bypass — it does not hide nannies from search. |
| `NannyProfileController.resignHire()` → `_hireService.endHire(...)`, surfaced on `nanny_dashboard_screen.dart`'s `_statusCard()` | **`resignHire()` does not exist.** `nanny_profile_controller.dart` has no hire methods. `nanny_dashboard_screen.dart` (a `GetView<NannyProfileController>`) has no `_statusCard()` and no hired/resign UI — only hero + quality-score card + jobs list. |
| `ChatController.endActiveHire()` family "End employment" from chat header | **Does not exist.** `chat_controller.dart` has no hire logic. |
| `functions/src/triggers/stats.ts` with `onHireCreated`/`onHireEnded` pushing "🎉 You've been hired!" | **`stats.ts` does not exist.** No `onHireCreated`/`onHireEnded`. The only trial pushes are in `trial.ts`. |
| `onTrialEnded` sends "identical generic push to **both** parties" | Partly false. `onTrialEnded` (`trial.ts:89-125`) on `completed` sends **one** generic FCM push to the **family only** ("Trial completed / Evaluate the nanny"). The nanny gets nothing. |
| `applications/{appId}` `_apps.markHired` flip fires alongside the instant hire | **`markHired` is never called** from any trial/hire path. `ApplicationStatus.hired` exists in the enum but nothing writes it. |
| Deliver prompts "via the existing `writeInbox`/`sendNotification` pattern"; new `InboxType`/`InboxNotifType` union in `notifications.ts:81` | **No `writeInbox`, no `InboxType`/`InboxNotifType` union.** `notifications.ts` exposes only `sendNotification` (FCM push) + `getUser/getNanny/getFamily`. **There is no server-side producer of the in-app `notifications` collection at all** (rules `create: if isAdmin()` only; Flutter only *reads* it — `fcm_notification_service.dart:337-375`). |

### 0.2 What IS accurate in the scope
- No date-driven trial-end detection exists; `scheduled.ts` has only
  `trialStartingReminder` (upcoming starts), `subscriptionExpiringReminder`,
  `subscriptionExpiredEnforcer`. A new `endDate <= now` job is genuinely needed.
- `TrialStatus` = `{pending, countered, accepted, declined, active, completed,
  cancelled}`; no "hired" status; outcome is a free-form `String?`. No per-party
  hire-confirmation fields (`nannyConfirmedPayment` is about *payment*, not hire).
- `NotificationType.trialEndingSoon` exists in Dart (`notification_model.dart:11`)
  and is unused.
- The `hires` collection **is scaffolded but never produced**: `firestore.rules`
  has **no** `hires` block (so client writes to it are denied by default), yet
  `delete.ts:132-146` cascades a `hires` cleanup and the admin panel renders
  `stats.hiresCount`. So `hires` is a *designed-but-unimplemented* collection.

### 0.3 Why this blocks a clean READY_FOR_BUILD
1. **Build, not adapt.** The scope frames this phase as "make the *existing*
   hire flow mutual-confirm, reuse the *existing* derived hide mechanism, reuse
   the *existing* resign path." None of those exist. Delivering the requirements
   means **building the hire-outcome representation, the search-visibility
   mechanism, and the reactivation path from scratch** — roughly 2–3× the implied
   size. That is a scope change the PM must re-confirm with Waseem (CLAUDE.md §4:
   flag as scope risk; do not invent scope).
2. **Three hard constraints are impossible as literally worded** and need a
   confirmed substitute:
   - "Reuse the existing derived `activeTrialNannyIds`/`activeHiredNannyIds`
     hide mechanism" → that mechanism does not exist; §2 proposes building a
     derived-from-`trials` exclusion in the browse path (honoring the *intent*:
     derived, no stored nanny flag).
   - "Call into the SAME underlying `resignHire()`/`endHire()` mechanism" →
     there is no such mechanism; §2 proposes a single shared trial-status
     transition that both resign and reactivation route through.
   - "Deliver via the existing `writeInbox`/`sendNotification` pattern" → there
     is no `writeInbox` and no in-app-notification producer; §2 proposes
     delivery via trial-doc state (rendered in-app, matching how every trial
     screen already works) + the existing FCM `sendNotification` nudge.
3. **One genuine architecture fork** (see §3, D1): represent "Hired" **on the
   trial doc** (proposed) vs. **finally implement the `hires` collection** the
   rules/`delete.ts`/admin scaffolding anticipates. This has data-model, rules,
   and admin-panel consequences and should be a conscious, confirmed decision,
   not one an architect makes unilaterally under an inaccurate scope.

**Recommended PM action:** re-confirm the enlarged scope with Waseem, answer the
D1–D5 decisions in §3, then I flip this doc to `READY_FOR_BUILD`. The design in
§2–§9 below is complete and internally consistent against the *real* code, so
approval is the only gate — no further investigation is required.

---

## 1. Architecture summary

Everything hangs off the **trial document** as the single source of truth (it
already has read/write rules for both parties, is the object both the app and
`trial.ts` revolve around, and needs no new collection/rules/read-path). The
flow becomes a small, explicit state machine layered on `TrialStatus`:

```
active  ──(scheduled: endDate<=now)──►  awaitingOutcome
                                          │
     family writes familyOutcome ∈ {hired, searching}
     nanny  writes nannyOutcome  ∈ {hired, searching}
                                          │
        server trigger resolves the 2×2 matrix:
          both 'hired'            → status = hired      (nanny hidden from browse)
          either 'searching'      → status = notHired   (nanny visible in browse)
          only one side responded → stays awaitingOutcome (pending; nanny stays hidden)
                                          │
   Returning Hired Nanny: nanny sets reactivationReason
          hired ──► notHired  (same transition path → nanny reappears in browse)
```

**Search visibility is derived, never stored on the nanny.** A nanny is hidden
from browse iff she has any trial whose status ∈ {`accepted`, `active`,
`awaitingOutcome`, `hired`}. Leaving that set (→ `notHired`/`declined`/
`cancelled`) makes her reappear. This is the derived mechanism the scope
*assumed existed*, built here in the browse path.

**Mutual gate is resolved server-side** (a `trials` `onUpdate` trigger), so a
family "hired" + nanny silent/`searching` can never reach `hired` — the gate is
authoritative and race-free; each party only ever writes its own outcome field.

Data flow: scheduled fn flips `active→awaitingOutcome` + pushes both parties →
app renders outcome prompt from trial state → each party writes its own field →
server trigger resolves → status→`hired`/`notHired`, recomputes
`activeTrialNannyIds`, sends the single outcome-specific push, (optionally)
flips a linked application to `hired` and bumps `stats.hiresCount`.

## 2. Reuse map (existing pieces the build MUST use, not reinvent)

- **State + persistence:** `TrialModel` (add fields; keep `copyWith`/`toMap`/
  `fromMap` tolerant-parse conventions exactly — see the existing `_parseDate`
  and `firstWhere(orElse:)` patterns). `firestore_trial_service.dart` +
  `i_trial_service.dart` for all writes (add methods; do not write Firestore
  from controllers directly — the service boundary is consistent across the app).
- **Controller pattern:** `TrialController` (GetX) already owns
  `recordOutcome`/`refreshAll`/`displayed`/`selected`/`active`. Extend it; keep
  `Get.snackbar(AppStrings.*.tr, ...)` + `isLoading` conventions.
- **Notifications:** functions' `sendNotification(tokens, {title, body, data})`
  + `getFamily`/`getUser` from `utils/notifications.ts`. This is the ONLY
  delivery mechanism; reuse it (do not invent `writeInbox`).
- **Scheduled job style:** copy `trialStartingReminder` (`scheduled.ts:5-43`)
  exactly — `onSchedule('every 1 hours')`, Timestamp range query, `.limit(200)`,
  `Promise.all`, per-doc idempotency flag (`reminderSent` → here
  `outcomePromptSent`).
- **Terminal-recompute helper:** `onTrialEnded` (`trial.ts:89-125`) already
  recomputes `families/{id}.activeTrialNannyIds` and stamps
  `subscription.lastTrialEndedAt`. Extend its terminal set; do not duplicate the
  recompute logic elsewhere.
- **UI / design system:** `kafi_theme.dart` (`KafiColors`, `KafiTheme.fredoka/
  nunito`), `KafiPrimaryButton` (`variant: KafiButtonVariant.green/…`), and the
  existing card idioms already in `trial_screen.dart` (white card, radius 11–13,
  `KafiColors.cardBorder`, green gradient CTA). The reason pickers must reuse the
  existing `AlertDialog`/`showModalBottomSheet` idiom already in
  `trial_screen.dart` (`_confirmCancel`, `_reportIssueDialog`) — no new bespoke
  widgets, no hardcoded one-off colors.
- **Strings:** `AppStrings` + `l10n/locales/en_us.dart` + `ar_ae.dart` (every new
  user-facing string added to all three; the epic and this repo require `.tr`
  everywhere and Arabic for new keys).
- **Enums:** add the two reason lists as Dart enums beside the models (mirror
  `HireEndReason`-style naming the scope expected, but as trial-local enums).

## 3. Decisions requiring PM/Waseem confirmation (gates for READY_FOR_BUILD)

- **D1 — "Hired" representation.** *Proposed:* represent on the **trial doc**
  (`TrialStatus.hired`), NOT a new `hires` collection. Smallest change; no new
  rules/read-path; single source of truth. *Alternative:* finally implement the
  scaffolded `hires` collection (needs a new `firestore.rules` block, a producer
  trigger, a client read path, and touches admin `stats.hiresCount`). Confirm
  which. (Everything in §5 assumes the proposed trial-doc approach.)
- **D2 — Resolution locus.** *Proposed:* server-side trigger resolves the mutual
  gate (authoritative). Confirm we accept a Cloud-Functions round-trip of latency
  before the nanny sees "Hired" (vs. client-side resolution, which is racier and
  can't be trusted for the gate).
- **D3 — Search-visibility mechanism.** *Proposed:* derived exclusion in the
  browse path from `trials` status (§5, file 8). Confirm this is an acceptable
  substitute for the (non-existent) mechanism the scope named, and that adding a
  pre-query to `browseNannies` is acceptable (one extra indexed query per browse).
- **D4 — Application hired-flip.** *Proposed:* at the resolution gate, best-effort
  flip a *linked* `applications/{id}` (matching familyId+nannyId) to `hired`.
  Trials created from browse have no application → no-op. Confirm this is enough
  (the scope asks only whether it should move to the gate — it should, and does).
- **D5 — Reactivation placement.** *Proposed:* `nanny_dashboard_screen.dart`, a
  new card shown when the nanny has a `hired` trial. This requires wiring
  `TrialController` into that screen (today it only knows `NannyProfileController`).
  Confirm dashboard placement (vs. a dedicated banner on the nanny shell).

## 4. New enums / constants (verbatim option lists from the scope)

Add to a new file `kafi_app/lib/models/trial_outcome_reasons.dart` (or inline in
`trial_model.dart` — architect default: separate file, single responsibility):

- `NotHiredReason` (family "Keep searching", optional/skippable — 7 options,
  verbatim): `notTheRightMatch`, `salary`, `schedule`, `location`,
  `nannyDeclined`, `foundSomeoneElse`, `other`. Persisted as `.name` string in
  `trials.notHiredReason` (nullable — skippable).
- `ReactivationReason` (nanny "Why are you looking again?" — 6 options, verbatim):
  `jobDidntWorkOut`, `familyEndedEmployment`, `iDecidedToLeave`,
  `temporaryJobEnded`, `other`, `preferNotToSay`. Persisted as `.name` string in
  `trials.reactivationReason`.

Each enum gets a `label` getter (English) used by the UI; UI labels route through
`AppStrings` for l10n. Reason strings are stored as the stable `.name`, not the
localized label.

## 5. File-by-file change list (in build order)

### App (`kafi_app/`)

**1. `lib/models/trial_model.dart` — MODIFY**
- Extend `enum TrialStatus` with `awaitingOutcome, hired, notHired` (append at
  end so existing `.name` persistence and `fromMap` orElse stay stable).
- Add fields (all nullable/defaulted, additive — no destructive migration):
  `String? familyOutcome` ('hired'|'searching'), `String? nannyOutcome`,
  `DateTime? familyOutcomeAt`, `DateTime? nannyOutcomeAt`,
  `String? notHiredReason`, `String? reactivationReason`,
  `DateTime? reactivatedAt`, `DateTime? endReachedAt`,
  `bool outcomePromptSent = false`.
- Thread them through the constructor, `copyWith`, `toMap`, `fromMap` using the
  existing `_parseDate` + `== true`/`?.toString()` conventions.
- Add getters: `bool get isAwaitingOutcome => status == TrialStatus.awaitingOutcome;`
  `bool get isHired => status == TrialStatus.hired;`
  `bool get familyConfirmedHire => familyOutcome == 'hired';`
  `bool get nannyConfirmedHire => nannyOutcome == 'hired';`
- Update `isAcceptedOrActive`-style engagement helper OR add
  `bool get engagesNanny => const {TrialStatus.accepted, TrialStatus.active, TrialStatus.awaitingOutcome, TrialStatus.hired}.contains(status);`
  (used by the browse-hide derivation and the offer-dedup guard).
- Edge cases: unknown status string → `fromMap` already falls back to `pending`;
  keep. `outcome` free-form field is retained for back-compat but no longer the
  hire signal.

**2. `lib/models/trial_outcome_reasons.dart` — CREATE**
- The two enums + `label` getters from §4. No logic.

**3. `lib/services/interfaces/i_trial_service.dart` — MODIFY**
- Add:
  - `Future<void> setFamilyOutcome(String trialId, {required String outcome, String? notHiredReason});`
  - `Future<void> setNannyOutcome(String trialId, {required String outcome});`
  - `Future<void> reactivateHiredNanny(String trialId, {required String reason});`
  - `Future<List<String>> engagedNannyIds();` (returns nanny ids with a trial
    whose status ∈ engagement set — for browse-hide).

**4. `lib/services/firebase/firestore_trial_service.dart` — MODIFY**
- **Fix (required for the scheduled query):** persist `endDate` as a `Timestamp`
  in `sendOffer` (today only `startDate` is converted; `endDate` is written as an
  ISO string via `toMap`, so a `where('endDate','<=',Timestamp)` server query
  would never match). Add `data['endDate'] = Timestamp.fromDate(trial.endDate);`
  next to the existing `startDate` conversion. Also set it in `applyCounterAndAccept`
  if the counter changes `startDate` (recompute endDate = startDate + durationDays).
- Implement the four new interface methods:
  - `setFamilyOutcome`: `update({'familyOutcome': outcome, 'familyOutcomeAt':
    serverTimestamp(), if notHiredReason != null 'notHiredReason': notHiredReason})`.
  - `setNannyOutcome`: `update({'nannyOutcome': outcome, 'nannyOutcomeAt':
    serverTimestamp()})`.
  - `reactivateHiredNanny`: `update({'status': notHired.name, 'reactivationReason':
    reason, 'reactivatedAt': serverTimestamp()})`.
  - `engagedNannyIds`: query `trials.where('status', whereIn: ['accepted','active',
    'awaitingOutcome','hired']).limit(1000)`, map to `nannyId`, dedupe. Fail-open
    (return `[]` on error) so browse never hard-fails — mirror the scope's
    intended fail-open behavior.
- Note: resolution (both→hired etc.) is **not** done here; it's server-side (file 11).

**5. `lib/controllers/trial_controller.dart` — MODIFY**
- Replace the family outcome path: `setOutcome(TrialStatus.completed,
  outcomeLabel: 'hired'|'failed')` is removed from the family CTA. Add:
  - `Future<void> familyHired(String trialId)` → `_trials.setFamilyOutcome(id,
    outcome: 'hired')`; refresh; snackbar "Waiting for {nanny} to confirm" (the
    family side is now pending, not terminal).
  - `Future<void> familyKeepSearching(String trialId, {NotHiredReason? reason})`
    → `_trials.setFamilyOutcome(id, outcome: 'searching', notHiredReason:
    reason?.name)`; refresh.
  - `Future<void> nannyGotJob(String trialId)` → `_trials.setNannyOutcome(id,
    outcome: 'hired')`; refresh.
  - `Future<void> nannyStillLooking(String trialId)` → `_trials.setNannyOutcome(id,
    outcome: 'searching')`; refresh. (Server resolves to `notHired` → nanny
    reappears in browse; acceptance criterion "leaves active/accepted set" is met
    because `notHired` is outside the engagement set.)
  - `Future<void> reactivate(String trialId, ReactivationReason reason)` →
    `_trials.reactivateHiredNanny(id, reason: reason.name)`; refresh.
- `refreshAll`: include `awaitingOutcome` (and expose the nanny's `hired` trial)
  so the nanny side surfaces the prompt and the dashboard reactivation card.
  Today the nanny branch only sets `active` when `t.isActive`; broaden to also
  track an `awaitingOutcome` trial and a `hired` trial (add
  `Rx<TrialModel?> awaitingOutcomeTrial`, `Rx<TrialModel?> hiredTrial`).
- Keep all existing methods; do not remove `recordOutcome` (still used for
  accept→active promotion).

**6. `lib/views/family/trial_screen.dart` — MODIFY**
- `_outcomeBar` family branch: gate the two big buttons on
  `t.isAwaitingOutcome` (not `t.isActive`). Relabel to "We hired her" /
  "Keep searching" (existing green-gradient CTA + white outline idiom).
  - "We hired her" → `controller.familyHired(t.id)` (no further questions;
    show the pending confirmation banner using `_banner(...)`).
  - "Keep searching" → open the **optional** reason sheet (7 options +
    "Skip") reusing the `showModalBottomSheet`/`AlertDialog` idiom; on pick or
    skip → `controller.familyKeepSearching(t.id, reason: picked)`.
  - When `t.familyConfirmedHire && !t.nannyConfirmedHire`: render the
    "We're waiting for {nanny} to confirm" banner instead of buttons.
- Nanny branch: today the nanny has no outcome UI once `active`. When
  `t.isAwaitingOutcome`, render "What happened after your trial?" with
  "I got the job" / "I'm still looking":
  - "I got the job" → `controller.nannyGotJob(t.id)`; if family not yet
    confirmed, swap to "Great! We're waiting for the family to confirm." banner.
  - "I'm still looking" → `controller.nannyStillLooking(t.id)`.
- Add an "overdue" cue: `_remainingLabel` should show a "Trial ended — awaiting
  your response" state when `isAwaitingOutcome` instead of frozen `0d 0h 0m`.
- Header status badge: reflect `awaitingOutcome`/`hired` states (reuse the
  existing badge container; new label strings via `AppStrings`).
- All new copy via `AppStrings.*.tr`.

**7. `lib/views/nanny/nanny_dashboard_screen.dart` — MODIFY (D5)**
- Wire in `TrialController` (via `Get.find`). When
  `TrialController.hiredTrial.value != null`, render a "Looking for a job
  again?" card (reuse the white card + rose CTA idiom already in this file;
  `KafiColors.rose/roseD`, `KafiTheme` text styles — no new palette).
- CTA "Make My Profile Available" → open the 6-option reason picker (reuse the
  dialog idiom) → `controller.reactivate(trialId, reason)` → card disappears,
  nanny is browseable again (derived; nothing deleted from her profile).
- Keep the screen a thin view; all logic in `TrialController`.

**8. `lib/services/firebase/firestore_job_service.dart` + `lib/controllers/browse_controller.dart` — MODIFY (D3)**
- In `browseNannies` (or, preferably, in `BrowseController.refreshList` to keep
  the service query-shape simple): after fetching approved nannies, exclude any
  whose id ∈ `ITrialService.engagedNannyIds()`. Inject `ITrialService` where the
  exclusion runs. Fail-open (if the engaged query throws, show all — never hide
  the whole board). This is the derived hide/unhide mechanism; reactivation and
  "still looking" both drop the nanny out of the engaged set automatically.
- Add a Firestore index note (composite index on `trials.status`) if the emulator
  flags it; single-field `status` `whereIn` needs no composite index.

**9. `lib/l10n/app_strings.dart` + `locales/en_us.dart` + `locales/ar_ae.dart` — MODIFY**
- Add keys for: family prompt title/body, "We hired her", "Keep searching",
  the 7 not-hired reasons + "Skip", the pending "waiting for nanny/family to
  confirm" banners, nanny prompt title/body, "I got the job", "I'm still
  looking", "Great! We're waiting…", reactivation card title/CTA, the 6
  reactivation reasons, and the "trial ended — awaiting response" label. English
  + Arabic for every new key.

### Cloud Functions (`functions/src/`)

**10. `triggers/scheduled.ts` — MODIFY (new job `trialOutcomeDetector`)**
- `export const trialOutcomeDetector = onSchedule('every 1 hours', …)` modeled
  exactly on `trialStartingReminder`:
  - Query `trials.where('status','==','active').where('endDate','<=',
    Timestamp.fromDate(now)).limit(200)`.
  - Per doc, skip if `outcomePromptSent === true`.
  - `doc.ref.update({status:'awaitingOutcome', endReachedAt: serverTimestamp(),
    outcomePromptSent:true})`.
  - Push family: title "How did the trial go?", body prompts hire/keep-searching,
    `data:{type:'trial_outcome_family', trialId}`.
  - Push nanny (via `getUser(trial.nannyId)`): title "What happened after your
    trial?", `data:{type:'trial_outcome_nanny', trialId}`.
  - Use `getFamily`/`getUser` for tokens; guard empty token arrays (existing
    pattern). Wrap per-doc work so one failure doesn't abort the batch.
- Export from `index.ts` (file 12).

**11. `triggers/trial.ts` — MODIFY (add resolver; adapt `onTrialEnded`)**
- Add `export const onTrialOutcomeResolved = onDocumentUpdated('trials/{trialId}',
  …)`:
  - Fire only when `familyOutcome` or `nannyOutcome` changed and status is still
    `awaitingOutcome`.
  - Resolve the 2×2:
    - both `'hired'` → `update({status:'hired'})`; push nanny "🎉 You're hired!"
      + push family "Confirmed — you hired {nanny}"; (D4) best-effort flip a
      linked `applications` doc to `hired`; (D1) if the `hires`-collection
      alternative is chosen, create the hire doc + bump `stats.hiresCount` here
      instead.
    - either `'searching'` → `update({status:'notHired'})`; push the nanny an
      outcome-specific "trial ended — you're back in search" message and the
      family a neutral confirmation. (No generic double push.)
    - only one side set → do nothing (stay `awaitingOutcome`; the pending banner
      is client-rendered).
  - Idempotent: guard on the *transition* (before.status === 'awaitingOutcome'
    && after.status still 'awaitingOutcome' at read time) so re-entrancy from the
    same trigger's own writes is avoided; the status write moves it out of
    `awaitingOutcome` so the resolver won't re-resolve.
- Adapt `onTrialEnded`:
  - Extend `terminal` set to include `'hired'` and `'notHired'` (so
    `activeTrialNannyIds` recomputes when a trial resolves), keep
    `completed/cancelled/declined` for legacy/cancel paths.
  - **Remove the generic `completed` family push** (lines 115-124) — it is
    replaced by the outcome-specific pushes in `onTrialOutcomeResolved`. Leave the
    `activeTrialNannyIds`/`lastTrialEndedAt` recompute intact.

**12. `src/index.ts` — MODIFY**
- Import + export `trialOutcomeDetector` and `onTrialOutcomeResolved`.

**13. `functions/test/trial_outcome.test.js` — CREATE (see §7)**

### Not touched (explicit boundaries honored)
- No nanny/family **profile-field** screens (phases 1–2). This plan reads
  `NannyModel`/`FamilyModel` but edits none of their fields.
- **No stored "available/hidden" boolean on `NannyModel`** — visibility stays
  derived (§5 file 8). The `Emirate` 8→7 fix is phases 1–2's; not touched here.
- Payments/billing untouched. `KafiLocationPicker`/`LocationService` untouched.

## 6. Work units & parallelization

- **WU-A (models + reasons + service) — SEQUENTIAL (foundation):** files 1–4.
  Everything else depends on the new `TrialStatus` values, fields, and service
  methods. Build first.
- **WU-B (controller + family/nanny outcome UI + strings) — depends on WU-A:**
  files 5, 6, 9.
- **WU-C (reactivation on dashboard) — depends on WU-A (+ 5):** file 7.
- **WU-D (browse-hide derivation) — depends on WU-A:** file 8. INDEPENDENT of
  WU-B/WU-C (no file overlap) → can run parallel to them once WU-A lands.
- **WU-E (functions: scheduled + resolver + index + tests) — INDEPENDENT of the
  app** (no shared files) → can run fully in parallel with WU-A..D, but its
  Firestore field/status contract must match WU-A. Files 10–13.

So after WU-A: WU-B, WU-C, WU-D, WU-E can proceed with only WU-B/WU-C sharing
`trial_controller.dart` (keep them on one developer or sequence B→C).

## 7. Test plan

Functions tests must match the existing convention exactly
(`functions/test/translate.test.js`: `node:test` + `node:assert` against the
**compiled** `../lib/**` output; `npm test` = `node --test test/*.test.js`; no
Jest/mocha). Because the triggers themselves are thin I/O wrappers, extract the
**pure resolution logic** into a testable helper and unit-test that (mirrors how
`translate.test.js` tests `computeTranslationUpdates`, not the trigger):
- In `trial.ts`, factor the 2×2 into `export function resolveTrialOutcome(family,
  nanny): 'hired'|'notHired'|'pending'`. `trial_outcome.test.js` asserts:
  both-hired→'hired'; family-hired+nanny-searching→'notHired';
  family-searching+nanny-hired→'notHired'; family-hired+nanny-null→'pending';
  both-null→'pending'; both-searching→'notHired'.
- In `scheduled.ts`, factor the due-trial predicate into
  `export function isTrialDueForOutcome(trial, now): boolean`
  (status==='active' && endDate<=now && !outcomePromptSent) and unit-test the
  boundary (endDate just past / just future / already prompted).
- Keep `npm run build && npm test` green.

App (manual/CI, `flutter analyze` must pass — no Flutter runtime in this
container, verified in a prior plan; static-clean is the bar here):
- Family taps "We hired her" alone → trial `awaitingOutcome`, `familyOutcome=
  hired`, **no `hired` status**, nanny still visible in browse. (AC 1, 2)
- Nanny then "I got the job" → server resolves → `hired`, nanny hidden from
  browse via the derived exclusion. (AC 2)
- Family "We hired her" + nanny "I'm still looking" → `notHired`, nanny visible.
  (AC 2, 3)
- Nanny "I'm still looking" alone → `notHired` immediately → visible in browse
  (verified through `engagedNannyIds` no longer containing her). (AC 3)
- Scheduled fn flips a past-`endDate` active trial to `awaitingOutcome` + both
  prompts fire once (`outcomePromptSent` idempotency). (AC 4)
- "Keep searching" reason (7, skippable) persists to `trials.notHiredReason`;
  reactivation reason (6) persists to `trials.reactivationReason`. (AC 5)
- Reactivation flips `hired→notHired`, profile intact (no deletes), nanny
  reappears. Same transition path as a resign would use. (AC 6)

## 8. Refactor callouts
- **`endDate` persistence bug (must fix first):** `endDate` is written as an ISO
  string; the scheduled query needs a `Timestamp`. Fix in `sendOffer`
  (+ `applyCounterAndAccept`) — file 4. Without this the whole detector silently
  matches nothing.
- **Free-form `outcome` string retired for the hire signal.** Keep the field for
  back-compat but stop treating `'hired'`/`'failed'` as authoritative; the hire
  decision now lives in `status` + `familyOutcome`/`nannyOutcome`. Avoid a second
  parallel source of truth (the exact anti-pattern the scope warned about).

## 9. Definition of done (buildable, gradable)
- [ ] Family "We hired her" writes `familyOutcome='hired'` only — no `hired`
      status, no browse-hide, until the nanny also confirms. (AC 1, 2)
- [ ] `hired` status (and derived browse-hide) reached only when both
      `familyOutcome=='hired'` && `nannyOutcome=='hired'`; server-resolved. (AC 2)
- [ ] Nanny "I'm still looking" → `notHired` → reappears in browse via the
      `engagedNannyIds` derivation (status genuinely leaves the engagement set;
      not a UI flag). (AC 3)
- [ ] New `trialOutcomeDetector` scheduled fn detects `endDate<=now` on `active`
      trials and fires both prompts via `sendNotification`, idempotently. (AC 4)
- [ ] 7-option (skippable) not-hired reason + 6-option reactivation reason
      persisted on the trial doc. (AC 5)
- [ ] Reactivation reuses the single shared status-transition path; profile data
      preserved. (AC 6)
- [ ] Generic/duplicate trial pushes replaced by one outcome-specific push per
      party. (scope §"What happens to the redundant notification chain")
- [ ] Linked application (if any) flips to `hired` only at the mutual gate. (D4)
- [ ] `flutter analyze` clean; `npm run build && npm test` green with the two new
      unit-test files. (AC 7)
- [ ] D1–D5 confirmed by PM/Waseem; status flipped to READY_FOR_BUILD.
