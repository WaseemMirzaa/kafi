---
slug: kafi-family-profile-fields
project: kafi
title: Family profile — emirate-only location, expanded languages, multi-select role with "Other", days-off replacing free-text schedule
owner: developer
status: READY_FOR_REVIEW
updated: 2026-08-15
epic: kafi-profile-trial-overhaul (phase 2 of 3 — parallel with kafi-nanny-profile-fields and kafi-trial-completion-flow)
branch: claude/kafi-family-profile-fields
---

# Build — kafi-family-profile-fields

Implements `docs/agents/plans/kafi-family-profile-fields.md` in full, including
its §0 binding decisions (D1–D5). Built in one worktree, four commits mirroring
the plan's WU-A → WU-B → WU-C → WU-D order, plus one additional commit for two
forced test fixes (see "Deviations" below).

## File-by-file

### WU-A — Foundation (commit `39ec9f4`)
- **CREATE `kafi_app/lib/utils/emirate_ui.dart`** — `kFamilyEmirates` (the 7
  real emirates, explicit list, never `Emirate.values`), `emirateLabel()`, and
  `emirateFromStored()` (tolerant reverse-parse: canonical label or enum
  `.name`, case-insensitive, null on no match). Reuses `Emirate` from
  `nanny_model.dart` by import only.
- **`kafi_app/lib/utils/constants/family_constants.dart`** — `homeLanguages`
  replaced with the 8-item list; `roles` replaced with the 11-item list; added
  `daysOffOptions = ['1 day off', '2 days off', 'Other']`.
- **`kafi_app/lib/models/job_post_model.dart`** — removed `schedule` (ctor
  default, field, copyWith param+body, `fromMap`, `toMap`); added `daysOff`
  (same pattern) and `rolesOther` (`String?`, holds custom "Other" role text).
  Also removed `localizedSchedule()` — it directly read the now-deleted
  `schedule` field so it could not compile once the field was gone; nothing in
  the plan's design calls it, and per D2 days-off values are a fixed canonical
  set that doesn't need per-doc translation, so there's no `localizedDaysOff()`
  replacement. `city` untouched (`String`, per D1). Left the
  `i18nMapsFrom(m, const ['jobTitle', 'schedule', 'additionalNotes'])` calls
  (here and in `firestore_job_service.dart`) as-is — same "harmless stale
  reference" reasoning the plan's D2 already applied to the Cloud Functions
  side: an absent `schedule` field on new docs is simply skipped.
- **`kafi_app/lib/services/firebase/firestore_job_service.dart`** —
  `_jobFromMap` reads `daysOff`/`rolesOther` instead of `schedule`.
- **`kafi_app/lib/l10n/app_strings.dart` + `locales/en_us.dart` +
  `locales/ar_ae.dart`** — added `fldSelectEmirate`, `fldRolePrompt`,
  `fldRoleOther`, `fldDaysOff`, `familyDaysOffRequired`,
  `familyRoleOtherRequired` (EN + AR values per plan); updated
  `familyCityRequired` copy (EN + AR) to the emirate wording. `ar_ae.dart` did
  not previously have a `familyCityRequired` override (it was silently falling
  back to the baked-in English copy via `Map.from(enUs)`), so this is an ADD
  there, not an edit of an existing line — same intent as the plan, applied to
  the file's actual state. Left `fldSchedule`, `familyScheduleRequired`,
  `jobFieldSchedule`, `locationDetecting`, `fldCity` defined-but-unused, per
  the plan's explicit instruction.

### WU-B — Controller + shared widgets (commit `ff337d6`)
- **`kafi_app/lib/controllers/family_profile_controller.dart`** — `RxString
  city` → `Rx<Emirate?> cityEmirate`; `scheduleCtrl` → `RxString daysOff`;
  added `rolesOtherCtrl`; removed the `LocationService` field, `detectingCity`,
  and the entire `autoDetectCity()` method. `onInit` now just calls
  `_hydrateFromCurrentUser()`. Hydration: `cityEmirate.value =
  emirateFromStored(fam.city)` (legacy free-text city → no selection, not a
  crash); `daysOff.value` guarded against `FamilyConstants.daysOffOptions`
  (legacy free-text schedule → no selection); `rolesOtherCtrl.text = p.rolesOther
  ?? ''`. `validateFamily()`: city-null check, new roles-contains-Other-but-
  blank-text check, daysOff-blank check (replacing the schedule-blank check).
  `_persist()` computes `cityLabel` once (after the `fid` guard) and writes it
  into both `FamilyModel.city` and `JobPostModel.city`; writes `daysOff.value`
  and the conditional `rolesOther`.
