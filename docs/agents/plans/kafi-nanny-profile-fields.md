---
slug: kafi-nanny-profile-fields
project: kafi
title: Nanny profile — languages, emirate-only location, employment type + part-time availability, restructured work experience, drop emergency contact
owner: architect
status: READY_FOR_BUILD
updated: 2026-08-15
epic: kafi-profile-trial-overhaul (phase 1 of 3 — parallel with kafi-family-profile-fields and kafi-trial-completion-flow)
branch: (developer creates its own worktree/branch for this slug)
---

# Plan — Nanny profile field overhaul

Static plan only (no Flutter toolchain in this env). Developer runs
`flutter analyze` + `flutter test` before marking `READY_FOR_REVIEW`.

## 0. Source-vs-scope reconciliation (read the real code — corrected twice)

**Correction note.** This plan was rewritten after the PM flagged that my first
pass was read while a concurrent `git checkout -B <branch> origin/main` in the
same shared working directory was rewriting the tree — every "doesn't exist"
claim in the original §0 turned out to be wrong. Everything below was
re-established via fresh, sequential `Read` calls on all seven affected files
plus repo-wide `Grep` sweeps for every field/type being touched, taken after
the PM confirmed the filesystem was stable. Where a grep result mattered for a
design decision, I cite the exact file:line it came from.

Confirmed real state (all five of the PM's flagged claims were wrong; I also
caught a 6th stale claim on my own re-check, see (f)):

- **(a) `NannyModel.currentLocation` (`GeoLocation?`) exists** —
  `lib/models/nanny_model.dart:269`, wired through the constructor (line 199),
  `copyWith` (param 423, body 490), and `toMap` (559, conditional).
- **(b) `WorkExperience.location` (`GeoLocation?`) exists** — same file, field
  at line 48, constructor param at line 33, `toMap` conditional at line 60.
- **(c) `NannyModel.hasPersonalInfo` exists** (lines 363–370) and is genuinely
  read by `lib/controllers/auth_controller.dart:366` inside `_nannyStartRoute`,
  which decides where a `draft`-status nanny resumes onboarding. See §1.2 for
  how this plan accounts for it.
- **(d) There are 4 emergency fields, not 3**: `emergencyName`,
  `emergencyRelationship`, `emergencyCountryCode` (default `'+971'`),
  `emergencyPhone` — all at `nanny_model.dart` lines 225–228 (constructor),
  295–298 (fields), 449–452/516–519 (copyWith), 585–588 (toMap). Repo-wide grep
  for all four names confirms exactly 5 Dart files reference any of them:
  `nanny_model.dart`, `nanny_map_codec.dart`, `nanny_profile_controller.dart`,
  `nanny_info_screen.dart`, `nanny_edit_profile_screen.dart` — the same 5 files
  this plan already edits for the other reasons below, so this is a same-file,
  same-edit-point correction (add the 4th field to each removal list), not a
  new file to touch.
- **(e) `nanny_exp_screen.dart` DOES call `KafiLocationPicker` with GPS
  capture** — confirmed at lines 280–288: it wraps the city field in a
  `KafiLocationPicker(..., onLocationPicked: (loc) { _cityLocation =
  loc.toGeoLocation(); _emit(); })`, and `_cityLocation` (a `GeoLocation?`
  instance field, set at line 145/151/176) is threaded into
  `WorkExperience(..., location: _cityLocation)`. My first pass said this
  screen already used a plain text field with no picker — wrong. §3.6 below
  now removes this call site explicitly, the same way §3.5 removes the
  current-location picker.
- **(f) Self-caught: `firestore_job_service.dart` does NOT read `currentArea`
  directly.** My first pass claimed `city: m['currentArea'] ?? 'Dubai'` at
  line 37 of that file; a fresh repo-wide grep for `currentArea` (glob `*.dart`)
  found no match there at all. The real reader is
  **`lib/models/nanny_card_model.dart:59`**: `NannyCardModel.fromNanny(n)`
  builds `city: n.currentArea` for every browse/shortlist card, which feeds
  `match_service.dart`'s card-fallback `_cardLocation` scorer and browse-list
  display. This changes *which* file I cite as the reason `currentArea` must
  stay populated (§1.3), not the underlying design decision, which already
  planned to keep it populated.

Authoritative reference lists (fresh, repo-wide grep, glob `*.dart` /
`admin-panel/src`), used to build every removal list in §3:

- `currentArea` (Flutter): exactly 7 files —
  `test/onboarding/onboarding_validation_test.dart`,
  `nanny_dashboard_screen.dart` (line 84, not 79 as I first miscounted — reader,
  stays untouched), `nanny_info_screen.dart`, `nanny_card_model.dart` (line 59
  — reader, stays untouched), `nanny_map_codec.dart`, `nanny_model.dart`,
  `nanny_profile_controller.dart`.
- `currentLocation` / `WorkExperience(...).location` (Flutter): only
  `nanny_model.dart`, `nanny_map_codec.dart`, `nanny_info_screen.dart`,
  `nanny_exp_screen.dart`, `nanny_profile_controller.dart`, plus
  `match_service_test.dart`'s `WorkExperience(` constructor call (which never
  passes `location:`, so needs no change beyond the already-planned
  `cityCountry` fix). `ReferenceContact.location` is a **separate field on a
  separate class** used only by `nanny_refs_screen.dart:289` (out of scope,
  confirmed by grep) — never touched by this plan.
- Emergency fields (Flutter): exactly the 5 files listed in (d) above.
- Admin panel (`admin-panel/src`, TypeScript, out of scope, read-only check):
  `firestore.ts` types `currentArea?: string`, `cityCountry: string`,
  `emergencyName?/emergencyRelationship?/emergencyPhone?` (no
  `emergencyCountryCode` field ever existed on the TS side), and mock nanny
  data includes `workEmirates: [..., 'alAin']`. `AllNannies.tsx` and
  `NannyProfileView.tsx` display `currentArea`. See §8 for what this means.

## 1. Architecture summary

The nanny onboarding is a GetX flow: one controller (`NannyProfileController`)
holds all form state as `Rx*`/`TextEditingController`s, screens are `GetView`s
that `Obx`-bind to it, and persistence goes model → `toMap()` →
`IUserService.saveNanny`, read back via `nannyModelFromMap` in
`nanny_map_codec.dart`. This plan stays entirely within that pattern — no new
state-management or data-layer concepts.

