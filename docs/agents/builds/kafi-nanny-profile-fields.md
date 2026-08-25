---
slug: kafi-nanny-profile-fields
project: kafi
title: Nanny profile — languages, emirate-only location, employment type + part-time availability, restructured work experience, drop emergency contact
owner: developer
status: READY_FOR_REVIEW
updated: 2026-08-15
branch: claude/kafi-nanny-profile-fields
---

# Build — Nanny profile field overhaul

Implements `docs/agents/plans/kafi-nanny-profile-fields.md` exactly. All file:line
pointers in the plan matched the real code (independently re-verified before
editing — see below); no line-number drift was found, so no adaptation was
needed anywhere. Zero design deviations — every field removal/addition, every
explicit decision (§1.2 `hasPersonalInfo` untouched, §1.3 `currentArea` mirror,
§1.4 GeoLocation-field removal) was implemented as specified.

## Pre-flight: plan verification

Before writing any code, all seven affected files plus the widget primitives
(`KafiChip`, `KafiToggleTile`, `KafiSection`, `KafiTextField`) and the l10n
files were freshly read, and every one of the plan's file:line citations was
checked against the real content. All matched exactly (constructor param
lines, field-declaration lines, `copyWith`/`toMap` line numbers, l10n key line
numbers, test line numbers) — the plan's "read twice, corrected twice" claim
held up under a third independent check. Repo-wide greps for `cityCountry`,
`currentLocation`, `currentArea`, the 4 emergency field names, and
`Emirate.alAin` independently reproduced the plan's §0 authoritative file
lists exactly (7 files for `currentArea`, 5 for emergency fields in
production code, etc.).

## Files changed

### `lib/models/nanny_model.dart` (WU-1)
- `Emirate` enum: 8 → 7 values (dropped `alAin`); added `EmirateX.label`
  extension as the single source of emirate display names.
- Added `EmploymentType` enum and `DayAvailability` value class.
- `WorkExperience`: `cityCountry` split into `country` + `city`; `location`
  (`GeoLocation?`) field removed entirely (its only writer, the exp-screen
  GPS picker, is gone — see §1.4 of the plan for why an inert nullable field
  is worse than deleting it).
- `NannyModel`: removed `currentLocation` (`GeoLocation?`) and all 4 emergency
  fields (`emergencyName`, `emergencyRelationship`, `emergencyCountryCode`,
  `emergencyPhone`) from constructor/fields/`copyWith`/`toMap`. Added
  `currentEmirate` (`Emirate?`), `employmentTypes`
  (`List<EmploymentType>`), `partTimeAvailability`
  (`List<DayAvailability>`).
- `hasPersonalInfo` — **byte-for-byte unchanged**, confirmed by direct read
  after all edits. `geo_location.dart` import kept (still needed by
  `ReferenceContact.location`, out of scope).

### `lib/models/nanny_map_codec.dart` (WU-1)
- Added `_emirateByName` helper: remaps legacy `'alAin'` → `'abuDhabi'` before
  enum lookup, applied to both `workEmirates` (with `.toSet()` de-dup, so a
  doc holding both `abuDhabi` and `alAin` doesn't collide into a duplicate)
  and the new `currentEmirate`.
- Added `_dayAvailabilityFromMap`; wired `employmentTypes`/
  `partTimeAvailability` parsing into `nannyModelFromMap`.
- `_experienceFromMap`: reads `country`/`city`, folding legacy `cityCountry`
  into `city` when `city` itself is absent (old experience entries keep
  showing their text).
- Removed `currentLocation` and the 4 emergency-field reads.
- `_geoFromMap` helper, its import, and `_referenceFromMap`'s use of it — all
  kept, unchanged (still needed by `ReferenceContact`).

### `lib/utils/constants/nanny_constants.dart` (WU-1)
- `languages` replaced verbatim with the canonical 12 + Other list.
  `totalSteps` (6) and everything else untouched.

### `lib/l10n/app_strings.dart` + `locales/en_us.dart` + `locales/ar_ae.dart` (WU-2)
- Added every key from the plan's §3.8 table (current-emirate label, "Any
  Emirate", employment section/question/3 tiles/required message, part-time
  question/from/until/required message, `dayMon`…`daySun`, `expCountry`,
  `expCity`) to `app_strings.dart` and both locale maps. Arabic values are
  genuine translations, not English fallbacks, per the plan's explicit
  instruction (the file's usual convention lets many older keys silently
  fall back to English via `ar_ae.dart`'s `Map.from(enUs)..addAll(...)`
  pattern; this build's new keys deliberately don't rely on that fallback).