- **CREATE `kafi_app/lib/views/widgets/family_job_selectors.dart`** —
  `FamilyEmirateSelector`, `FamilyRoleSelector`, `FamilyDaysOffSelector`, all
  `KafiChip(purple: true)`-based per the design-token reuse rule, wrapped in
  `Obx`. Consolidates what was previously two separate, duplicated chip-Wrap
  implementations (form screen + edit screen) into one shared widget each.

### WU-C — Screens + downstream display (commit `790646c`)
- **`kafi_app/lib/views/family/family_form_screen.dart`** /
  **`family_edit_screen.dart`** — city picker (`KafiLocationPicker` +
  "Detecting…" state) replaced with `FamilyEmirateSelector`; duplicated role
  chip `Wrap` replaced with `FamilyRoleSelector`; free-text schedule
  `KafiTextField` replaced with `FamilyDaysOffSelector`. Removed the
  `kafi_location_picker.dart` import and (form screen only) the
  now-unreferenced `_detectingCity()` helper from both screens.
- **`kafi_app/lib/views/nanny/job_detail_screen.dart`** — "Schedule" detail
  row → "Days off", reading `job.daysOff`.
- **`kafi_app/lib/views/family/my_jobs_screen.dart`** (plan D5) —
  `_JobEditSheet`'s `_schedule` controller, its `KafiTextField`, and its
  `copyWith` arg all removed; title + salary quick-edit remain; days-off is
  edited via the sheet's existing "Full details" bridge into the full editor.

### WU-D — Admin panel (commit `a46d40a`)
- **`admin-panel/src/services/firestore.ts`** — `JobPostRow.schedule` →
  `daysOff`; `parseJobPost` mapper reads `data.daysOff`; the 5 mock seed job
  rows (`j1`–`j5`) get canonical `daysOff` values (`'1 day off'` ×2, `'2 days
  off'` ×2, `'Other'` ×1 — a representative mix) instead of the old free-text
  schedule strings. `city` fields untouched.
- **`admin-panel/src/pages/families/FamilyDetail.tsx`** /
  **`TrialDetail.tsx`** — "Schedule" `Field` → "Days off", reading
  `job.daysOff`.
- `rolesOther` intentionally **not** added to `JobPostRow` or surfaced
  anywhere in the admin panel — the plan's explicit deferral note. (First
  implementation pass mistakenly added `rolesOther?: string` to `JobPostRow`;
  caught and reverted before compiling, since the plan is explicit that this
  new field gets no new admin UI this phase.)

## Deviations from the plan

One category, both instances mechanical/forced, not design changes — flagged
per the task instructions since touching files outside plan §3 is normally
disallowed:

**Two pre-existing test files, not in plan §3, required fixes to compile**
(commit `b581c53`), discovered only after a full-repo grep sweep for every
symbol the plan's renames touch (`schedule`, `scheduleCtrl`, `city` on
`FamilyProfileController`, `localizedSchedule`) — the plan's own D5 already
established the precedent for this exact situation (a forced dependency the
scope doc's search missed) and its resolution (fix it, document it, don't
silently skip it):
- `kafi_app/test/i18n/localization_test.dart` constructed a `JobPostModel`
  with `schedule: 'Mon-Fri'` and called `j.localizedSchedule('ar')` — both
  gone after WU-A. Fixed by dropping the schedule-specific arg/assertion from
  that one test (jobTitle/additionalNotes coverage in the same test is
  unaffected).
