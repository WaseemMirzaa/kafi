---
slug: kafi-nanny-profile-fields
project: kafi
title: Review — Nanny profile field overhaul (languages, emirate-only location, employment type + part-time availability, restructured work experience, drop emergency contact)
owner: architect-reviewer
status: REVIEW_PASS
updated: 2026-08-15
branch: claude/kafi-nanny-profile-fields
---

# Review — Nanny profile field overhaul

**Verdict: REVIEW_PASS.** Zero Critical, zero Major. The build implements the
plan file-by-file with no design deviations. All 9 acceptance criteria pass,
independently verified. Two non-blocking Minors are noted below for an optional
fixer touch-up; neither blocks merge.

## How I verified (not trusting the build note)

- Read the plan, build note, and the full `git diff origin/main...origin/claude/kafi-nanny-profile-fields`
  for all 13 files.
- **Independently re-ran the toolchain** (Flutter 3.35.7 stable, matching
  `.fvmrc`, from the shared scratchpad SDK): `flutter pub get` →
  `flutter analyze` = **"No issues found!"**; `flutter test
  test/onboarding/onboarding_validation_test.dart test/services/match_service_test.dart`
  = **"00:17 +94: All tests passed!"** (94/94, incl. the 3 new employment/
  part-time cases). Both match the build note's claims exactly.
- **Grep-verified every critical removal against the whole branch tree**, not
  the build note's assertions:
  - `KafiLocationPicker`: **zero** call sites in `nanny_info_screen.dart` and
    `nanny_exp_screen.dart`. Remaining refs are all out-of-scope (family
    screens, `trial_offer_screen`, `nanny_refs_screen`, the widget def, and a
    doc comment in `kafi_searchable_picker`). ✓
  - `alAin`: **zero** as an enum value or UI box anywhere; the only occurrences
    are inside `nanny_map_codec.dart`'s `_emirateByName` remap helper + its
    comments. ✓
  - Emergency fields (`emergencyName/Relationship/CountryCode/Phone` and the 3
    controllers): **zero** references in `lib/` or `test/`. Fully removed. ✓
  - `cityCountry`: only surviving reference is the intended legacy read-fold in
    `_experienceFromMap` (`city: m['city'] ?? m['cityCountry'] ?? ''`). ✓
  - `currentAreaCtrl` / `currentLocationPicked`: **zero** references. `NannyModel
    .currentLocation`: **zero** (the `currentLocation` grep hits are all
    `_currentLocationTile` inside `kafi_location_picker.dart`, an unrelated GPS
    "use current location" list tile — not the removed model field). ✓
  - `Emirate` enum = exactly **7** values `{dubai, abuDhabi, sharjah, ajman,
    rak, fujairah, uaq}`. ✓
  - `hasPersonalInfo` getter is **byte-for-byte unchanged** (still checks
    `currentArea.trim().isNotEmpty`); `auth_controller.dart` is **not in the
    diff at all**. ✓
  - No hardcoded nanny language list survives outside `NannyConstants.languages`
    (the other `'English'` hits are family-side / mock data, out of scope). ✓

## Acceptance criteria — each PASS with evidence

1. **No GPS/picker reachable from current-location or exp-city fields** — PASS.
   Grep confirms both `KafiLocationPicker` call sites removed; `_workLocation()`
   ends after the relocate toggle with no picker; exp `build()` uses two plain
   `KafiTextField`s.
2. **Emirate lists show exactly 7, no "Al Ain"** — PASS. Both grids iterate one
   `static const _emirates` records list (7 entries, names from `EmirateX.label`);
   the old 8th `_emirateBox('🌴','Al Ain',...,Emirate.alAin,...)` line is deleted.
3. **Legacy `alAin` reads back as `abuDhabi`** — PASS. `_emirateByName` remaps
   the raw string *before* enum lookup, applied to both `workEmirates` (with
   `.toSet()` de-dup so a doc holding both collapses to one `abuDhabi`) and
   `currentEmirate`. Exercised on every load; no migration script needed. This
   is the architect's chosen codec-level mechanism and it genuinely covers the
   criterion.