- Left the now-unused emergency/location keys in place (flagged dead, not
  deleted) per plan §3.8, to avoid touching unrelated call sites.

### `lib/controllers/nanny_profile_controller.dart` (WU-3)
- `currentAreaCtrl` + `currentLocationPicked` → `Rx<Emirate?> currentEmirate`.
- Removed the 3 emergency `TextEditingController`s + `emergencyCountryCode`
  Rx and their `dispose()` calls; removed the `geo_location.dart` import
  (its only use, `currentLocationPicked`, is gone).
- Added `employmentTypes`/`partTimeAvailability` `RxList`s and
  `toggleEmploymentType`, `toggleDay`, `setDayFrom`/`setDayUntil` (via a
  shared private `_updateDay` — same externally-visible behavior the plan
  describes, DRY internally), `toggleAnyEmirate`, `allEmiratesSelected`.
- `_hydrate`, `saveProfileDraft`, `savePersonalInfoAndNext`: updated for the
  field swap. `savePersonalInfoAndNext` writes `currentArea:
  currentEmirate.value?.label ?? ''` — the denormalized display mirror from
  plan §1.3, keeping the dashboard/browse-card/admin-panel readers correct
  without touching them.
- `validatePersonalInfo`: current-area text check → `currentEmirate.value ==
  null` check (same message key, no l10n churn); 3 emergency checks removed;
  added `employmentTypes.isEmpty` check + the part-time availability gate.

### `lib/views/nanny/nanny_info_screen.dart` (WU-3)
- Removed `kafi_location_picker.dart`, `auth_constants.dart`,
  `kafi_phone_input.dart` imports (each confirmed by grep to be used only
  inside the deleted `_emergency()`/`_emergencyCodeOptions`/the deleted
  picker call).
- `build()` children: `_emergency()` removed, `_employment()` inserted after
  `_workPrefs()`. No new onboarding step — stays inside step-1's existing
  `KafiStepScaffold(step: 1, ...)`, `NannyConstants.totalSteps` untouched.
- `_workLocation()` reworked into: (1) net-new current-emirate single-select
  grid (`_currentEmirateBox`, no picker), (2) existing preferred-emirates
  multi-select minus the Al Ain box (7 boxes) plus a new "Any Emirate"
  `KafiChip`, (3) the existing relocate toggle unchanged, (4) the
  `KafiLocationPicker` block deleted entirely. Both emirate grids are driven
  by one private `_emirates` list of `(Emirate, emoji, subtitle)` records
  (names from `EmirateX.label`) so the two grids can never drift out of sync
  again — this was the plan's own prescribed fix for the original Al Ain bug.
- Added `_employment()` (3 `KafiToggleTile`s, purple) and
  `_partTimeAvailability()` (7 `KafiChip` day toggles + per-selected-day
  from/until fields using `showTimePicker`, formatted `"HH:mm"`).

### `lib/views/nanny/nanny_edit_profile_screen.dart` (WU-3)
- Languages: hardcoded 6-item list + bespoke chip widget → `KafiChip` over
  `NannyConstants.languages`, reusing the controller's existing
  `toggleLanguage`.
- Emergency Contact `_section(...)` block removed entirely (all 3
  `KafiInput`s; there was no country-code UI on this screen to begin with).
- Class doc comment updated to drop "emergency contact" from the list of
  editable fields.