### 1.1 Emirate 8→7 + Al Ain remap

Drop `Emirate.alAin` from the enum. Because a dropped enum value would make
`_enumByName` return `null` for legacy `'alAin'` strings, the remap is done
**at codec read time**: a dedicated `_emirateByName` helper normalizes the raw
string `'alAin' → 'abuDhabi'` *before* enum lookup, applied to **both**
`workEmirates` and the new `currentEmirate`. This is exercised on every
profile load, so any existing doc holding `alAin` reads back as `abuDhabi`
(acceptance criterion met without a migration script). `workEmirates` is
de-duplicated after remap (a doc that already independently held both
`abuDhabi` and `alAin` would otherwise remap to a list with `abuDhabi` twice).

### 1.2 `hasPersonalInfo` — explicit decision: leave untouched

`hasPersonalInfo` (confirmed to exist, §0(c)) checks exactly six things:
`fullName`, `dateOfBirth`, `visaStatus`, `workEmirates`, `currentArea`, `bio`.
None of the fields I'm removing (the 4 emergency fields) or adding
(`employmentTypes`, `partTimeAvailability`) are part of this check today.

**Decision: do not add `employmentTypes`/`partTimeAvailability` to this
getter, and do not change its `currentArea` check to `currentEmirate`.**
Reasoning:
- `currentArea` continues to be written in lockstep with `currentEmirate` in
  every `copyWith` call this plan touches (§3.4), so for every nanny doc saved
  *after* this ships, `currentArea.isNotEmpty` and `currentEmirate != null`
  are equivalent — the getter's existing check keeps working with zero code
  change, and `auth_controller.dart` (out of scope) needs no edit at all.
