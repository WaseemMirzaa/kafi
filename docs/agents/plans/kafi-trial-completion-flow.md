---
slug: kafi-trial-completion-flow
project: kafi
title: Trial-completion workflow with mutual hire confirmation, nanny outcome capture, and hired-nanny reactivation
owner: architect
status: READY_FOR_BUILD
updated: 2026-08-15
epic: kafi-profile-trial-overhaul (phase 3 of 3 — parallel with kafi-nanny-profile-fields and kafi-family-profile-fields)
---

## 0. Correction note

An earlier pass of this plan was written after a `git rebase (start): checkout
origin/main` → `rebase (abort)` happened mid-investigation in this shared
working directory (confirmed via `git reflog`), which produced a stale/mixed
read: several files were found empty (`i_hire_service.dart`,
`firestore_hire_service.dart` — "File does not exist") and `firestore.rules`
was read complete-but-truncated at 193 lines with no `hires` block. That plan
wrongly concluded the hire/notification subsystem didn't exist and stopped at
a blocker.

This version is a full redo: every file below was re-read from a since-settled
working tree (`git status` clean throughout this pass) and cross-checked for
internal consistency (service ↔ interface ↔ mock ↔ controller ↔ UI ↔
functions all agree with each other). The hire subsystem, `writeInbox`,
`resignHire`, and `endActiveHire` are all real, and the scope doc's guidance
is groundable almost exactly as written. No blockers remain.

---

## 1. Architecture summary

The mutual-confirm gate is built as a **thin pending layer on top of the
existing `TrialModel`/`hires` machinery**, not a parallel system:

```
active ──(scheduled: endDate<=now)──► awaitingOutcome
                                         │
   family writes familyOutcome ∈ {hired, notHired}  (+ optional notHiredReason)
   nanny  writes nannyOutcome  ∈ {hired, notHired}
                                         │
        onTrialOutcomeResolved (Cloud Function, transactional):
          both 'hired'        → status=completed, outcome='hired'
                                 → creates hires/{hire_<trialId>} (status=active)
                                 → flips linked application to hired
          either 'notHired'   → status=completed, outcome='failed'
          only one responded  → no-op, stays awaitingOutcome
                                         │
   onHireCreated (existing) fires the nanny's "You've been hired!" push
   onTrialEnded  (existing, enhanced) fires the outcome-aware closing pushes
```