### `lib/views/nanny/nanny_exp_screen.dart` (WU-4)
- Removed `geo_location.dart` and `kafi_location_picker.dart` imports.
- `_addBtn`'s default `WorkExperience`: `cityCountry: ''` → `country: '',
  city: '',`.
- `_ExpCardState`: added `_country` controller alongside `_city`; deleted
  `GeoLocation? _cityLocation` and its seed. `_country` added to the
  listener/dispose loops.
- `_emit()`: builds `WorkExperience(..., country: _country.text, city:
  _city.text, ...)`, no `location:` arg.
- `build()`: the single labeled `KafiLocationPicker` replaced with two plain
  `KafiTextField`s (Country, City), no picker, no GPS callback anywhere on
  this screen.

### `test/onboarding/onboarding_validation_test.dart` (WU-5)
- `_fillValidPersonalInfo`: `currentAreaCtrl.text` → `currentEmirate.value =
  Emirate.dubai`; 3 emergency fills removed; added
  `employmentTypes.assignAll([EmploymentType.fullTimeLiveIn])` so the base
  "passes" case stays valid.
- "empty current area is rejected" now sets `currentEmirate.value = null`.
- Removed the 3 emergency tests.
- Added 3 tests: no employment type is rejected, part-time with no
  availability is rejected, part-time with a day+times passes.

### `test/services/match_service_test.dart` (WU-5)
- `exp()` fixture helper: `cityCountry: 'Dubai'` → `country: 'UAE', city:
  'Dubai'`. Compile-fix only — `match_service.dart` itself untouched
  (confirmed out of scope: `_locationScore` compares `workEmirates` against
  `job.city`, unaffected by the enum shrinking; `_skillsScore` reads only
  `jobTitle`/`children`).

## Commands run and results

Flutter 3.35.7 (stable, matching `.fvmrc` / CI's pinned version) was not
present in this environment, so it was installed fresh (git clone to the
scratchpad dir, outside the repo) to actually run verification rather than
skip it.

```
$ flutter pub get
Got dependencies!

$ flutter analyze
Analyzing kafi_app...
No issues found! (ran in 6.5s)