- The only case where they could diverge is a **pre-existing draft** nanny who
  completed step 1 under the old field shape (so `currentArea` is a real
  free-text value with no `currentEmirate`). Per the epic's cross-phase note
  ("treat new/changed fields as additive... rather than requiring a
  destructive backfill"), that nanny should resume at step 2 as before, not
  get bounced back to step 1 to satisfy a field that didn't exist when she
  did it. Adding a `currentEmirate != null` check would force exactly that
  regression.
- Symmetrically, requiring `employmentTypes.isNotEmpty` here would also
  retroactively block the same legacy drafts. The forward-looking requirement
  ("a part-time nanny must set at least one day+time to complete her profile")
  is instead enforced once, at the point of explicit submission, by
  `validatePersonalInfo()` (§3.4) — the same mechanism that already gates
  every other required field on this step. `submitForReview()` does not
  re-invoke `validatePersonalInfo()` today (it only re-checks
  `hasRequiredDocs`), so this is consistent with the existing flow's behavior,
  not a new gap.

### 1.3 `currentArea` stays as a populated display mirror

Add `Emirate? currentEmirate` (canonical, typed) to the model. Keep the
existing `String currentArea` field as a denormalized display mirror
(populated from the selected emirate's label) so the two confirmed out-of-scope
readers — `nanny_dashboard_screen.dart:84` and `NannyCardModel.fromNanny`
(`nanny_card_model.dart:59`, which feeds match-service card scoring and browse
cards) — keep working unmodified, and so the admin panel's `currentArea`
display/search (out of scope, §8) is not silently broken either. This is a
deliberate, documented denormalization, not accidental duplication. Controller
state becomes `Rx<Emirate?> currentEmirate` (replacing `currentAreaCtrl`). The
`KafiLocationPicker`/GPS call site is removed.

### 1.4 GeoLocation fields — explicit decision: remove both in-scope ones

`NannyModel.currentLocation` and `WorkExperience.location` (§0(a)/(b)) are
both `GeoLocation?`, populated today only by the two `KafiLocationPicker`
call sites this plan removes (§3.5, §3.6). **Decision: delete both fields**
(constructor param, field, `copyWith` param+body, `toMap` entry; codec read),
rather than leave them as inert nullable fields. Reasoning: once their only
writers are gone, they never become non-null again for a *new* save — but
`copyWith`'s `value ?? this.value` fallback means an **old**, already-stored
GPS coordinate would otherwise be silently re-forwarded and re-persisted on
every subsequent step-1/experience save forever, which is a worse outcome
than removing the field (a stale field nobody can see or clear, still holding
real coordinates, directly undercuts "no GPS reachable from these fields").
Removing them is also the smaller diff: it deletes code instead of adding
dead branches.

**What does NOT move**: `ReferenceContact.location` (a distinct field on a
distinct class, feeding the out-of-scope refs screen) stays exactly as is.
Consequently: the `GeoLocation` class itself, the `geo_location.dart` import
in `nanny_model.dart`, the `_geoFromMap` helper and its import in
`nanny_map_codec.dart` are all **kept** (still needed by `ReferenceContact`).
Only the two in-scope call sites of `_geoFromMap` are removed. The
`geo_location.dart` import is dropped only from the two files where it becomes
fully unused after this change: `nanny_profile_controller.dart` (its only use,
`currentLocationPicked`, is deleted) and `nanny_exp_screen.dart` (its only use,
`_cityLocation`, is deleted).

### 1.5 New fields

- **Employment type (net-new).** Add `EmploymentType { fullTimeLiveIn,
  fullTimeLiveOut, partTime }` and `List<EmploymentType> employmentTypes`
  (multi-select, additive). `jobTypePreference` (liveIn/liveOut/both, feeds
  `match_service.dart`, out of scope) is untouched — see §5 for the
  acknowledged-but-not-acted-on overlap.
- **Part-time availability (net-new).** Add `DayAvailability { weekday, from,
  until }` and `List<DayAvailability> partTimeAvailability`. Rendered only
  when Part-Time is selected; validation blocks completion if Part-Time is
  chosen but no day+times are set.
- **Work experience restructure.** Split `WorkExperience.cityCountry` into
  `country` + `city` (both plain-text). Keep `jobTitle`, `employer`,
  `fromDate`, `toDate`, `children`, `duties`, `reasonLeaving`. Legacy
  `cityCountry` migrates into `city` at codec read time.
- **Emergency contact removed** end-to-end (4 fields): model, codec,
  controller, both screens, and its validation + tests.
- **Languages canonical list** converges to one source:
  `NannyConstants.languages` (updated to the 12 + Other list). Onboarding
  already reads it; edit-profile's hardcoded list is replaced to read it too.

New module boundary: one net-new UI helper is added **inline** in
`nanny_info_screen.dart` (the employment-type + part-time-availability
sections). No new standalone widget file is justified — the existing
`KafiSection` / `KafiChip` / `KafiToggleTile` / `showTimePicker` primitives
cover it. `EmirateX.label`, `EmploymentType`, and `DayAvailability` live in
`nanny_model.dart` alongside the existing enums/classes (matches the file's
convention of co-locating small enums + value classes).

## 2. Reuse map (design system + utilities — do NOT invent new primitives)

Verified fresh against the actual widget files (unchanged from first pass):

- **Section shell:** `KafiSection` (`kafi_section.dart`) —
  `{title, children, accent: KafiSectionAccent, icon}` — use
  `accent: KafiSectionAccent.purple` for work-related sections (matches
  `_workLocation`/`_workPrefs`).
- **Multi-select chips:** `KafiChip` (`kafi_chip_wrap.dart`) —
  `{label, selected, onTap, purple}` — used for Languages and for the
  Mon–Sun day multi-select and the "Any Emirate" toggle. `purple: true` for
  work-context chips, rose default for languages (matches `_basic()` today).
- **Emirate grid boxes:** reuse the exact existing `_emirateBox(...)` pattern
  in `nanny_info_screen.dart` (rounded box, emoji + name + subtitle, purple
  selected state). Add a single-select sibling for current-emirate using the
  identical styling (see §3.5).
- **Employment-type tiles:** `KafiToggleTile` (`kafi_chip_wrap.dart`) —
  `{label, selected, onTap, icon, purple, subtitle, compact}` — multi-select
  tile with a check-circle, `purple: true`. (Not `KafiToggleBox` — that widget
  is a paired A/B single-choice box, the wrong shape for a 3-way multi-select.)
- **Text fields:** `KafiTextField` (onboarding) / `KafiInput` (edit-profile) —
  reuse per each screen's existing convention. Country/City in the exp card
  both use `KafiTextField`, exactly like the field it replaces.
- **Time picker:** Flutter `showTimePicker` (same idiom as the existing
  `showDatePicker` helpers in these screens); format to `"HH:mm"` for storage.
- **Colors/typography:** `KafiTheme.nunito(...)`, `KafiColors.tm/td/ts/pur/
  purL/purB` etc. — never hardcode new hex. Field labels use the existing
  `KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)` style.
- **Strings:** all user-facing text via `AppStrings.*` keys (`.tr`), added to
  both `locales/en_us.dart` and `locales/ar_ae.dart`.
- **Enum labels:** new `EmirateX.label` extension is the single source for
  emirate display names, reused by both emirate grids.

## 3. File-by-file change list

All paths under `kafi_app/`. Touch in the order listed in §4.

### 3.1 `lib/models/nanny_model.dart` — MODIFY (foundation)

- **`Emirate` enum (line 6):** remove `alAin`. Final:
  `enum Emirate { dubai, abuDhabi, sharjah, ajman, rak, fujairah, uaq }`.
- **Add extension** immediately after the enum:
  ```dart
  extension EmirateX on Emirate {
    String get label => switch (this) {
      Emirate.dubai => 'Dubai',
      Emirate.abuDhabi => 'Abu Dhabi',
      Emirate.sharjah => 'Sharjah',
      Emirate.ajman => 'Ajman',
      Emirate.rak => 'Ras Al Khaimah',
      Emirate.fujairah => 'Fujairah',
      Emirate.uaq => 'Umm Al Quwain',
    };
  }
  ```
- **Add `EmploymentType` enum** near `JobTypePreference` (line 19–20):
  `enum EmploymentType { fullTimeLiveIn, fullTimeLiveOut, partTime }`.
- **Add `DayAvailability` value class** near `WorkExperience`/
  `ReferenceContact` (after line 62). `weekday` is 1–7 (matches
  `DateTime.weekday`, Mon=1…Sun=7); `from`/`until` are `"HH:mm"` 24h strings:
  ```dart
  class DayAvailability {
    DayAvailability({required this.weekday, required this.from, required this.until});
    final int weekday;
    final String from;
    final String until;
    DayAvailability copyWith({int? weekday, String? from, String? until}) =>
      DayAvailability(weekday: weekday ?? this.weekday, from: from ?? this.from, until: until ?? this.until);
    Map<String, dynamic> toMap() => {'weekday': weekday, 'from': from, 'until': until};
  }
  ```
- **`WorkExperience` (lines 22–62):**
  - Replace the single `cityCountry` field with two required fields `country`
    and `city` (both `String`). Constructor param order: `...employer,
    country, city, fromDate...`.
  - **Remove `location` entirely**: constructor param `this.location,` (line
    33), field + doc comment (lines 46–48), `toMap`'s conditional entry
    (line 60). Per §1.4.
  - `toMap()`: write `'country'` and `'city'`, remove `'cityCountry'` and
    `'location'`.
- **`ReferenceContact` (lines 64–92): NO CHANGE.** Its own `location` field
  stays untouched — confirmed out of scope (§0).
- **`NannyModel`:**
  - **Remove `currentLocation`**: constructor param `this.currentLocation,`
    (line 199), doc comment + field (lines 267–269), `copyWith` param (423) +
    body (490), `toMap` conditional (559). Per §1.4. Do **not** remove the
    `geo_location.dart` import (line 1) — `ReferenceContact.location` still
    needs it.
  - **Remove all 4 emergency fields**: `emergencyName`,
    `emergencyRelationship`, `emergencyCountryCode`, `emergencyPhone` — from
    the constructor (lines 225–228), field declarations (295–298), `copyWith`
    params (449–452) + body (516–519), `toMap` (585–588).
  - **Add** `final Emirate? currentEmirate;` (constructor `this.currentEmirate,`
    default null), placed next to `currentArea` (line 265), with a doc
    comment: `/// Canonical current-location value. [currentArea] is kept in
    sync as a denormalized display label for out-of-scope readers
    (dashboard, browse cards, admin panel) — see plan §1.3.`
  - **Add** `final List<EmploymentType> employmentTypes;` (constructor
    `this.employmentTypes = const [],`).
  - **Add** `final List<DayAvailability> partTimeAvailability;` (constructor
    `this.partTimeAvailability = const [],`).
  - `copyWith`: add `Emirate? currentEmirate`, `List<EmploymentType>?
    employmentTypes`, `List<DayAvailability>? partTimeAvailability` params +
    `?? this.` body lines (same convention as every other field here).
  - `toMap`: add `'currentEmirate': currentEmirate?.name`,
    `'employmentTypes': employmentTypes.map((e) => e.name).toList()`,
    `'partTimeAvailability': partTimeAvailability.map((d) => d.toMap()).toList()`.
    Keep `'currentArea': currentArea` (line 558) unchanged.
  - **`hasPersonalInfo` (lines 363–370): NO CHANGE.** See §1.2 for the
    explicit reasoning.

### 3.2 `lib/models/nanny_map_codec.dart` — MODIFY

- **Add helper** (Al Ain remap, single point of truth for reading an emirate):
  ```dart
  Emirate? _emirateByName(dynamic raw) {
    if (raw == null) return null;
    var name = raw.toString();
    if (name == 'alAin') name = 'abuDhabi'; // 8→7 remap (Al Ain ⊂ Abu Dhabi)
    return _enumByName(Emirate.values, name);
  }
  ```
- **`workEmirates` parse (lines 81–85):** map through `_emirateByName`, then
  de-duplicate (remap can collide `abuDhabi` + `alAin` in one legacy doc):
  `.map(_emirateByName).whereType<Emirate>().toSet().toList()`.
- **Add** `currentEmirate: _emirateByName(m['currentEmirate']),` in
  `nannyModelFromMap` (near the existing `currentArea:` line, 87). No legacy
  fallback from free-text `currentArea` — it isn't a reliable emirate name.
- **Add** `employmentTypes` parse:
  `(m['employmentTypes'] as List?)?.map((e) => _enumByName(EmploymentType.values, e)).whereType<EmploymentType>().toList() ?? const []`.
- **Add** `partTimeAvailability` parse via a new `_dayAvailabilityFromMap`
  (mirrors `_referenceFromMap`'s pattern):
  ```dart
  DayAvailability _dayAvailabilityFromMap(Map<String, dynamic> m) => DayAvailability(
    weekday: (m['weekday'] as num?)?.toInt() ?? 1,
    from: m['from']?.toString() ?? '',
    until: m['until']?.toString() ?? '',
  );
  ```
  then `partTimeAvailability: (m['partTimeAvailability'] as List?)?.map((e) => _dayAvailabilityFromMap(Map<String, dynamic>.from(e as Map))).toList() ?? const [],`.
- **`_experienceFromMap` (lines 27–38):**
  - Replace `cityCountry: m['cityCountry']?.toString() ?? '',` with
    `country: m['country']?.toString() ?? '',` and
    `city: m['city']?.toString() ?? m['cityCountry']?.toString() ?? '',`
    (legacy `cityCountry` folds into `city`, preserving old data).
  - **Remove** `location: _geoFromMap(m['location']),` (line 37). Per §1.4.
- **`nannyModelFromMap`:** **remove** the `currentLocation:
  _geoFromMap(m['currentLocation']),` line (88) and the 4 emergency-field
  reads (116–119).
- **Keep unchanged**: `_geoFromMap` helper (lines 8–9), the `geo_location.dart`
  import (line 2), and `_referenceFromMap`'s `location: _geoFromMap(m['location'])`
  (line 46) — all still required by `ReferenceContact`, out of scope.

### 3.3 `lib/utils/constants/nanny_constants.dart` — MODIFY

- Replace `languages` (lines 51–54) with the canonical list **verbatim** from
  the scope doc (12 + Other), preserving order:
  ```dart
  static const languages = [
    'English', 'Arabic', 'Filipino/Tagalog', 'Bahasa Indonesia', 'Hindi', 'Urdu',
    'Bengali', 'Amharic', 'Oromo', 'Swahili', 'Punjabi', 'Malayalam', 'Other',
  ];
  ```
- Leave `nationalities`, `jobTitles`, `reasonsLeaving`, `referenceRelations`,
  `totalSteps` (stays **6** — see §3.5 for why no new step is added)
  unchanged.

### 3.4 `lib/controllers/nanny_profile_controller.dart` — MODIFY

- **Remove import** `geo_location.dart` (line 14) — its only use
  (`currentLocationPicked`) is deleted below.
- **Remove** `currentAreaCtrl` (line 72) and its `.dispose()` (line 174).
  **Add** `final Rx<Emirate?> currentEmirate = Rx<Emirate?>(null);` in the
  step-1 block.
- **Remove** `GeoLocation? currentLocationPicked;` (line 74) — nothing will
  ever populate it once §3.5/§3.6 remove its writers. Per §1.4.
- **Remove** `emergencyNameCtrl`, `emergencyRelCtrl`, `emergencyPhoneCtrl`
  (lines 94–96) and `emergencyCountryCode` (the `RxString`, line 97 — this is
  the 4th field the first pass missed) and the three controllers' `.dispose()`s
  (lines 183–185; `emergencyCountryCode` is an `Rx`, not a
  `TextEditingController`, so it has no `.dispose()` call to remove).
- **Add** step-1 state:
  `final RxList<EmploymentType> employmentTypes = <EmploymentType>[].obs;`
  `final RxList<DayAvailability> partTimeAvailability = <DayAvailability>[].obs;`
- **Add methods:**
  - `void toggleEmploymentType(EmploymentType t)` — add/remove; when removing
    `partTime`, also `partTimeAvailability.clear()` (part-time UI + data
    disappear together).
  - `void toggleDay(int weekday)` — if a `DayAvailability` with that weekday
    exists, remove it; else add `DayAvailability(weekday: weekday, from: '',
    until: '')`.
  - `void setDayFrom(int weekday, String v)` / `setDayUntil(int weekday,
    String v)` — replace the matching entry via `copyWith`, reassigning the
    `RxList` so `Obx` fires.
  - `void toggleAnyEmirate()` — `if (workEmirates.length ==
    Emirate.values.length) workEmirates.clear(); else
    workEmirates.assignAll(Emirate.values);`
  - `bool get allEmiratesSelected => Emirate.values.every(workEmirates.contains);`
- **`_hydrate` (lines 290–349):**
  - Replace `currentAreaCtrl.text = n.currentArea;` (308) +
    `currentLocationPicked = n.currentLocation;` (309) with
    `currentEmirate.value = n.currentEmirate;`.
  - Add `employmentTypes.assignAll(n.employmentTypes);`
    `partTimeAvailability.assignAll(n.partTimeAvailability);`.
  - Remove the 4 emergency `.text =`/`.value =` lines (333–337, including the
    `emergencyCountryCode.value = ...` fallback-to-`'+971'` line).
- **`validatePersonalInfo` (lines 415–446):**
  - Replace the current-area check (425:
    `if (currentAreaCtrl.text.trim().isEmpty) return
    AppStrings.nannyCurrentAreaRequired;`) with
    `if (currentEmirate.value == null) return
    AppStrings.nannyCurrentAreaRequired;` (reuse the existing key — no l10n
    churn needed, the message text is still appropriate).
  - **Remove** the 3 emergency checks (439–443: name, relationship, phone —
    `emergencyCountryCode` was never separately validated, it always carries a
    default, so there is no 4th check to remove here).
  - **Add**, after the children-count check (438) and before the bio check
    (444):
    - `if (employmentTypes.isEmpty) return AppStrings.nannyEmploymentTypeRequired;`
    - Part-time gate:
      ```dart
      if (employmentTypes.contains(EmploymentType.partTime)) {
        final ok = partTimeAvailability.isNotEmpty &&
          partTimeAvailability.every((d) => d.from.isNotEmpty && d.until.isNotEmpty);
        if (!ok) return AppStrings.nannyPartTimeAvailabilityRequired;
      }
      ```
- **`savePersonalInfoAndNext` copyWith (lines 460–496):**
  - Replace `currentArea: currentAreaCtrl.text.trim(),` (470) +
    `currentLocation: currentLocationPicked,` (471) with
    `currentEmirate: currentEmirate.value,` `currentArea:
    currentEmirate.value?.label ?? '',` (populates the display mirror, §1.3).
  - Add `employmentTypes: List.of(employmentTypes),`
    `partTimeAvailability: List.of(partTimeAvailability),`.
  - **Remove** the 4 emergency copyWith args (491–494).
- **`saveProfileDraft` (lines 372–404):** remove the `currentArea:
  currentAreaCtrl.text.trim(),` (382) and `currentLocation:
  currentLocationPicked,` (383) lines, and the 4 emergency args (388–391).
  Edit-profile screen edits neither location nor emergency, so dropping these
  is correct and avoids clobbering a legacy nanny's `currentArea` with an
  empty string. Leave the `workEmirates` line and the method's `Future<bool>`
  return contract unchanged.
- **No change needed** to the hire/trial service dependencies, `activeHire`/
  `activeTrial`, `loadEmploymentStatus`, or `_onboardingRoutes` — unrelated to
  this plan's fields, confirmed by fresh read.

### 3.5 `lib/views/nanny/nanny_info_screen.dart` — MODIFY

- **Remove imports**: `kafi_location_picker.dart` (line 12), `auth_constants.dart`
  (line 7), `kafi_phone_input.dart` (line 11). Confirmed by grep that
  `AuthConstants` and `KafiPhoneInput` are each used **only** inside
  `_emergency()`/`_emergencyCodeOptions`, both removed below, so both imports
  become dead. `KafiLocationPicker`'s only use is the one call removed below.
  Keep `kafi_chip_wrap.dart` (line 10, still used for languages + new chips)
  and `kafi_searchable_picker.dart` (line 14, used for nationality, untouched).
- **Remove** the `_emergencyCodeOptions` static field (lines 23–29) — its only
  consumer is `_emergency()`, removed below.
- **`build()` children list (lines 47–58):** remove `_emergency(),`; insert
  `_employment(),` right after `_workPrefs(),`. New order: `_basic(), _visa(),
  _workLocation(), _workPrefs(), _employment(), _personal(), _health(),
  _comfort(), _religion(), _bio()`.
- **Why a new section, not a new onboarding step** (confirmed by grepping
  every nanny screen's `KafiStepScaffold(step: N, ...)`): `nanny_info_screen
  .dart` is step 1, `nanny_media_screen.dart` step 2, `nanny_exp_screen.dart`
  step 3, `nanny_refs_screen.dart` step 4, `nanny_docs_screen.dart` step 5.
  Inserting a new onboarding step would require renumbering every one of
  these, including `nanny_refs_screen.dart` — explicitly out of scope per the
  epic doc. Adding `_employment()` as a new section inside the existing step-1
  screen needs no renumbering and keeps `NannyConstants.totalSteps = 6`
  untouched.
- **`_workLocation()` (lines 320–384):** rework into four blocks inside the
  same `KafiSection` (title `secWorkLoc`, purple accent), in this order —
  current location first (matches the requirements doc's own ordering), then
  preferred job locations, then relocate:
  1. **Current emirate (single-select), net-new UI:** a label
     (`AppStrings.nannyCurrentEmirateLabel.tr`) + a 2-col `GridView.count`
     (same `childAspectRatio: 2.2` as the existing grid) of a new
     `_currentEmirateBox(...)` over `Emirate.values` (7 boxes), wrapped in
     `Obx`. Selected when `controller.currentEmirate.value == value`; tap
     sets `controller.currentEmirate.value = value`.
  2. **Preferred job location (multi-select):** keep the info banner + the
     `fldEmirates` label + the existing `workEmirates` grid, but delete the Al
     Ain box (line 350) → 7 boxes. Add an "Any Emirate" `KafiChip` (`purple:
     true`) above the grid: `selected: controller.allEmiratesSelected,
     onTap: controller.toggleAnyEmirate`.
  3. **Relocate toggle:** keep the existing `willingRelocate` `KafiToggleBox`
     row (lines 354–373) unchanged.
  4. **Delete** the `KafiLocationPicker(...)` block (lines 375–381) entirely.
  - To avoid re-introducing an Al Ain-style drift (two independently
    hand-maintained emoji/subtitle lists that can fall out of sync with the
    enum), define one private list of `(Emirate, emoji, subtitle)` records at
    the top of the class and drive **both** grids from it, with names sourced
    from `EmirateX.label`.
- **Add `_currentEmirateBox(String emoji, String name, Emirate value, bool
  selected)`** — copies the existing `_emirateBox` styling; `onTap` sets the
  single `currentEmirate`.
- **Add `_employment()`** — a `KafiSection(title: nannySecEmployment, icon:
  Icons.work_outline, accent: purple)` containing:
  1. Label `nannyEmploymentQuestion` + an `Obx`-wrapped `Column` of three
     `KafiToggleTile` (`purple: true`): Full-Time Live-In / Full-Time
     Live-Out / Part-Time. `selected: controller.employmentTypes.contains
     (type)`, `onTap: () => controller.toggleEmploymentType(type)`.
  2. Conditional part-time block: `Obx(() =>
     employmentTypes.contains(partTime) ? _partTimeAvailability() :
     const SizedBox.shrink())`.
- **Add `_partTimeAvailability()`** — label `nannyPartTimeQuestion` + a `Wrap`
  of 7 `KafiChip` (`purple: true`) for Mon–Sun (`AppStrings.dayMon`…`daySun`),
  selected when a `DayAvailability` for that weekday exists, `onTap: () =>
  controller.toggleDay(weekday)`. Below, an `Obx` rendering, for each selected
  day (sorted by weekday): the day name + two tappable
  `AbsorbPointer`/`GestureDetector` time fields (from/until) using
  `showTimePicker` → `controller.setDayFrom/setDayUntil(weekday, "HH:mm")`,
  showing the value or an em-dash placeholder. Reuse the existing
  `_dateField`-style container idiom from `nanny_exp_screen.dart` for visual
  consistency. A selected day with an unset time shows the placeholder and is
  exactly what the validator (§3.4) blocks on.
- **Remove `_emergency()` (lines 614–654) and `_relValue()` (lines 656–660)**
  entirely.
- `_bio()` (unchanged) stays last.

### 3.6 `lib/views/nanny/nanny_exp_screen.dart` — MODIFY

Corrected section — the first pass wrongly claimed this screen had no GPS
picker. It does (§0(e)), and removing it is required by the scope doc's
literal "no maps/GPS/pins/exact-address" requirement for work-experience city.

- **Remove imports**: `geo_location.dart` (line 5) and `kafi_location_picker
  .dart` (line 9) — both become fully unused once the changes below land.
- **`_addBtn` default `WorkExperience` (lines 85–94):** replace `cityCountry:
  ''` with `country: '', city: '',`. (No `location:` arg — that param no
  longer exists per §1.4/§3.1.)
- **`_ExpCard` state (class starting line 136):**
  - Rename the field the city text lives in and add a country field:
    `late final TextEditingController _country;` alongside the existing
    `late final TextEditingController _city;`.
  - **Delete** `GeoLocation? _cityLocation;` (line 145) and its seed
    `_cityLocation = e.location;` (line 151) entirely.
  - `initState` (148–163): seed `_country = TextEditingController(text:
    e.country);` and `_city = TextEditingController(text: e.city);` (was
    `text: e.cityCountry`). Add `_country` to the listener loop (`for (final c
    in [_employer, _country, _city, _children, _duties]) { c.addListener
    (_emit); }`) and to `dispose()`'s loop (line 181).
- **`_emit()` (lines 165–178):** build `WorkExperience(..., country:
  _country.text, city: _city.text, ...)` — drop `cityCountry:` and
  `location: _cityLocation,`.
- **`build()` (around lines 274–288):** replace the single
  `_label(AppStrings.expCityCountry.tr)` + `KafiLocationPicker(...)` block
  with two plain fields, no picker, no callback:
  ```dart
  KafiTextField(label: AppStrings.expCountry.tr, controller: _country, hint: 'e.g. Philippines'),
  KafiTextField(label: AppStrings.expCity.tr, controller: _city, hint: 'e.g. Dubai'),
  ```
  Keep Job role dropdown, dates, children, duties, reason exactly as they are
  — none of them touch location.

### 3.7 `lib/views/nanny/nanny_edit_profile_screen.dart` — MODIFY

Confirmed by fresh read to be essentially unchanged from the first pass (the
only drift was `saveProfileDraft` now returning `Future<bool>` with an
already-wired `if (!ok) return;` guard in the Save button — not something this
plan needs to touch).

- **Add import** `kafi_chip_wrap.dart` and `nanny_constants.dart`.
- **Languages section (lines 37–79):** replace the hardcoded 6-item list
  (`['English','Arabic','French','Hindi','Tagalog','Amharic']`) and its
  bespoke `GestureDetector` chip with an `Obx`-wrapped `Wrap` of `KafiChip`
  over `NannyConstants.languages`, `selected: ctrl.selectedLanguages.contains
  (l)`, `onTap: () => ctrl.toggleLanguage(l)` (reuse the controller's existing
  `toggleLanguage`). This converges the third language list to the single
  canonical source (§1.5).
- **Remove the entire Emergency Contact `_section(...)` block (lines 81–102)**
  — all three `KafiInput`s (name/relationship/phone; there is no
  country-code UI on this screen today, confirmed by fresh read, so no 4th
  widget to remove here).
- No change to `_toggleRow`, the comfort section, or the Save button flow
  (128–142, already handles the boolean return).
- Update the class doc comment (lines 10–12) to drop "emergency contact" from
  the list of editable fields.

### 3.8 l10n — MODIFY `lib/l10n/app_strings.dart` + `locales/en_us.dart` + `locales/ar_ae.dart`

Add these keys (constant in `app_strings.dart`, value in **both** locale maps
— Arabic translated, not an English placeholder):

| Key const | value id | EN string |
| --- | --- | --- |
| `nannyCurrentEmirateLabel` | `nanny_current_emirate_label` | "Which emirate do you currently live in?" |
| `nannyAnyEmirate` | `nanny_any_emirate` | "Any Emirate" |
| `nannySecEmployment` | `nanny_sec_employment` | "Employment Type" |
| `nannyEmploymentQuestion` | `nanny_employment_question` | "What type of job are you looking for?" |
| `nannyEmpFullLiveIn` | `nanny_emp_full_live_in` | "Full-Time — Live-In" |
| `nannyEmpFullLiveOut` | `nanny_emp_full_live_out` | "Full-Time — Live-Out" |
| `nannyEmpPartTime` | `nanny_emp_part_time` | "Part-Time" |
| `nannyEmploymentTypeRequired` | `nanny_employment_type_required` | "Please select at least one job type" |
| `nannyPartTimeQuestion` | `nanny_part_time_question` | "Which days are you available?" |
| `nannyPartTimeFrom` | `nanny_part_time_from` | "Available from" |
| `nannyPartTimeUntil` | `nanny_part_time_until` | "Available until" |
| `nannyPartTimeAvailabilityRequired` | `nanny_part_time_availability_required` | "Add at least one available day with from and until times" |
| `dayMon`…`daySun` | `day_mon`…`day_sun` | "Mon","Tue","Wed","Thu","Fri","Sat","Sun" |
| `expCountry` | `exp_country` | "Country" |
| `expCity` | `exp_city` | "City or location" |

Confirmed to already exist (verified via grep of `app_strings.dart`, no
churn needed) — reused as-is: `nannyCurrentAreaRequired` (line 962, current-
emirate required message), `fldEmirates` (154), `secWorkLoc` (138),
`fldRelocate` (155), `secBio` (144), `fldBio` (172), `nannySecWorkPrefs` (950),
`fldJobType` (479).

**Do not delete** the now-unused emergency/location keys (`secEmergency`,
`fldEmergencyName/Rel/Phone`, `nannyEmergency*Required`,
`editEmergencyContact`, `fldCurrentArea`, `expCityCountry`) — leaving orphaned
string-key constants is harmless and avoids touching unrelated call sites.
Flag as dead for an optional later sweep.

### 3.9 `test/onboarding/onboarding_validation_test.dart` — MODIFY

Fresh read confirms `bindNanny()` already registers `MockHireService` and
`MockTrialService` (needed because the controller resolves `IHireService`/
`ITrialService` in field initializers) — nothing to add there, just noting it
so the developer doesn't think it needs wiring.

- `_fillValidPersonalInfo` (lines 286–303): replace `c.currentAreaCtrl.text =
  'Dubai Marina';` with `c.currentEmirate.value = Emirate.dubai;`; **remove**
  the 3 emergency-controller fills (name/rel/phone — `emergencyCountryCode`
  was never filled here, it's an Rx with a default); **add**
  `c.employmentTypes.assignAll([EmploymentType.fullTimeLiveIn]);` so the base
  "passes" case stays valid under the new required-employment rule.
- Test "empty current area is rejected" (lines 105–108): change body to
  `c.currentEmirate.value = null;`, keep `expect(...,
  AppStrings.nannyCurrentAreaRequired)`.
- **Remove** the 3 emergency tests (lines 132–143).
- **Add** three tests:
  - `no employment type is rejected` → `c.employmentTypes.clear();` expect
    `nannyEmploymentTypeRequired`.
  - `part-time with no availability is rejected` →
    `c.employmentTypes.assignAll([EmploymentType.partTime]);` (leave
    `partTimeAvailability` empty) expect `nannyPartTimeAvailabilityRequired`.
  - `part-time with a day and times passes` → add a `DayAvailability
    (weekday: 1, from: '08:00', until: '17:00')` to `partTimeAvailability`,
    keep `employmentTypes = [partTime]`, expect `isNull`.

### 3.10 `test/services/match_service_test.dart` — MODIFY (compile-fix only)

Fresh read confirms this file was restructured since the scope doc's
investigation (now uses `totalExperienceYears`, `cardWithJobMatch`/
`rankNannies`, many more dimension groups) — none of that affects this plan.
The only touch point is the `exp(int years)` fixture helper (now at lines
112–122), which constructs `WorkExperience(..., cityCountry: 'Dubai', ...)`.
Replace with `country: 'UAE', city: 'Dubai',`. No other change — this does
**not** touch `match_service.dart` itself (confirmed: `_locationScore` (line
60) compares `nanny.workEmirates` `.name` values against `job.city`, unaffected
by the enum shrinking from 8 to 7; `_skillsScore` reads only
`WorkExperience.jobTitle`/`.children`, neither of which this plan changes).

## 4. Work units & parallelization

- **WU-1 — Model + codec + constants** (`nanny_model.dart`,
  `nanny_map_codec.dart`, `nanny_constants.dart`). **SEQUENTIAL, foundation.**
  Everything depends on it. Build first.
- **WU-2 — l10n** (`app_strings.dart`, `en_us.dart`, `ar_ae.dart`).
  **INDEPENDENT** (no file overlap with any other unit). Can run in parallel
  with WU-1. Land before/with WU-3/WU-4, which reference these keys.
- **WU-3 — Controller + onboarding screen + edit screen**
  (`nanny_profile_controller.dart`, `nanny_info_screen.dart`,
  `nanny_edit_profile_screen.dart`). **SEQUENTIAL after WU-1 & WU-2.** These
  three share controller contracts, so one developer owns them as a set.
- **WU-4 — Experience screen** (`nanny_exp_screen.dart`). **INDEPENDENT** of
  WU-3 (only shares the `WorkExperience` shape from WU-1). Can run in
  parallel with WU-3 once WU-1 lands.
- **WU-5 — Tests** (`onboarding_validation_test.dart`,
  `match_service_test.dart`). **SEQUENTIAL, last** — depends on all of the
  above; run `flutter analyze` + `flutter test`.

Parallel-safe pairs: WU-2 ∥ WU-1; WU-4 ∥ WU-3 (after WU-1). No two units write
the same file.

## 5. Refactor callouts / design notes (no separate refactor needed)

The affected code is sound and idiomatic (clean controller/screen/codec
separation, consistent design-system usage) — **no pre-work refactor
required.** Three contained improvements are folded into the change itself:

1. **Emirate label single-source.** The hardcoded 8-box grid (with the Al Ain
   bug) is replaced by iterating `Emirate.values` + `EmirateX.label`, so the
   emirate set can never drift out of sync with the enum again.
2. **Language list single-source.** Three lists converge to
   `NannyConstants.languages`.
3. **Dead GeoLocation fields removed** instead of left inert (§1.4), which is
   a small net code-reduction, not an add.

Noted, **not acted on** (out of scope): `employmentTypes` (new) conceptually
overlaps `jobTypePreference` (live-in/out/both), which `match_service
._jobTypeScore` consumes. Consolidating them would require editing
`match_service.dart` (out of scope + a cross-phase collision zone — the family
phase's scope doc also touches nanny↔job matching per the epic doc). Left as
an additive parallel field; flag for a future matching-alignment task if the
client wants employment type to influence scoring.

## 6. Test plan

Automated (must pass):
- `flutter analyze` — zero new issues (enum removal, field renames/removals,
  removed emergency/GeoLocation refs all resolved, no dangling imports — see
  the explicit import-removal lists in §3.5/§3.6).
- `flutter test test/onboarding/onboarding_validation_test.dart` — updated + 3
  new cases green.
- `flutter test test/services/match_service_test.dart` — green after the
  `exp()` helper fix.

Manual/review flows to exercise:
1. Fresh nanny onboarding Step 1: pick current emirate (single), preferred
   emirates (multi + "Any Emirate" selects all 7 and reflects as selected),
   select employment types; select Part-Time → day multi-select + per-day
   from/until appear; a Part-Time selection with no day (or a day with a
   missing time) blocks Next with the localized message; filling one
   day+times unblocks. No Al Ain anywhere. No map/GPS picker anywhere on the
   screen.
2. Work-experience add: Country + City are separate plain-text fields, no
   picker; save + reload round-trips both.
3. Emergency section absent in both onboarding Step 1 and edit-profile; Bio
   present and functional; removing it does not block Step 1 completion for
   an otherwise-valid profile.
4. Edit-profile languages show the 12 + Other list (`KafiChip`), toggle
   persists.
5. Codec remap: a nanny doc with `workEmirates: ['alAin','dubai']` and
   `currentEmirate: 'alAin'` loads as `[abuDhabi, dubai]` (de-duped) and
   `currentEmirate == abuDhabi`; a legacy experience with only `cityCountry`
   shows its text in the City field.
6. A pre-existing **draft** nanny doc (old shape: has `currentArea` text, no
   `currentEmirate`, no `employmentTypes`) still resumes at Step 2 (media),
   not bounced back to Step 1 — confirms the §1.2 `hasPersonalInfo` decision.
7. `NannyCardModel.fromNanny` / the nanny dashboard still show a sensible
   area string after a fresh Step 1 save (confirms the §1.3 mirror).

## 7. Definition of done (buildable, gradable checklist)

- [ ] `Emirate` enum has exactly 7 values (no `alAin`); both emirate grids
      render the same 7 from `Emirate.values` + `EmirateX.label`.
- [ ] Codec `_emirateByName` remaps `'alAin' → 'abuDhabi'` on read for
      `workEmirates` (de-duped) and `currentEmirate`.
- [ ] `NannyConstants.languages` is the canonical 12 + Other list, verbatim;
      both onboarding `_basic()` and edit-profile read it; no other hardcoded
      nanny language list remains.
- [ ] Current location is a single-select of the 7 emirates writing
      `currentEmirate` (+ `currentArea` label mirror); `NannyModel
      .currentLocation` and `WorkExperience.location` are removed from the
      model/codec/controller/screens; `ReferenceContact.location` is
      untouched; the `KafiLocationPicker` call sites in both
      `nanny_info_screen.dart` and `nanny_exp_screen.dart` are removed and
      their now-unused imports (`kafi_location_picker.dart`,
      `geo_location.dart`, `auth_constants.dart`, `kafi_phone_input.dart`
      where applicable) are removed too; no GPS/Places call is reachable from
      the current-location or work-experience-city fields.
- [ ] Preferred job location = 7-emirate multi-select + working "Any Emirate"
      (writes all 7).
- [ ] Employment-type section (Full-Time Live-In / Full-Time Live-Out /
      Part-Time, multi-select) exists, persists, and is required for
      completion (via `validatePersonalInfo`, not via `hasPersonalInfo` —
      §1.2).
- [ ] Part-time availability shows only when Part-Time is selected; each
      selected day has independent from/until; a Part-Time selection with
      zero days or any missing time blocks completion via
      `nannyPartTimeAvailabilityRequired`.
- [ ] Work experience collects Country + City (plain text, no picker) + Job
      role + Start + End + Main responsibilities; legacy `cityCountry`
      migrates into `city`.
- [ ] Emergency Contact (all 4 fields, including `emergencyCountryCode`)
      removed from model, codec, controller, both screens, and its
      validation + tests; `validatePersonalInfo` no longer references any
      emergency field; removing it doesn't break Step-1 completion.
- [ ] `hasPersonalInfo` and `auth_controller.dart` are unmodified and still
      correct (verified by manual flow 6).
- [ ] All new user-facing strings are `AppStrings` keys present in both
      `en_us.dart` and `ar_ae.dart`.
- [ ] `flutter analyze` clean (including no unused-import warnings from the
      removed picker/GeoLocation call sites); onboarding + match_service
      tests updated and passing.

## 8. Scope-boundary confirmation

- **Untouched (out of scope), confirmed by fresh read/grep:**
  `nanny_refs_screen.dart` (its own `KafiLocationPicker` + `ReferenceContact
  .location` stay exactly as-is), `trial_offer_screen.dart`,
  `KafiLocationPicker`/`LocationService`/`PlacesService`/`GeoLocation` class,
  `match_service.dart`, `nanny_card_model.dart`, `nanny_dashboard_screen.dart`,
  everything in `functions/` and `admin-panel/`, family side (phase 2), trial
  flow (phase 3).
- **No cross-phase collision:** this plan does not edit `match_service.dart`,
  `nanny_card_model.dart`, or `nanny_dashboard_screen.dart` — the `currentArea`
  display mirror (§1.3) is precisely what keeps those three readers correct
  without editing them. The family phase's `match_service`/admin work does
  not overlap any file this plan touches.
- **Admin-panel note for the build doc** (now precisely characterized, not a
  guess — see §0's admin-panel grep): the TS `NannyRow` type and its mock/live
  data (`admin-panel/src/services/firestore.ts`) read `cityCountry` on work
  experience and `emergencyName`/`emergencyRelationship`/`emergencyPhone` on
  the nanny doc (no `emergencyCountryCode` field ever existed there). After
  this phase ships, newly-saved nanny docs stop writing all of those, and
  admin's `AllNannies.tsx`/`NannyProfileView.tsx` will show them blank for new
  saves (existing docs keep their old values until re-saved) while not
  displaying the new `currentEmirate`/`employmentTypes`/
  `partTimeAvailability`/experience `country`+`city` fields at all. The `currentArea`
  display/search in `AllNannies.tsx`/`NannyProfileView.tsx` is **not** broken
  — the mirror (§1.3) keeps it populated. Flag the rest in `builds/<slug>.md`
  for a follow-up admin-panel task — do not silently expand scope to fix it
  here.