4. **Employment-type multi-select persists** — PASS. `EmploymentType` enum +
   `List<EmploymentType> employmentTypes` through model/copyWith/toMap; codec
   parse via `_enumByName`; controller `toggleEmploymentType`; UI 3 ×
   `KafiToggleTile`.
5. **Part-time availability conditional + independent per-day times + blocks
   completion** — PASS. UI renders `_partTimeAvailability()` only when
   `partTime` is selected; each selected day gets independent from/until
   `showTimePicker` fields; `validatePersonalInfo` returns
   `nannyPartTimeAvailabilityRequired` unless every selected day has both times.
   Deselecting Part-Time clears availability (`toggleEmploymentType`).
   Independently confirmed by the 3 new green tests.
6. **Work experience Country + City (plain text) + role/dates/responsibilities,
   no GPS** — PASS. `WorkExperience` split into `country`/`city`; exp card uses
   two `KafiTextField`s; job role dropdown/dates/duties untouched; legacy
   `cityCountry` folds into `city` on read.
7. **Emergency gone from both screens; Bio remains; drafts' routing intact** —
   PASS. Both `_emergency()`/edit-profile emergency `_section` removed; Bio
   unchanged and still last. `hasPersonalInfo` unchanged and still true for a
   legacy draft because `currentArea` remains populated (new saves mirror it
   from `currentEmirate.value?.label`), so `_nannyStartRoute` still resumes such
   a nanny at step 2 — the §1.2 decision holds under trace.
8. **One canonical language list (12 + Other) in both screens** — PASS.
   `NannyConstants.languages` updated verbatim; edit-profile's hardcoded 6-item
   list replaced with `KafiChip` over `NannyConstants.languages` reusing
   `ctrl.toggleLanguage`; onboarding already read it. No third list remains.
9. **`flutter analyze` clean; tests pass/updated** — PASS. Independently
   reproduced: analyze clean, 94/94 tests green, `match_service_test`'s `exp()`
   fixture updated to `country/city`.

## Plan adherence

Walked §3.1–§3.10 against the diff. Every prescribed edit is present and
correct: model field add/remove set and ordering; codec `_emirateByName` +
`_dayAvailabilityFromMap` + dedup + legacy `cityCountry` fold; controller
state swap, new toggle/setDay methods, `_hydrate`/`saveProfileDraft`/
`savePersonalInfoAndNext`/`validatePersonalInfo` edits; both screens; edit-
profile; l10n keys in `app_strings.dart` + **both** locale maps with genuine
Arabic; both test files. `geo_location.dart` import correctly **kept** in
`nanny_model.dart`/`nanny_map_codec.dart` (still needed by
`ReferenceContact.location`) and **removed** from `nanny_profile_controller.dart`
and `nanny_exp_screen.dart` where it became unused — exactly per §1.4.

The build note's two "implementation-only" choices are legitimate and within
the plan's latitude, not architecture decisions:
- The private `_updateDay(weekday, {from, until})` helper backing
  `setDayFrom`/`setDayUntil` — same two public signatures/behavior the plan
  specifies, DRY internally. Fine.
- Field ordering of the new model fields adjacent to their semantic siblings —
  consistent across constructor/fields/copyWith/toMap. Fine.

No unplanned scope expansion. Admin-panel impact and dead l10n keys are
correctly flagged-not-fixed per §8/§3.8.

## Findings

### Minor 1 (non-blocking) — `_dayTimeRow` uses `firstWhere` with no `orElse`
- **Where:** `kafi_app/lib/views/nanny/nanny_info_screen.dart`, `_dayTimeRow(DayAvailability d)`:
  `final dayLabel = _weekdays.firstWhere((w) => w.$1 == d.weekday).$2.tr;`
