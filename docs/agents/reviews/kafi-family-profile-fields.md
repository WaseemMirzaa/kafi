---
slug: kafi-family-profile-fields
project: kafi
title: Family profile — emirate-only location, expanded languages, multi-select role with "Other", days-off replacing free-text schedule
owner: architect-reviewer
status: REVIEW_PASS
updated: 2026-08-15
epic: kafi-profile-trial-overhaul (phase 2 of 3)
branch: claude/kafi-family-profile-fields
reviewed_commit: 62189d49a13ed060dcc08137d4bc026fc8ea8e61
---

# Review — kafi-family-profile-fields

**Verdict: REVIEW_PASS.** Zero Critical, zero Major. Three non-blocking Minors,
all pre-authorized by the plan itself. The build matches the plan file-by-file
(D1–D5 respected), holds the quality bar, and all acceptance criteria pass with
independently reproduced evidence.

## What I verified (not trusted — re-run myself)

Worked against the fetched build ref `62189d4`, diffed vs `origin/main`, and
ran the toolchains in a clean detached worktree using the pre-cached Flutter
3.35.7 SDK (matches `.fvmrc`).

- **`flutter analyze`** → `No issues found!` (ran in 2.5s). Reproduced.
- **`flutter test`** (full suite) → `+149: All tests passed!`. Reproduced,
  including the two touched test files.
- **`npx tsc -b`** (admin-panel) → exit 0, clean. Reproduced.
- **`npx vite build`** → `✓ built in 3.14s`; only the pre-existing >500 kB
  chunk advisory (unrelated to this change). Reproduced.
- **Grep gate (plan §6.4)** in the two family screens for
  `job.schedule|controller.city|scheduleCtrl|detectingCity|KafiLocationPicker`
  → **zero matches** in both. Reproduced independently.
- **`Emirate` reuse (D4):** `enum Emirate` is declared only in
  `nanny_model.dart`; `emirate_ui.dart` imports it, never redeclares it. The
  new code (`emirate_ui.dart`, `family_job_selectors.dart`, controller, tests)
  **never references `Emirate.alAin`**. The only `alAin` occurrences in the
  repo are pre-existing sibling-phase files (`nanny_info_screen.dart`,
  `nanny_model.dart` enum decl, admin `firestore.ts`/`nannyLabels.ts`) — none
  touched by this build. Confirmed it compiles both with the enum's current
  8-value form and after phase 1's 8→7 removal, because the option list and
  label map are explicit 7-item declarations.
- **No phase-1/phase-3 files edited:** `git diff --stat` = exactly the plan's
  16 files + the 2 flagged test files. No `nanny_model.dart`, no trial files.

## Plan adherence — file-by-file

Every planned change is present and correct:

- `emirate_ui.dart` (CREATE) — matches the plan's spec verbatim, including the
  null/empty and unknown-legacy-string → null tolerance in `emirateFromStored`.
- `family_constants.dart` — `homeLanguages` (8, exact order),
  `roles` (11, exact order incl. `"Mother's Helper"`), `daysOffOptions`
  added. Verbatim.
- `job_post_model.dart` — `schedule` fully removed; `daysOff` and `rolesOther`
  added across ctor/field/copyWith/fromMap/toMap in the planned positions.
- `firestore_job_service.dart` — `_jobFromMap` reads `daysOff` + `rolesOther`.
- `app_strings.dart` + `en_us.dart` + `ar_ae.dart` — all 6 new keys + the
  `familyCityRequired` copy change, EN + AR. (AR `familyCityRequired` was an
  ADD, not an edit — the file previously had no override and inherited English
  via `Map.from(enUs)`; adding the Arabic string is strictly correct and
  matches plan intent.)
- `family_job_selectors.dart` (CREATE) — the three shared selectors, exactly as
  designed; single shared implementation genuinely consolidates the previously
  duplicated role/emirate/days-off UI (the no-duplication goal is met, not just
  relocated — both screens now call the same widgets).
- `family_profile_controller.dart` — every listed change: `cityEmirate`,
  `daysOff`, `rolesOtherCtrl`; `LocationService`/`detectingCity`/`autoDetectCity`
  removed; hydration guards for legacy city and legacy schedule; the three
  validation changes; `cityLabel` computed once after the `fid` guard and
  dual-written to `FamilyModel.city` + `JobPostModel.city`; conditional
  `rolesOther` persist.
- `family_form_screen.dart` / `family_edit_screen.dart` — location picker →
  `FamilyEmirateSelector`; role `Wrap` → `FamilyRoleSelector` under
  `fldRolePrompt`; schedule field → `FamilyDaysOffSelector` under `fldDaysOff`;
  `kafi_location_picker` import and `_detectingCity()` helper removed. Languages
  `Wrap` and job-type/employment toggles left intact (verified untouched).
- `job_detail_screen.dart` — "Days off" reading `job.daysOff`.
- `my_jobs_screen.dart` (D5) — `_schedule` controller, its field, its
  `copyWith` arg removed; doc comment updated; title+salary quick-edit remain.
- `admin firestore.ts` — `JobPostRow.daysOff`, mapper reads `data.daysOff`, all
  5 mock seeds (j1–j5) reseeded with canonical values. `rolesOther` correctly
  **not** added to the row/UI (plan's explicit deferral; build note notes an
  initial mistaken add was reverted before compile — confirmed absent).