**Why resolution is server-side, not client-side (the one real design
decision in this plan):** `firestore.rules`' `hires` collection only allows
`create: if incoming().familyId == request.auth.uid` — only the family's
client can create a hire. If the NANNY is the second party to respond (family
already said "hired", nanny confirms second), a client-side resolution
running on the nanny's device could never satisfy that rule and hire-creation
would silently fail for exactly half of the possible response orderings. A
Cloud Function using the Admin SDK bypasses rules entirely, so it works
regardless of which side resolves the match second — and this exact
"client can't write the cross-user side effect, so a trigger owns it" pattern
is already used twice in this codebase (`onProfileViewed`'s transactional
free-contact accounting, `onHireCreated`'s server-owned `stats.hiresCount`).
The client (`TrialController`/`FirestoreTrialService`) only ever writes its
**own** side's outcome field — it never decides or creates the hire.

**Search visibility stays 100% derived, reusing the exact existing
mechanism** — `BrowseController._engagedNannyIds()` unions
`IHireService.activeHiredNannyIds()` (`hires` where `status==active`) and
`ITrialService.activeTrialNannyIds()` (`trials` where `status in
[active,accepted]`). Both queries are **left completely unchanged**. The new
`awaitingOutcome` status is simply not in either query's set, so the moment
the scheduled detector moves a trial out of `active` into `awaitingOutcome`,
the nanny already falls out of the engaged set with zero code changes to the
derivation itself — she reappears in browse the instant the trial's clock
runs out, and stays that way unless/until mutual confirmation creates a
`hires` doc. This is also exactly how the locked decision's mismatch case
resolves itself: "family says hired, nanny never responds" — she's already
outside both engaged sets during that wait, so she stays visible, matching
"she stays visible/available until both sides agree" precisely.

**Reactivation reuses `resignHire()`/`endHire()` — traced concretely, not
just "in spirit":** the reactivation UI's 6-option picker calls
`NannyProfileController.resignHire(reasonNote: picked)` (a small,
backward-compatible signature extension) → `IHireService.endHire(hire.id,
reason: HireEndReason.resigned, note: reasonNote)` → the existing
transactional first-end-wins write in `FirestoreHireService.endHire` →
`hires/{id}.status='ended'` → the existing `onHireEnded` trigger notifies the
family → `activeHiredNannyIds()` no longer includes her (query is
`status==active`) → she reappears in browse. No new status field, no new
enum value, no second code path — the 6-option reason is carried entirely by
the **existing** `endNote: String?` field `endHire` already accepts.

---

## 2. Exact state-machine design

### 2.1 `TrialStatus` — one new value
`kafi_app/lib/models/trial_model.dart`:
```dart
enum TrialStatus { pending, countered, accepted, declined, active, awaitingOutcome, completed, cancelled }
```
`awaitingOutcome` = "execution window closed (`endDate` passed), outcome not
yet resolved." Inserted between `active` and `completed` for readability;
position doesn't affect the existing `.name`-based persistence/`orElse`
fallback.

### 2.2 New `TrialModel` fields (additive, nullable — no destructive migration)
```dart
final String? familyOutcome;      // null | 'hired' | 'notHired'
final DateTime? familyOutcomeAt;
final String? notHiredReason;     // one of NotHiredReason.name, nullable/optional
final String? nannyOutcome;       // null | 'hired' | 'notHired'
final DateTime? nannyOutcomeAt;
final bool outcomePromptSent;     // default false — scheduled-fn idempotency, mirrors trials.reminderSent
final DateTime? endReachedAt;     // when the scheduled detector flipped active→awaitingOutcome
```
Threaded through the constructor, `copyWith`, `toMap`, `fromMap` using the
exact existing conventions (`_parseDate`, `?? this.field`,
`.toIso8601String()`, `== true` boolean reads).

New getters:
```dart
bool get isAwaitingOutcome => status == TrialStatus.awaitingOutcome;
bool get familyConfirmedHire => familyOutcome == 'hired';
bool get nannyConfirmedHire => nannyOutcome == 'hired';
bool get familyDeclinedHire => familyOutcome == 'notHired';
bool get nannyDeclinedHire => nannyOutcome == 'notHired';
```

### 2.3 Resolution truth table (implemented as one pure, unit-tested function — see §5)
| familyOutcome | nannyOutcome | Resolution |
| --- | --- | --- |
| hired | hired | **hired** — create `hires` doc, flip application, hide from search |
| notHired | * (any, including hired) | **notHired** — no hire; mismatch case explicitly covered |
| * (any, including hired) | notHired | **notHired** |
| hired | null | pending — stays `awaitingOutcome`, visible in search (not in engaged set) |
| null | hired | pending — stays `awaitingOutcome`, visible in search |
| null | null | pending |

### 2.4 Reason lists (verbatim from scope, new file — single responsibility)
`kafi_app/lib/models/trial_outcome_reasons.dart`:
```dart
enum NotHiredReason { notTheRightMatch, salary, schedule, location, nannyDeclined, foundSomeoneElse, other }
enum ReactivationReason { jobDidntWorkOut, familyEndedEmployment, iDecidedToLeave, temporaryJobEnded, other, preferNotToSay }
```
Persisted as the enum's stable `.name` (never the localized label — matches
every other enum-to-string convention in this codebase, e.g. `status.name`,
`HireEndReason.resigned.name`). Display labels are resolved through
`AppStrings` at render time.
- `NotHiredReason` → `trials.notHiredReason` (nullable, skippable — family only).
- `ReactivationReason` → passed as the free-text `note` on the *existing*
  `HireModel.endNote` field via `endHire(..., note: reason.name)`. No new
  persistence surface.

---

## 3. Required prerequisite fix (blocking — the detector silently matches nothing without it)