- **What & evidence:** `firstWhere` without an `orElse` throws `StateError` if
  no `_weekdays` entry matches `d.weekday`. In practice `d.weekday` is always
  1–7 (the only writer is `toggleDay(weekday)` fed from `_weekdays`, and
  `partTimeAvailability` is a net-new field with no legacy data), so this never
  fires today — hence Minor, not a live bug. But `_dayAvailabilityFromMap`
  reads `weekday: (m['weekday'] as num?)?.toInt() ?? 1` with no range clamp, so
  a hand-tampered Firestore doc holding e.g. `weekday: 0` or `8` would reach
  this and crash the Step-1 render.
- **Root cause:** the UI trusts a codec value that the codec itself doesn't
  constrain to the enum-equivalent 1–7 domain — a small validate-at-boundary
  gap, the same class of defensiveness the rest of the codec already applies
  (defaults/`whereType`).
- **Exact fix (fixer, no redesign):** in `nanny_map_codec.dart`
  `_dayAvailabilityFromMap`, clamp the weekday to the valid range so out-of-
  range data can never reach the UI, e.g.:
  ```dart
  final wd = (m['weekday'] as num?)?.toInt() ?? 1;
  return DayAvailability(
    weekday: (wd < 1 || wd > 7) ? 1 : wd,
    from: m['from']?.toString() ?? '',
    until: m['until']?.toString() ?? '',
  );
  ```
  (No UI change needed once the codec guarantees 1–7. Do not change the plan's
  `_dayTimeRow` structure.)

### Minor 2 (non-blocking, pre-existing — not introduced by this build)
- **Where:** `nanny_info_screen.dart` — the purple info banner text
  (`'Select every emirate you are willing to work in. …'`) and the emirate
  subtitle strings in the `_emirates` records list (`'Most jobs'`,
  `'Capital · High demand'`, …).
- **What & evidence:** these are hardcoded English literals, not `AppStrings`
  keys. They are **carried over verbatim** from the pre-existing inline
  `_emirateBox(...)` calls (the banner predates this task; the plan explicitly
  prescribed moving the subtitles into the records list as-is). No regression
  is introduced and no acceptance criterion requires them localized.
- **Root cause:** pre-existing i18n debt in this screen, outside this task's
  field scope.
- **Recommendation:** leave for a dedicated `nanny_info_screen` localization
  sweep (same bucket as the dead emergency/location l10n keys §3.8 already
  flags). **Do not** expand this task to fix it.

## Genuinely clean (called out so the fixer doesn't churn them)
- Codec remap + `.toSet()` de-dup ordering: `LinkedHashSet` preserves insertion
  order, so `workEmirates` display order is stable. Correct.
- `savePersonalInfoAndNext` writes `currentArea: currentEmirate.value?.label ?? ''`
  (display mirror) while `validatePersonalInfo` blocks save on
  `currentEmirate == null`, so the mirror is always non-empty for new saves —
  keeps `hasPersonalInfo`, the dashboard, browse cards, and admin `currentArea`
  correct without touching them (§1.3). Verified by trace.
- `saveProfileDraft` (edit-profile) correctly no longer writes `currentArea`/
  emergency, so it can't clobber a legacy nanny's stored `currentArea` with an
  empty string. Correct.
- Design-system conformance: `_currentEmirateBox`/`_timeField`/`_employmentTile`/
  day chips all use `KafiColors.*` tokens, `KafiTheme.nunito(...)`, and existing
  primitives (`KafiToggleTile`, `KafiChip`, `KafiSection`, `showTimePicker`) —
  no new hardcoded hex, no generic styling.

## Note to PM
- **REVIEW_PASS** — 0 Critical, 0 Major, 2 non-blocking Minors (a codec weekday-
  clamp defensive fix, and pre-existing screen i18n debt). analyze clean and
  94/94 tests independently reproduced. Safe to open the PR; the two Minors can
  ship as-is or be folded into a trivial fixer pass at your discretion.