- `kafi_app/test/onboarding/onboarding_validation_test.dart` drove the real
  `FamilyProfileController` and directly touched `c.city.value` and
  `c.scheduleCtrl.text` in three places (an "empty city" test, an "empty
  schedule" test, and the shared `_fillValidFamily` setup helper). Fixed by
  switching to `c.cityEmirate.value` / `c.daysOff.value`, and updating the
  "empty schedule" test's expected key from `familyScheduleRequired` to
  `familyDaysOffRequired` (renamed the test description to match).

No production-code behavior changed by this commit. Verified with `flutter
test` (not just `flutter analyze`) — full suite, 149 tests, all passing,
confirming the fixes are correct at runtime, not just compiling.

Everything else matches the plan exactly — no other deviations, no redesign,
no scope creep.

## Commands run and results

```
$ cd kafi_app && flutter pub get
Got dependencies!

$ flutter analyze
Analyzing kafi_app...
No issues found! (ran in 24.2s)

$ flutter test          # full suite, not just the two touched files
00:xx +149: All tests passed!

$ cd admin-panel && npm install
added 364 packages ... (pre-existing audit warnings, unrelated to this change)

$ npx tsc -b
(clean — no output, no errors)

$ npx vite build
✓ 102 modules transformed.
✓ built in 3.51s
(one pre-existing "chunk larger than 500kB" advisory, unrelated to this change)
```

Grep gate (plan §6.4), run against the two family screens — all five patterns
return zero matches in both files:
```
$ grep -n 'job\.schedule\|controller\.city\|scheduleCtrl\|detectingCity\|KafiLocationPicker' \
    kafi_app/lib/views/family/family_form_screen.dart \
    kafi_app/lib/views/family/family_edit_screen.dart
(no output)
```

Environment note: this sandbox has no Flutter SDK preinstalled. A pre-cached
Flutter 3.35.7 checkout (matching `.fvmrc`) was found already bootstrapped at
the scratchpad path and used directly — no SDK was modified, and nothing was
installed into the repo or worktree.

## Definition of done — confirmed item by item (plan §7)

- [x] No `KafiLocationPicker`/GPS/`autoDetectCity`/`LocationService`/
      `detectingCity` reachable from the family city field or the controller.
      Removed from the controller (field, method, dependency) and from both
      screens; grep gate confirms zero matches. (`KafiLocationPicker` still
      exists in the codebase for `trial_offer_screen.dart`, which the plan
      explicitly says to leave alone — untouched.)
- [x] Family location is a single-select of the 7 real emirates, sourced from
      the reused `Emirate` enum; persisted as a canonical label into both
      `FamilyModel.city` and `JobPostModel.city` from one controller value.
      `FamilyEmirateSelector` renders `kFamilyEmirates` (7 items); `_persist()`
      computes `cityLabel` once, used for both writes.
- [x] `FamilyConstants.homeLanguages` == the 8-item list exactly (Arabic,
      English, Hindi, Urdu, Tagalog, French, Russian, Other); Other has no
      reveal field. Confirmed — list matches verbatim; the languages `Wrap` in
      both screens was untouched (no reveal logic exists or was added).
- [x] `FamilyConstants.roles` == the 11-item list exactly; multi-select;
      "Other" reveals a required text field persisted to
      `JobPostModel.rolesOther`; the two duplicated role UIs are one shared
      widget. Confirmed — list matches verbatim; `FamilyRoleSelector` is the
      single shared implementation used by both screens.
- [x] `JobPostModel.schedule` is gone; `daysOff` replaces it; 1/2/Other
      single-select with no elaboration field; validation requires a
      selection. Confirmed — `schedule` fully removed (incl. the
      `localizedSchedule()` getter, see Deviations); `FamilyDaysOffSelector`
      has no reveal logic for any option; `validateFamily()` rejects a blank
      `daysOff`.
- [x] `job_detail_screen.dart`, `FamilyDetail.tsx`, `TrialDetail.tsx`, and the
      `JobPostRow` type + mapper + mock seeds read/display `daysOff` ("Days
      off"), not `schedule`. Confirmed across all six.
- [x] `my_jobs_screen.dart` compiles with the schedule quick-edit removed.
      Confirmed by `flutter analyze` (No issues found) and `flutter test`.
- [x] `flutter analyze` and admin `tsc -b && vite build` both pass. Confirmed,
      output above.
- [x] No file owned by phase 1 (nanny) or phase 3 (trial) was edited;
      `Emirate` is imported, never redefined; `Emirate.alAin` is never
      referenced anywhere in new code. Confirmed: `git diff --stat` against
      `origin/main` shows exactly the plan's 16 files + the 2 forced test
      files (see Deviations) — no `nanny_model.dart`, no trial-flow files.
      `emirate_ui.dart` imports `Emirate` (no `enum Emirate` redeclaration
      anywhere in the diff); `grep -r alAin` across every file this build
      touched returns nothing.

## Known gaps / follow-ups (not blocking, called out by the plan itself)

- **`functions/src/utils/translate.ts`** still lists `'schedule'` in
  `JOB_TX.fields` (plan D2) — left untouched per the plan's explicit decision
  (out of scope boundary; harmless since the field is simply absent on new
  docs); flagged there as a follow-up cleanup for a functions-owning task.
- **Admin panel `rolesOther`** is not surfaced anywhere (plan's explicit
  deferral, no new admin UI in scope this phase) — flagged as a possible
  future admin enhancement.
- `fldSchedule`, `familyScheduleRequired`, `jobFieldSchedule`,
  `locationDetecting`, `fldCity` l10n keys remain defined but unused (plan
  explicitly says removing them is optional cleanup, not required).

## Branch

`claude/kafi-family-profile-fields`, based on `origin/main` @ `168c398`
(fetched fresh at task start). Pushed to `origin/claude/kafi-family-profile-fields`.
Five commits: `39ec9f4` (WU-A), `ff337d6` (WU-B), `790646c` (WU-C), `a46d40a`
(WU-D), `b581c53` (forced test fixes). No PR opened — PM handles that after
review.