`FirestoreTrialService.sendOffer` converts only `startDate` to a Firestore
`Timestamp`; `endDate` is written as whatever `TrialModel.toMap()` produces —
an ISO **string** (`'endDate': endDate.toIso8601String()`). A
`where('endDate', '<=', Timestamp)` range query (needed for §4's scheduled
detector) cannot match a string-typed field — it will silently return zero
results forever, not error. Must fix in the same change:
- `sendOffer`: add `data['endDate'] = Timestamp.fromDate(trial.endDate);`
  next to the existing `startDate` conversion.
- `applyCounterAndAccept`: today it writes the counter's `startDate` as a
  Timestamp but never recomputes `endDate` at all (a pre-existing gap — a
  counter that moves the start date silently leaves the old end date in
  place). Fix alongside: recompute
  `counter.startDate.add(Duration(days: trial.durationDays))` and write it as
  a Timestamp too.

Trials created before this fix keep a string `endDate` and simply won't be
picked up by the new detector (not an error, just silently excluded) — an
acceptable, additive gap per the epic's "no destructive backfill" guidance,
worth a one-line callout to the PM but not a blocker.

---

## 4. Notification design (reusing `writeInbox`/`sendNotification` — no new delivery mechanism)

### 4.1 New scheduled Cloud Function — `trialOutcomeDetector`
`functions/src/triggers/scheduled.ts`, modeled exactly on the existing
`trialStartingReminder` (same file): `onSchedule('every 1 hours')`, Timestamp
range query, `.limit(200)`, `Promise.all`, per-doc idempotency flag.
```ts
export const trialOutcomeDetector = onSchedule('every 1 hours', async () => {
  const now = admin.firestore.Timestamp.now();
  const trials = await admin.firestore().collection('trials')
    .where('status', '==', 'active')
    .where('endDate', '<=', now)
    .limit(200)
    .get();

  await Promise.all(trials.docs.map(async (doc) => {
    const trial = doc.data();
    if (!isTrialDueForOutcome(trial, now.toMillis())) return; // pure helper, unit-tested (§5)

    const [family, nannyUser] = await Promise.all([
      getFamily(trial.familyId as string),
      getUser(trial.nannyId as string),
    ]);
    const famTitle = 'How did the trial go?';
    const famBody = 'Let us know how it went with your nanny.';
    const nanTitle = 'What happened after your trial?';
    const nanBody = 'Tell us if you got the job.';
    const data = { type: 'trial_outcome_pending', trialId: doc.id };

    await writeInbox(trial.familyId as string, 'trialOutcomePending', famTitle, famBody, data);
    await sendNotification((family.fcmTokens as string[]) ?? [], { title: famTitle, body: famBody, data });
    await writeInbox(trial.nannyId as string, 'trialOutcomePending', nanTitle, nanBody, data);
    await sendNotification((nannyUser.fcmTokens as string[]) ?? [], { title: nanTitle, body: nanBody, data });

    await doc.ref.update({
      status: 'awaitingOutcome',
      endReachedAt: admin.firestore.FieldValue.serverTimestamp(),
      outcomePromptSent: true,
    });
  }));
});
```
Also call the existing `recomputeActiveTrialNannyIds(familyId)` helper
(`trial.ts`) inside this same update — see §4.4 for why.

### 4.2 New resolver trigger — `onTrialOutcomeResolved`
`functions/src/triggers/trial.ts`, `onDocumentUpdated('trials/{trialId}')`:
- Fires only when `after.status === 'awaitingOutcome'` and
  `familyOutcome`/`nannyOutcome` actually changed.
- Computes the verdict via the pure `resolveMutualOutcome` helper (§5); a
  `'pending'` verdict is a no-op (still waiting on one side).
- On a decided verdict, runs a **transaction**: read the trial fresh, bail if
  its status is no longer `awaitingOutcome` (first-resolution-wins — mirrors
  `onHireEnded`'s before/after guard and `FirestoreHireService.endHire`'s
  transactional pattern, both already in this codebase), then write
  `status='completed'`, `outcome='hired'|'failed'`, `outcomeAt`,
  `completedAt` — the **exact same field shape** `FirestoreTrialService.
  recordOutcome` already writes today.