- `FamilyDetail.tsx` / `TrialDetail.tsx` — "Days off" `Field` reading
  `job.daysOff`. No residual `.schedule` field references in admin `src`
  (the two `grep` hits are the word "scheduled" in mock dispute prose).

## Flagged deviation — verified genuinely forced & mechanical

I read the actual diff to both test files. Both are legitimate forced,
no-behavior-change fixes, **not** scope creep:

- `test/i18n/localization_test.dart` — dropped only the `schedule:` ctor arg
  and the `localizedSchedule('ar')` assertion (both reference deleted symbols);
  the test title was updated to match; jobTitle/additionalNotes coverage in the
  same test is unchanged. Correct — the test cannot assert on a method the plan
  deleted.
- `test/onboarding/onboarding_validation_test.dart` — pure field-rename
  updates mirroring the production rename: `c.city.value` → `c.cityEmirate.value`,
  `c.scheduleCtrl.text` → `c.daysOff.value`, the "empty schedule" test's
  expected key `familyScheduleRequired` → `familyDaysOffRequired` (description
  renamed), and `_fillValidFamily` now seeds `Emirate.dubai` / `'1 day off'`.
  The file already imports `nanny_model.dart`, so `Emirate.dubai` resolves.
  No new test semantics beyond the rename.

The plan's D5 established the precedent for exactly this class of
search-missed forced dependency; the developer applied it correctly and
flagged it. Approved.

**One additional forced deletion not in the plan's file list, correctly
handled:** `JobPostModel.localizedSchedule()` was removed because it read the
now-deleted `schedule` field and could not compile. Grep confirms **zero**
callers anywhere. This is a minimal mechanical consequence of the planned field
removal, not a design decision, and the build note flagged it. Approved.

## Acceptance criteria (plan §7 DoD) — each PASS with evidence

1. No location machinery reachable from the family city field/controller —
   **PASS** (grep gate zero; `autoDetectCity`/`LocationService`/`detectingCity`
   removed from controller; `KafiLocationPicker` import gone from both screens;
   picker still exists for the out-of-scope trial screen, correctly untouched).
2. Single-select of the 7 real emirates from the reused `Emirate` enum,
   persisted as canonical label to both models from one value — **PASS**.
3. `homeLanguages` == the exact 8-item list; "Other" has no reveal — **PASS**.
4. `roles` == the exact 11-item list; multi-select; "Other" reveals a required
   field → `rolesOther`; two duplicated role UIs now one shared widget — **PASS**.
5. `schedule` gone; `daysOff` replaces it; 1/2/Other single-select with no
   elaboration; validation requires a selection — **PASS**.
6. `job_detail_screen`, `FamilyDetail`, `TrialDetail`, `JobPostRow`+mapper+mock
   seeds all read/display `daysOff` ("Days off") — **PASS**.
7. `my_jobs_screen` compiles with the schedule quick-edit removed — **PASS**
   (`flutter analyze` clean).
8. `flutter analyze` + admin `tsc -b && vite build` pass — **PASS** (reproduced).
9. No phase-1/3 file edited; `Emirate` imported not redefined; `Emirate.alAin`
   never referenced in new code — **PASS**.

## Non-blocking Minors (do NOT block the PR; fixer-optional, or defer)

All three are explicitly pre-authorized by the plan; listing for the record.

- **Minor 1 — stale `'schedule'` key in the i18n field list.**
  `job_post_model.dart:251` and `firestore_job_service.dart:179` still pass
  `const ['jobTitle', 'schedule', 'additionalNotes']` to `i18nMapsFrom`. Now
  that the field is gone, `'schedule'` is a dead key. **Harmless** — an absent
  key is simply never found; `daysOff` is a fixed canonical set that needs no
  per-doc machine translation (plan D2 reasoning). *Root cause:* the translation
  field list was defined against the old schema and the plan deliberately kept
  the translation layer out of scope. *Optional fix (only if a functions/i18n
  cleanup task picks it up):* drop `'schedule'` from both lists. Leave as-is
  otherwise — do not chase it this phase.
- **Minor 2 — defined-but-unused l10n keys.** `fldSchedule`,
  `familyScheduleRequired`, `jobFieldSchedule`, `locationDetecting`, `fldCity`,
  and `familyScheduleHint` remain defined and unused. The plan explicitly says
  removing them is optional cleanup, not required. Leave as-is.
- **Minor 3 — legacy data will not pre-select on edit.** Family records holding
  old free-text city ("Dubai Marina, Villa 3") or old language/role labels
  ("Filipino", "Caregiver", "Helper", "Pet Caretaker") won't match the new
  chips and simply show unselected on the edit screen. This is *intended and
  correct* per the plan's tolerant-hydration design (no crash), and the exact
  lists were mandated by the plan. Not a defect; noted only so it isn't
  mistaken for one later. No action.

## Summary for PM

REVIEW_PASS — 0 Critical, 0 Major, 3 pre-authorized Minors. Build matches the
plan file-by-file, D1–D5 honored, all 9 DoD criteria pass with independently
reproduced `flutter analyze`/`flutter test` (149 passing)/`tsc`/`vite` and the
§6 grep gate. No blocker. Clear to open the PR.