$ flutter test test/onboarding/onboarding_validation_test.dart test/services/match_service_test.dart
00:17 +94: All tests passed!
```

94/94 tests green (40 in the onboarding file — including the 3 new
employment/part-time cases — + 54 in match_service_test.dart), zero analyzer
issues, including zero unused-import warnings from the removed
picker/GeoLocation call sites.

## Definition of done — §7 checklist

- [x] `Emirate` enum has exactly 7 values (no `alAin`); both emirate grids
      render the same 7 from the shared `_emirates` list (built from the same
      7 values as `Emirate.values`, in the same order) + `EmirateX.label`.
- [x] Codec `_emirateByName` remaps `'alAin' → 'abuDhabi'` on read for
      `workEmirates` (de-duped via `.toSet()`) and `currentEmirate`.
- [x] `NannyConstants.languages` is the canonical 12 + Other list, verbatim;
      both onboarding `_basic()` and edit-profile read it (grep-confirmed: no
      third hardcoded nanny-language-picker list exists anywhere in `lib/`).
- [x] Current location is a single-select of the 7 emirates writing
      `currentEmirate` (+ `currentArea` label mirror); `NannyModel
      .currentLocation` and `WorkExperience.location` are removed from
      model/codec/controller/screens; `ReferenceContact.location` untouched;
      `KafiLocationPicker` call sites in both `nanny_info_screen.dart` and
      `nanny_exp_screen.dart` are removed, and their now-unused imports
      (`kafi_location_picker.dart`, `geo_location.dart`, `auth_constants.dart`,
      `kafi_phone_input.dart`) are removed too. Grep-confirmed post-edit:
      `KafiLocationPicker(` call sites remaining are only in
      `nanny_refs_screen.dart`, `trial_offer_screen.dart`,
      `family_form_screen.dart`, `family_edit_screen.dart` — all out of
      scope. No GPS/Places call is reachable from the current-location or
      work-experience-city fields.
- [x] Preferred job location = 7-emirate multi-select + working "Any Emirate"
      (`toggleAnyEmirate` writes all of `Emirate.values`, 7 entries).
- [x] Employment-type section exists, persists, and is required via
      `validatePersonalInfo` (not `hasPersonalInfo` — confirmed unchanged).
- [x] Part-time availability shows only when Part-Time is selected; each
      selected day has independent from/until; zero days or any missing time
      blocks completion via `nannyPartTimeAvailabilityRequired` (test-covered).
- [x] Work experience collects Country + City (plain text, no picker) + Job
      role + Start + End + Main responsibilities; legacy `cityCountry`
      migrates into `city` at codec read time.
- [x] Emergency Contact (all 4 fields, including `emergencyCountryCode`)
      removed from model, codec, controller, both screens, and its
      validation + tests. Grep-confirmed zero remaining references anywhere
      in `lib/` or `test/`. `validatePersonalInfo` no longer references any
      emergency field; Step-1 completion is unaffected (test-covered).
- [x] `hasPersonalInfo` and `auth_controller.dart` are unmodified — confirmed
      by direct diff (neither file appears in `git status`/`git diff`
      against `origin/main`). The pre-existing-draft resume flow (plan §6
      flow 6) was verified by static code-path reasoning (`currentArea`
      keeps being written in lockstep with `currentEmirate`, so a legacy
      draft's already-saved `currentArea` text keeps `hasPersonalInfo` true
      exactly as before) rather than clicked through live — no
      emulator/device is available in this headless environment. Flagged
      below as a review-time follow-up.
- [x] All new user-facing strings are `AppStrings` keys present in both
      `en_us.dart` and `ar_ae.dart`.
- [x] `flutter analyze` clean; onboarding + match_service tests updated and
      passing (see command output above).

## Deviations from the plan

None in design or behavior. A few implementation-only choices where the plan
left the exact spot/organization open (all produce exactly the behavior the
plan describes):
- Field order for `currentEmirate`/`employmentTypes`/`partTimeAvailability`
  in `NannyModel`'s constructor/fields/`copyWith`/`toMap` — placed adjacent
  to their semantic siblings (work-location cluster, work-prefs cluster),
  kept consistent across all four regions.
- `setDayFrom`/`setDayUntil` share a private `_updateDay` helper instead of
  duplicating the "replace entry via `copyWith`, reassign the `RxList`"
  logic twice — same two public signatures/behavior the plan specifies.
- Removed one redundant `SizedBox` spacer in two places where deleting a
  whole section (edit-profile's Emergency block; the exp-screen's
  picker→2-fields swap) would otherwise have left a doubled gap where a
  single one exists everywhere else in the same card/screen — matches the
  existing spacing convention rather than introducing a visible regression.

## Known gaps / follow-ups (flagged, not acted on — out of scope per plan)

- **Manual UI flows** (plan §6, items 1–7) were verified by reading the code
  paths, not by driving a running app — this environment has no
  emulator/device. Recommend the architect-reviewer or a manual QA pass
  confirms the on-device look/feel (grid layout, time-picker UX, chip
  wrapping) before merge.
- **Admin panel** (`admin-panel/src/services/firestore.ts`,
  `AllNannies.tsx`, `NannyProfileView.tsx`): after this ships, newly-saved
  nanny docs stop writing `cityCountry` (experience) and
  `emergencyName`/`emergencyRelationship`/`emergencyPhone`, so those fields
  will show blank for new saves (existing docs keep their old values until
  re-saved); the new `currentEmirate`/`employmentTypes`/
  `partTimeAvailability`/experience `country`+`city` fields aren't displayed
  there at all. The `currentArea` display/search stays populated (the §1.3
  mirror). Untouched here per plan §8 — needs a follow-up admin-panel task.
- **Dead l10n keys** (`secEmergency`, `fldEmergencyName/Rel/Phone`,
  `nannyEmergency*Required`, `editEmergencyContact`, `fldCurrentArea`,
  `expCityCountry`) intentionally left in place per plan §3.8 — candidate
  for an optional later cleanup sweep.
- **`employmentTypes` / `jobTypePreference` overlap** — noted but not acted
  on per plan §5 (would require editing `match_service.dart`, out of scope
  and a cross-phase collision zone with the family-profile phase).

## Branch

`claude/kafi-nanny-profile-fields`, based on `origin/main` @ `168c39864d6a90162e393a36b5245941d67e7a7d`.
5 commits (WU-1 through WU-5), pushed to `origin/claude/kafi-nanny-profile-fields`.