- On `verdict==='hired'`, after the transaction commits: fetch
  `getFamily(after.familyId)`/`getNanny(after.nannyId)` for display names
  (a background function has no client auth context, so it cannot read
  `_auth.currentUser` the way the old client-side `_createHireFromTrial`
  did — it must look the names up itself) and create
  `hires/{hire_<trialId>}` with the **same field shape** as
  `TrialController._createHireFromTrial` (`status:'active'`, `trialId`,
  `jobPostId`, `employmentType: after.trialType`, `nannyName`, `familyName`,
  `startedAt`/`createdAt`: server timestamp). Then best-effort look up a
  matching `applications` doc (`familyId`+`nannyId`, optionally `jobPostId`)
  and flip it with the exact same write `FirestoreApplicationService.
  markHired` already uses (`status:'hired'`, `respondedAt`: server
  timestamp) — swallow errors, matching `_createHireFromTrial`'s existing
  "a missing application is fine" behavior.
- Sends **no notifications itself** — see §4.3, this is deliberately left to
  the enhanced `onTrialEnded`, to avoid two functions racing to notify the
  same transition.

### 4.3 Enhanced `onTrialEnded` — outcome-aware, de-duplicated copy
`functions/src/triggers/trial.ts`, existing function, `completed` branch only
(the `cancelled` branch and the terminal-status/`activeTrialNannyIds` recompute
stay untouched):
- `after.outcome === 'hired'`: family gets one push
  ("✅ Hire confirmed" / "You and {nanny} confirmed the hire — she's now
  marked Hired."). **The nanny gets nothing from this function** — she
  already gets "🎉 You've been hired!" from the existing `onHireCreated`
  trigger (fires from the `hires/{id}` document §4.2 just created). This is
  the fix for the current double-push-on-hire problem: today both
  `onTrialEnded`'s generic "trial complete" push AND `onHireCreated`'s
  specific push land on the nanny for the same event; after this change she
  gets exactly one, and it's the specific one.
- `after.outcome === 'failed'`: family gets a neutral closure
  ("Trial closed" / "This trial didn't lead to a hire. Keep browsing for
  your next match."); nanny gets an honest, specific message ("Trial update"
  / "This trial didn't lead to a hire this time. Your profile is visible in
  search again.") — replacing today's actively-misleading generic copy
  ("Your trial is complete. The family will confirm next steps.") which is
  sent even when the family already decided against hiring.
- `after.outcome` is `undefined`/unrecognized (defensive fallback for any
  trial completed via a path this phase doesn't touch, e.g. a future
  admin action): keep today's existing generic copy verbatim, unchanged —
  never regress a code path this plan doesn't control.

### 4.4 `activeTrialNannyIds` (family-doc chat-unlock list) — deliberate, narrow widen
Distinct from the browse-hide derivation (§1), `families/{id}.
activeTrialNannyIds` is a **different** mechanism: it's what
`firestore.rules`' `hasActiveTrialWith()` reads to let an unsubscribed family
keep chatting with the nanny during a trial. `recomputeActiveTrialNannyIds`
(`trial.ts`) currently queries `status in ['active','accepted']`. If left
unchanged, the moment a trial flips to `awaitingOutcome` an unsubscribed
family would lose chat access at exactly the point both parties most need to
discuss the outcome — a clear regression. Widen this one query (only this
one — **not** the browse-hide derivation) to
`status in ['active','accepted','awaitingOutcome']`, and call
`recomputeActiveTrialNannyIds(familyId)` from the new scheduled detector
(§4.1) at the same point it flips the status, exactly as `onTrialResponse`
already does on accept.

### 4.5 New `InboxType` / `NotificationType` (lockstep, one new value)
Exactly one new shared type — reused for both the family and nanny variant of
the scheduled prompt (mirrors how `trialStartingSoon` is already shared
between both parties in `trialStartingReminder`):
- `functions/src/utils/notifications.ts`: add `'trialOutcomePending'` to the
  `InboxType` union.
- `kafi_app/lib/models/notification_model.dart`: add `trialOutcomePending` to
  `NotificationType` in the same lockstep the file's own comment documents
  ("mirror the Flutter NotificationType enum names"). `trialEndingSoon`
  remains present-but-unused — out of scope, not required by the spec.

---

## 5. Pure-function test seams (matches the existing test convention exactly)

`functions/test/*.test.js` uses `node:test`/`node:assert` against the
**compiled** `../lib/**` output, testing small pure functions extracted from
the triggers (`flooredCount` from `stats.ts`, `buildInboxDoc` from
`notifications.ts`) — not the triggers themselves. Follow this precisely:

- `functions/src/triggers/trial.ts` exports
  `resolveMutualOutcome(familyOutcome?: string, nannyOutcome?: string): 'hired' | 'notHired' | 'pending'`
  (the truth table in §2.3, as pure code).
- `functions/src/triggers/scheduled.ts` exports
  `isTrialDueForOutcome(trial: {status?: string; endDate?: FirebaseFirestore.Timestamp | Date; outcomePromptSent?: boolean}, nowMs: number): boolean`
  (`status==='active' && endDate<=nowMs && !outcomePromptSent`).
- New `functions/test/trial_outcome.test.js`:
  - `resolveMutualOutcome`: both-hired→'hired'; family-hired+nanny-notHired→
    'notHired'; family-notHired+nanny-hired→'notHired' (the mismatch case);
    hired+undefined→'pending'; undefined+undefined→'pending';
    both-notHired→'notHired'.
  - `isTrialDueForOutcome`: due when active+endDate-past+unprompted; not due
    when status isn't active; not due when endDate is in the future; not due
    when `outcomePromptSent` is already true (boundary: endDate exactly
    `now`, endDate one ms past).

---

## 6. File-by-file change list (build order)

### App (`kafi_app/`)

**1. `lib/models/trial_model.dart` — MODIFY**
Add `TrialStatus.awaitingOutcome` (§2.1); add the 7 new fields + 5 getters
(§2.2), threaded through `copyWith`/`toMap`/`fromMap` per the file's existing
patterns.

**2. `lib/models/trial_outcome_reasons.dart` — CREATE**
`NotHiredReason` (7) + `ReactivationReason` (6) enums (§2.4). No logic.

**3. `lib/services/interfaces/i_trial_service.dart` — MODIFY**
Add:
```dart
Future<void> setFamilyOutcome(String trialId, {required String outcome, TrialEvaluation? evaluation, String? notHiredReason});
Future<void> setNannyOutcome(String trialId, {required String outcome});
```

**4. `lib/services/firebase/firestore_trial_service.dart` — MODIFY**
- Apply the §3 prerequisite fix (`endDate` → Timestamp in `sendOffer` +
  `applyCounterAndAccept`) first — everything downstream depends on it.
- Implement the two new methods as plain `.update()` calls (no client-side
  transaction needed — the mutual-resolution race is handled server-side,
  §1/§4.2; each party only ever writes its own field, so there's no
  same-field concurrent-writer race to guard against here):
```dart
Future<void> setFamilyOutcome(trialId, {required outcome, evaluation, notHiredReason}) =>
  _trials.doc(trialId).update({
    'familyOutcome': outcome,
    'familyOutcomeAt': FieldValue.serverTimestamp(),
    if (evaluation != null) 'evaluation': evaluation.toMap(),
    if (notHiredReason != null) 'notHiredReason': notHiredReason,
  });

Future<void> setNannyOutcome(trialId, {required outcome}) =>
  _trials.doc(trialId).update({
    'nannyOutcome': outcome,
    'nannyOutcomeAt': FieldValue.serverTimestamp(),
  });
```

**5. `lib/services/mock/mock_trial_service.dart` — MODIFY**
Add parity implementations (in-memory, `copyWith`-based, `AppConfig.
mockDelay`) matching every other method in this file.

**6. `lib/controllers/trial_controller.dart` — MODIFY**
- Add `familyRecordOutcome({required String outcome, NotHiredReason? reason})`
  → `_trials.setFamilyOutcome(displayed!.id, outcome: outcome, evaluation:
  buildEvaluation(), notHiredReason: reason?.name)`; `refreshAll()`;
  snackbar "Waiting for {nanny} to confirm" when `outcome=='hired'`.
- Add `nannyRecordOutcome(String outcome)` →
  `_trials.setNannyOutcome(displayed!.id, outcome: outcome)`; `refreshAll()`;
  snackbar "Great! We're waiting for the family to confirm." when
  `outcome=='hired'` is implied by the UI banner (§7), not required here —
  keep the snackbar minimal/optional.
- **Remove** `setOutcome()` and `_createHireFromTrial()` — confirmed via a
  fresh repo-wide grep that `setOutcome(` has exactly two call sites, both in
  `trial_screen.dart`'s `_outcomeBar` family branch (lines 532, 550); once
  §7 rewires those two sites to the new methods, both become fully dead
  code, and hire-creation is now server-side (§4.2) — leaving them in would
  be a second, parallel, unreachable hire-creation path.
- Leave `IHireService.createHire`/`FirestoreHireService.createHire`/
  `MockHireService.createHire` **in place, unremoved** — they become unused
  by the app after this change, but removing a public interface method used
  nowhere else is unrelated cleanup with its own blast radius; flag this as
  a deliberate, narrow scoping call for the architect-reviewer, not an
  oversight.

**7. `lib/views/family/trial_screen.dart` — MODIFY**
- `_outcomeBar`, family branch: change the gate from `if (!t.isActive) return
  SizedBox.shrink();` to branch on `t.isAwaitingOutcome`:
  - Not yet responded → the existing two-button block (**same widget,
    relabeled**: "We hired her" / "Keep searching", same green-gradient
    positive / white-outline-rose-text negative styling this file already
    uses for this exact positive/negative choice — no new colors).
    "We hired her" → `controller.familyRecordOutcome(outcome: 'hired')`
    directly (no further questions, per spec). "Keep searching" → open a
    reason sheet reusing the **existing** `Get.bottomSheet` idiom already in
    this file (`_chooseProofSource`'s pattern: white rounded-top sheet, drag
    handle, `_sourceTile`-style rows) listing the 7 `NotHiredReason` options
    plus a "Skip" action → `controller.familyRecordOutcome(outcome:
    'notHired', reason: picked)` (picked may be null on skip).
  - `t.familyConfirmedHire` (responded hired, nanny hasn't yet) → render the
    existing `_banner(...)` helper: "We're waiting for {nanny} to confirm."
  - `t.familyDeclinedHire` → `SizedBox.shrink()` (nothing more to do).
  - Any other status (including `completed`) → `SizedBox.shrink()`, matching
    the file's existing "hide once nothing left to do" convention.
- `_outcomeBar`, nanny branch: keep the existing pending/accepted Cancel
  button unchanged; add an `isAwaitingOutcome` branch with the mirrored
  two-button block ("I got the job" / "I'm still looking", same
  green/rose-outline treatment as the family's, for visual consistency
  within this one screen):
  "I got the job" → `controller.nannyRecordOutcome('hired')`, then show
  `_banner(...)`: "Great! We're waiting for the family to confirm."
  "I'm still looking" → `controller.nannyRecordOutcome('notHired')`.
  `t.nannyDeclinedHire` → `SizedBox.shrink()`.
- Header/timer: when `isAwaitingOutcome`, swap the frozen `'0d 0h 0m'`
  countdown for a clear "Trial ended — awaiting your response" label instead
  of a stale zero timer (small, contained change to `_remainingLabel`'s
  caller in `_header`).
- All new copy via `AppStrings.*.tr` (see §8 for the string-file pair).

**8. `lib/views/nanny/nanny_dashboard_screen.dart` — MODIFY**
In `_statusCard()`'s `hired` branch: replace the plain "Resign" link +
`_confirmResign()`'s bare `AlertDialog` with "Looking for a job again?" /
"Make My Profile Available" copy, opening a reason sheet (reuse the same
`Get.bottomSheet` idiom as file 7) listing the 6 `ReactivationReason`
options (no separate skip — "Prefer not to say" is itself one of the six).
On selection → `controller.resignHire(reasonNote: picked.name)`. This
**replaces** the existing bare-confirm resign entry point rather than adding
a second one alongside it — there is exactly one way to end a hire from this
card, now with a reason captured every time.

**9. `lib/controllers/nanny_profile_controller.dart` — MODIFY**
Extend `resignHire()` to `resignHire({String? reasonNote})`, passing it
straight through: `_hireService.endHire(hire.id, reason:
HireEndReason.resigned, note: reasonNote)`. Default `null` preserves exact
current behavior for any other caller.

**10. `lib/l10n/app_strings.dart` + `locales/en_us.dart` + `locales/ar_ae.dart` — MODIFY**
Add keys for: family "How did the trial go?" prompt + "We hired her" +
"Keep searching" + the 7 reason labels + "Skip" + the "waiting for {nanny}"
banner; nanny "What happened after your trial?" prompt + "I got the job" +
"I'm still looking" + "Great! We're waiting for the family to confirm."
banner + "Trial ended — awaiting your response"; reactivation card title +
CTA + the 6 reason labels. English + Arabic for every new key, matching the
existing `.tr` convention throughout both files.

### Cloud Functions (`functions/src/`)

**11. `triggers/scheduled.ts` — MODIFY**
Add `isTrialDueForOutcome` (pure, §5) and `trialOutcomeDetector` (§4.1).
Also call `recomputeActiveTrialNannyIds` from `trial.ts` inside the same
per-doc update (§4.4) — this requires exporting that helper from `trial.ts`
(currently module-private `async function recomputeActiveTrialNannyIds`;
add `export`).

**12. `triggers/trial.ts` — MODIFY**
- `export` the existing `recomputeActiveTrialNannyIds` (needed by file 11).
- Add `resolveMutualOutcome` (pure, §5) and `onTrialOutcomeResolved` (§4.2).
- Enhance `onTrialEnded`'s `completed` branch to be outcome-aware (§4.3);
  leave the `cancelled` branch untouched.

**13. `utils/notifications.ts` — MODIFY**
Add `'trialOutcomePending'` to the `InboxType` union (§4.5). No other change
— `writeInbox`/`sendNotification` are reused exactly as they are.

**14. `src/index.ts` — MODIFY**
Export `trialOutcomeDetector` (from `scheduled.ts`) and
`onTrialOutcomeResolved` (from `trial.ts`).

**15. `functions/test/trial_outcome.test.js` — CREATE**
Unit tests for `resolveMutualOutcome` and `isTrialDueForOutcome` (§5),
matching `stats.test.js`/`notifications.test.js`'s exact
`require('../lib/triggers/trial.js')` / `require('../lib/triggers/
scheduled.js')`-against-compiled-output style.

### `kafi_app/lib/models/notification_model.dart` — MODIFY
Add `trialOutcomePending` to `NotificationType`, in lockstep with file 13
(§4.5).

### `firestore.rules` — MODIFY (scoped hardening, required for gate integrity)
The current `trials` update rule lets *either* party write *any* field on the
trial doc (`existing().familyId == uid || existing().nannyId == uid`, no
field restriction) — looser than `families`, which already blocks specific
admin/server-owned fields via `incoming().diff(existing()).affectedKeys()
.hasAny([...])`. Without an equivalent restriction here, a nanny client could
simply write `familyOutcome: 'hired'` itself and forge the family's side of
the mutual gate — defeating the entire point of this phase. Add the same
pattern already used for `families`:
```
allow update: if isAdmin()
  || (isSignedIn() && existing().familyId == request.auth.uid
      && !incoming().diff(existing()).affectedKeys().hasAny(['nannyOutcome', 'nannyOutcomeAt']))
  || (isSignedIn() && existing().nannyId == request.auth.uid
      && !incoming().diff(existing()).affectedKeys().hasAny(['familyOutcome', 'familyOutcomeAt', 'notHiredReason']));
```
No `hires` rules change needed — `onTrialOutcomeResolved` creates the hire
via the Admin SDK, which bypasses Firestore rules entirely, exactly like
every other server-owned write in `stats.ts` already does.

### Not touched (explicit scope boundaries honored)
- No nanny/family profile-*field* screens (phases 1–2's files).
- No new stored "available/hidden" boolean on `NannyModel` — visibility stays
  100% derived (§1), both existing queries (`activeHiredNannyIds`,
  `activeTrialNannyIds`) unchanged.
- `ChatController.endActiveHire()` / `family/chat_screen.dart` (family-side
  "End employment") — untouched. The scope's reactivation reason picker is
  nanny-side only; the family's existing end-employment flow keeps its
  current behavior exactly as-is.
- `KafiLocationPicker`/`LocationService`, payments/billing, `Emirate` enum —
  untouched (out of scope / other phases' concern).
- Admin panel (`admin-panel/`) is not in this phase's file list and isn't
  edited; note for the developer to spot-check that it renders an unknown
  `trials.status` value ('awaitingOutcome') without crashing, since it likely
  displays the raw status string somewhere — a five-minute look, not a
  planned change.

---

## 7. Acceptance-criteria trace

- Family "We hired her" no longer instantly creates a `hires` doc — writes
  `familyOutcome='hired'` only (file 4/6/7). ✓
- Hired status + search-hide reached only once both `familyOutcome` and
  `nannyOutcome` are `'hired'`, resolved server-side (file 12, §4.2); a
  family-hired + nanny-silent-or-notHired mismatch never creates a hire (§2.3
  truth table, unit-tested in file 15). ✓
- Nanny "I'm still looking" → `nannyOutcome='notHired'` →
  `onTrialOutcomeResolved` immediately resolves `status='completed'`,
  `outcome='failed'` → she was already outside `activeTrialNannyIds()`'s
  `active`/`accepted` set from the moment the trial entered
  `awaitingOutcome` (§1) — genuinely a status transition, not a UI flag. ✓
- New scheduled `trialOutcomeDetector` (file 11) detects `endDate<=now` on
  `active` trials and fires both prompts via the existing
  `writeInbox`/`sendNotification` pair (§4.1). ✓
- 7-option skippable not-hired reason + 6-option reactivation reason
  captured and persisted (`trials.notHiredReason`, `hires.endNote` — §2.4). ✓
- Reactivation reuses `resignHire()`/`endHire()` exactly (§1, traced
  concretely); ending a hire (either resign-driven or reactivation-driven)
  only ever changes `hires.status`/derived visibility — nothing about the
  nanny's account/profile is deleted. ✓
- Redundant/generic notification chain replaced: hired → nanny gets exactly
  one push (`onHireCreated`'s existing one); not-hired → both parties get one
  specific, honest push each (§4.3), not today's always-generic,
  sometimes-wrong copy. ✓
- `applications/{appId}` hired-flip moved to the mutual-confirm gate
  (§4.2 — was previously fired by `_createHireFromTrial` alongside the old
  single-sided hire; now fired only by `onTrialOutcomeResolved` alongside the
  real, mutual hire). ✓
- `flutter analyze` and `npm run build && npm test` (with the new
  `trial_outcome.test.js`) both pass. ✓

## 8. Definition of done
- [ ] Files 1–10 (app) implemented in order; file 4's §3 prerequisite fix
      lands before anything depends on `endDate` being queryable.
- [ ] Files 11–15 (functions) implemented; `onTrialOutcomeResolved` and
      `trialOutcomeDetector` exported from `index.ts`.
- [ ] `firestore.rules` hardened for `trials` field-level ownership.
- [ ] `notification_model.dart` and `notifications.ts` `InboxType` updated in
      lockstep (one new value).
- [ ] `npm run build && npm test` green in `functions/`.
- [ ] `flutter analyze` clean in `kafi_app/`.
- [ ] Manual smoke of the 2×2 outcome matrix + the scheduled detector's
      idempotency (`outcomePromptSent`) + reactivation, per §7.
