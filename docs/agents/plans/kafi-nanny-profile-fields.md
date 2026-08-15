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

## 0. Source-vs-scope reconciliation (read the real code — several scope refs drifted)

I read every affected file. The scope doc's "Current state" line numbers were from
an earlier pass and are stale in ways that change the plan. Confirmed real state:

- **No `currentLocation` (`GeoLocation?`) field exists** on `NannyModel`. Current
  location today is only the plain `String currentArea` (model line 240) fed by a
  `KafiLocationPicker` in the UI. There is no GPS value persisted to drop — the GPS
  is purely a UI-picker concern in `nanny_info_screen.dart:371`.
- **No `WorkExperience.location` (`GeoLocation?`) field exists.** `WorkExperience`
  has a single `cityCountry` String and no geo field. Nothing GPS to drop from the
  model here.
- **`nanny_exp_screen.dart` does NOT use `KafiLocationPicker`.** It already uses a
  plain `KafiTextField` for the combined city/country (line 252). So the only real
  `KafiLocationPicker` call site in scope is `nanny_info_screen.dart:371` (current
  area). `nanny_refs_screen.dart` is the out-of-scope one and is left untouched.
- **No `hasPersonalInfo` getter exists** on `NannyModel`. Onboarding-step
  completion is gated solely by `NannyProfileController.validatePersonalInfo()`
  (controller lines 323–354). That validator is the single place to update for the
  `currentArea → Emirate` change and the new required fields.
- **Emergency fields are three, not four**: `emergencyName`, `emergencyRelationship`,
  `emergencyPhone`. There is **no** `emergencyCountryCode` field (the `+971` picker
  in the UI is cosmetic and unbound). Nothing to remove for a country-code field.

Everything below is planned against the real code.

## 1. Architecture summary

The nanny onboarding is a GetX flow: one controller (`NannyProfileController`)
holds all form state as `Rx*`/`TextEditingController`s, screens are `GetView`s that
`Obx`-bind to it, and persistence goes model → `toMap()` → `IUserService.saveNanny`,
read back via `nannyModelFromMap` in `nanny_map_codec.dart`. This plan stays entirely
within that pattern — no new state-management or data-layer concepts.

Data-flow changes:

1. **Emirate 8→7 + Al Ain remap.** Drop `Emirate.alAin` from the enum. Because a
   dropped enum value would make `_enumByName` return `null` for legacy
   `'alAin'` strings, the remap is done **at codec read time**: a dedicated
   `_emirateByName` helper normalizes the raw string `'alAin' → 'abuDhabi'`
   *before* enum lookup, applied to **both** `workEmirates` and the new
   `currentEmirate`. This is exercised on every profile load, so any existing doc
   holding `alAin` reads back as `abuDhabi` (acceptance criterion met without a
   migration script). `workEmirates` is de-duplicated after remap.
2. **Current location: typed emirate, single-select.** Add `Emirate? currentEmirate`
   (canonical, typed) to the model. Keep the existing `String currentArea` field as
   a **denormalized display mirror** (populated from the selected emirate's label)
   so the two out-of-scope readers of `currentArea`
   (`nanny_dashboard_screen.dart:79`, `firestore_job_service.dart:37`) keep working
   with a clean human label and need no edits — avoiding cross-phase file collisions.
   This is a deliberate, documented denormalization, not accidental duplication.
   Controller state becomes `Rx<Emirate?> currentEmirate` (replacing
   `currentAreaCtrl`). The `KafiLocationPicker`/GPS call site is removed.
3. **Preferred job location.** Reuse the existing `workEmirates` (`List<Emirate>`)
   grid; drop the Al Ain box (7 boxes) and add an "Any Emirate" affordance that
   writes all 7.
4. **Employment type (net-new).** Add `EmploymentType { fullTimeLiveIn,
   fullTimeLiveOut, partTime }` and `List<EmploymentType> employmentTypes`
   (multi-select, additive). `jobTypePreference` is **untouched** (it feeds
   `match_service.dart`, which is out of scope) — the conceptual overlap is noted in
   §5, not acted on.
5. **Part-time availability (net-new).** Add `DayAvailability { weekday, from, until }`
   and `List<DayAvailability> partTimeAvailability`. Rendered only when Part-Time is
   selected; validation blocks completion if Part-Time is chosen but no day+times set.
6. **Work experience restructure.** Split `WorkExperience.cityCountry` into
   `country` + `city` (both plain-text). Keep `jobTitle`, `employer`, `fromDate`,
   `toDate`, `children`, `duties`, `reasonLeaving`. Legacy `cityCountry` migrates into
   `city` at codec read time.
7. **Emergency contact removed** end-to-end: model fields, codec, controller,
   both screens, and its validation + tests.
8. **Languages canonical list** converges to one source: `NannyConstants.languages`
   (updated to the 12 + Other list). Onboarding already reads it; edit-profile's
   hardcoded list is replaced to read it too.

New module boundary: one net-new UI helper is added **inline** in
`nanny_info_screen.dart` (the employment-type + part-time-availability sections). No
new standalone widget file is justified — the existing `KafiSection` / `KafiChip` /
`KafiToggleBox` / `showTimePicker` primitives cover it. `EmploymentType`,
`DayAvailability`, and the `EmirateX.label` extension live in `nanny_model.dart`
alongside the existing enums/classes (matches the file's current convention of
co-locating small enums + value classes).

## 2. Reuse map (design system + utilities — do NOT invent new primitives)

- **Section shell:** `KafiSection` (`kafi_section.dart`) with
  `accent: KafiSectionAccent.purple` for work-related sections (matches
  `_workLocation`/`_workPrefs`).
- **Multi-select chips:** `KafiChip` (`kafi_chip_wrap.dart`) — used for Languages and
  for the day multi-select (Mon–Sun) and "Any Emirate" toggle. Use `purple: true`
  for work-context chips (matches the section accent), rose default for languages
  (matches `_basic()` today).
- **Emirate grid boxes:** reuse the exact existing `_emirateBox(...)` pattern in
  `nanny_info_screen.dart` (rounded box, emoji + name + subtitle, purple selected
  state via `KafiColors.purL/pur/inputBgP/purB`). Add a single-select sibling
  `_currentEmirateBox(...)` using the identical styling.
- **Employment-type tiles:** reuse `KafiToggleTile` (`kafi_chip_wrap.dart`,
  `purple: true`) — it already renders a check-circle + label + optional subtitle and
  is the established multi-select-tile primitive. (Do not use `KafiToggleBox`, which
  is a single-choice A/B box.)
- **Text fields:** `KafiTextField` (onboarding) / `KafiInput` (edit-profile) — reuse
  existing per each screen's current convention. Country/City in the exp card use
  `KafiTextField` exactly like the current combined field.
- **Time picker:** Flutter `showTimePicker` (same idiom as the existing
  `showDatePicker` helpers in these screens); format to `"HH:mm"` for storage.
- **Colors/typography:** `KafiTheme.nunito(...)`, `KafiColors.tm/td/ts/pur/purL/purB`
  etc. — never hardcode new hex. Labels use the existing
  `KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)` field-label style.
- **Strings:** all user-facing text via `AppStrings.*` keys (`.tr`) added to both
  `locales/en_us.dart` and `locales/ar_ae.dart` — no raw literals (matches the
  project's l10n pattern; note a few pre-existing literals in these screens are left
  as-is, do not add new ones).
- **Enum labels:** new `EmirateX.label` extension is the single source for emirate
  display names, reused by both emirate grids and the `currentArea` mirror.

## 3. File-by-file change list

All paths under `kafi_app/`. Touch in the order listed in §6.

### 3.1 `lib/models/nanny_model.dart` — MODIFY (foundation)

- **`Emirate` enum (line 5):** remove `alAin`. Final:
  `enum Emirate { dubai, abuDhabi, sharjah, ajman, rak, fujairah, uaq }`.
- **Add extension** (single source for emirate display labels):
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
- **Add `EmploymentType` enum:**
  `enum EmploymentType { fullTimeLiveIn, fullTimeLiveOut, partTime }`.
- **Add `DayAvailability` value class** (immutable, mirrors `ReferenceContact`
  style). `weekday` is 1–7 (Mon=1 … Sun=7, matching `DateTime.weekday`); `from`/
  `until` are `"HH:mm"` 24h strings:
  ```dart
  class DayAvailability {
    DayAvailability({required this.weekday, required this.from, required this.until});
    final int weekday;      // 1=Mon … 7=Sun
    final String from;      // "HH:mm"
    final String until;     // "HH:mm"
    DayAvailability copyWith({int? weekday, String? from, String? until}) =>
      DayAvailability(weekday: weekday ?? this.weekday, from: from ?? this.from, until: until ?? this.until);
    Map<String, dynamic> toMap() => {'weekday': weekday, 'from': from, 'until': until};
  }
  ```
- **`WorkExperience` (lines 21–55):** replace the single `cityCountry` field with two
  fields `country` and `city` (both `String`, required in the constructor). Keep all
  other fields. Update `toMap()` to write `'country'` and `'city'`, and **remove**
  `'cityCountry'`. Order the constructor params `... employer, country, city,
  fromDate ...`.
- **`NannyModel`:**
  - **Remove** the three emergency fields: `emergencyName`,
    `emergencyRelationship`, `emergencyPhone` — from the constructor (lines 205–207),
    the final field declarations (266–268), `copyWith` params (359–361) + body
    (420–422), and `toMap` (483–485).
  - **Add** `final Emirate? currentEmirate;` (constructor `this.currentEmirate,`
    default null — nullable, additive), placed next to `currentArea`. Keep
    `currentArea` (String) unchanged; add a doc comment: `/// Denormalized display
    label of [currentEmirate], kept for out-of-scope readers (dashboard, card
    codec). Canonical value is [currentEmirate].`
  - **Add** `final List<EmploymentType> employmentTypes;` (constructor
    `this.employmentTypes = const [],`).
  - **Add** `final List<DayAvailability> partTimeAvailability;` (constructor
    `this.partTimeAvailability = const [],`).
  - `copyWith`: add `Emirate? currentEmirate`, `List<EmploymentType>?
    employmentTypes`, `List<DayAvailability>? partTimeAvailability` params and
    `?? this.` body lines (follow the existing nullable-`??` convention; note this
    means `currentEmirate` can be set but not re-cleared to null via copyWith — same
    behavior as every other nullable field here, acceptable).
  - `toMap`: add `'currentEmirate': currentEmirate?.name`,
    `'employmentTypes': employmentTypes.map((e) => e.name).toList()`,
    `'partTimeAvailability': partTimeAvailability.map((d) => d.toMap()).toList()`.
    Keep `'currentArea': currentArea`.

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
- **`workEmirates` parse (lines 73–77):** map through `_emirateByName`, then
  **de-duplicate** (remap can collide `abuDhabi` + `alAin`):
  `.map(_emirateByName).whereType<Emirate>().toSet().toList()`.
- **Add** `currentEmirate: _emirateByName(m['currentEmirate'])`. (No legacy
  fallback from free-text `currentArea` — legacy free-text like "Dubai Marina" isn't
  a reliable emirate; the nanny re-selects on next edit. `currentArea` itself is
  still read as-is for the display mirror.)
- **Add** `employmentTypes` parse:
  `(m['employmentTypes'] as List?)?.map((e) => _enumByName(EmploymentType.values, e)).whereType<EmploymentType>().toList() ?? const []`.
- **Add** `partTimeAvailability` parse via a new `_dayAvailabilityFromMap`:
  ```dart
  DayAvailability _dayAvailabilityFromMap(Map<String, dynamic> m) => DayAvailability(
    weekday: (m['weekday'] as num?)?.toInt() ?? 1,
    from: m['from']?.toString() ?? '',
    until: m['until']?.toString() ?? '',
  );
  ```
  mapped like `references`/`documents` (guard with `Map<String,dynamic>.from`).
- **`_experienceFromMap` (lines 21–31):** replace `cityCountry:` with
  `country: m['country']?.toString() ?? ''` and
  `city: m['city']?.toString() ?? m['cityCountry']?.toString() ?? ''` (legacy
  `cityCountry` folds into `city`, preserving old data).
- **Remove** the three emergency reads (lines 107–109).

### 3.3 `lib/utils/constants/nanny_constants.dart` — MODIFY

- Replace `languages` (lines 21–24) with the canonical list **verbatim** from the
  scope (12 + Other), preserving order:
  ```dart
  static const languages = [
    'English', 'Arabic', 'Filipino/Tagalog', 'Bahasa Indonesia', 'Hindi', 'Urdu',
    'Bengali', 'Amharic', 'Oromo', 'Swahili', 'Punjabi', 'Malayalam', 'Other',
  ];
  ```
- Leave `nationalities`, `jobTitles`, `reasonsLeaving`, `referenceRelations`,
  `totalSteps` (stays **6**) unchanged.

### 3.4 `lib/controllers/nanny_profile_controller.dart` — MODIFY

- **Remove** `currentAreaCtrl` (line 44) and its `.dispose()` (line 135). **Add**
  `final Rx<Emirate?> currentEmirate = Rx<Emirate?>(null);` in the step-1 block.
- **Remove** `emergencyNameCtrl`, `emergencyRelCtrl`, `emergencyPhoneCtrl` (lines
  64–66) and their `.dispose()`s (144–146).
- **Add** step-1 state:
  `final RxList<EmploymentType> employmentTypes = <EmploymentType>[].obs;`
  `final RxList<DayAvailability> partTimeAvailability = <DayAvailability>[].obs;`
- **Add methods:**
  - `void toggleEmploymentType(EmploymentType t)` — add/remove; when removing
    `partTime`, also `partTimeAvailability.clear()` (part-time UI + data disappear
    together, mirrors the health-toggle "clear on No" idiom).
  - `void toggleDay(int weekday)` — if a `DayAvailability` with that weekday exists,
    remove it; else add `DayAvailability(weekday: weekday, from: '', until: '')`.
  - `void setDayFrom(int weekday, String v)` / `setDayUntil(int weekday, String v)` —
    replace the matching entry via `copyWith` (RxList reassign so `Obx` fires).
  - `void toggleAnyEmirate()` — `if (workEmirates.length == Emirate.values.length)
    workEmirates.clear(); else workEmirates.assignAll(Emirate.values);`
  - `bool get allEmiratesSelected => Emirate.values.every(workEmirates.contains);`
- **`_hydrate` (212–265):**
  - Replace `currentAreaCtrl.text = n.currentArea;` with
    `currentEmirate.value = n.currentEmirate;` (no legacy free-text parse).
  - `employmentTypes.assignAll(n.employmentTypes);`
    `partTimeAvailability.assignAll(n.partTimeAvailability);`
  - Remove the three emergency `.text =` lines (253–255).
- **`validatePersonalInfo` (323–354):**
  - Replace the current-area check (333) with
    `if (currentEmirate.value == null) return AppStrings.nannyCurrentAreaRequired;`
    (reuse the existing key — no l10n churn; message stays appropriate).
  - **Remove** the three emergency checks (347–351).
  - **Add**, positioned right after the salary/availability block (keep `bio` last):
    - `if (employmentTypes.isEmpty) return AppStrings.nannyEmploymentTypeRequired;`
    - Part-time gate:
      ```dart
      if (employmentTypes.contains(EmploymentType.partTime)) {
        final ok = partTimeAvailability.isNotEmpty &&
          partTimeAvailability.every((d) => d.from.isNotEmpty && d.until.isNotEmpty);
        if (!ok) return AppStrings.nannyPartTimeAvailabilityRequired;
      }
      ```
- **`savePersonalInfoAndNext` copyWith (368–402):**
  - Replace `currentArea: currentAreaCtrl.text.trim(),` with
    `currentEmirate: currentEmirate.value,`
    `currentArea: currentEmirate.value?.label ?? '',` (populate the display mirror).
  - Add `employmentTypes: List.of(employmentTypes),`
    `partTimeAvailability: List.of(partTimeAvailability),`.
  - **Remove** the three emergency copyWith args (398–400).
- **`saveProfileDraft` (285–312):** remove the `currentArea: currentAreaCtrl…` line
  and the three emergency args. (Edit-profile screen edits neither location nor
  emergency, so dropping these lines is correct and avoids clobbering a legacy
  nanny's `currentArea` with an empty string.) Leave the `workEmirates` line as-is.

### 3.5 `lib/views/nanny/nanny_info_screen.dart` — MODIFY

- **Remove import** `kafi_location_picker.dart` (line 10). **Add import**
  `kafi_chip_wrap.dart` if not already present (it is, line 9 — confirm).
- **`build` children (36–47):** remove `_emergency()`; insert `_employment()` right
  after `_workPrefs()`. New order:
  `_basic(), _visa(), _workLocation(), _workPrefs(), _employment(), _personal(),
  _health(), _comfort(), _religion(), _bio()`.
- **`_workLocation()` (316–378):** rework into three blocks inside the same
  `KafiSection`:
  1. **Current emirate (single-select), net UI:** a label
     (`AppStrings.nannyCurrentEmirateLabel.tr`) + a 2-col `GridView.count`
     (childAspectRatio ~2.2, same as the existing grid) of `_currentEmirateBox(...)`
     over `Emirate.values` (7), wrapped in `Obx`. Selected when
     `controller.currentEmirate.value == value`; tap sets
     `controller.currentEmirate.value = value`.
  2. **Preferred job location (multi-select):** keep the existing `workEmirates`
     grid but **remove the Al Ain box** (delete line 346) → 7 boxes. **Add** an
     "Any Emirate" `KafiChip` (`purple: true`) above/below the grid:
     `selected: controller.allEmiratesSelected`, `onTap: controller.toggleAnyEmirate`.
     Keep the info banner and the `fldEmirates` label.
  3. **Relocate toggle:** keep the existing `willingRelocate` `KafiToggleBox` row
     (351–369) unchanged.
  - **Delete** the `KafiLocationPicker(...)` block (371–375) entirely.
- **Add `_currentEmirateBox(String emoji, String name, Emirate value, bool selected)`**
  — copy the existing `_emirateBox` styling verbatim; `onTap` sets the single
  `currentEmirate`. To avoid duplicating the emoji/subtitle data across the two
  grids, define one private `const _emirates = <(_E)>[...]` list of
  `(Emirate, emoji, subtitle)` records at top of the class and drive **both** grids
  from it (names come from `EmirateX.label`). This removes the hardcoded 8-box list
  that caused the Al Ain bug and guarantees both grids show the same 7.
- **Add `_employment()`** — a `KafiSection(title: nannySecEmployment,
  icon: Icons.work_outline, accent: purple)` containing:
  1. Label `nannyEmploymentQuestion` + an `Obx` `Column` of three `KafiToggleTile`
     (`purple: true`, multi-select): Full-Time Live-In / Full-Time Live-Out /
     Part-Time. `selected: controller.employmentTypes.contains(type)`,
     `onTap: () => controller.toggleEmploymentType(type)`.
  2. **Conditional part-time block**, `Obx(() => employmentTypes.contains(partTime)
     ? _partTimeAvailability() : const SizedBox.shrink())`.
- **Add `_partTimeAvailability()`** — label `nannyPartTimeQuestion` + a `Wrap` of 7
  `KafiChip` (`purple: true`) for Mon–Sun (labels `AppStrings.dayMon…daySun`),
  `selected` when a `DayAvailability` for that weekday exists,
  `onTap: () => controller.toggleDay(weekday)`. Below, an `Obx` that, for each
  selected day (sorted by weekday), renders a row: day name + two tappable
  `AbsorbPointer`/`GestureDetector` time fields (from / until) using `showTimePicker`
  → `controller.setDayFrom/setDayUntil(weekday, "HH:mm")`, displaying the value or an
  em-dash placeholder. Reuse the existing date-field visual idiom
  (`_dateField`-style container). Edge case: a selected day with unset times is
  visually flagged (placeholder shown) and is what the validator blocks on.
- **Remove `_emergency()` (608–665) and `_relValue()` (667–671)** entirely.
- Keep `_bio()` unchanged.

### 3.6 `lib/views/nanny/nanny_exp_screen.dart` — MODIFY

- **`_addBtn` default `WorkExperience` (83–93):** replace `cityCountry: ''` with
  `country: '', city: ''`.
- **`_ExpCard` state:** rename `_city` to represent City and **add** `_country`
  `TextEditingController` (seed `_country = TextEditingController(text: e.country)`,
  `_city = TextEditingController(text: e.city)`). Add both to the listener list
  (156–158) and `dispose` list (177–179).
- **`_emit` (161–173):** build `WorkExperience(... country: _country.text,
  city: _city.text ...)` (drop `cityCountry`).
- **`build` (251–252):** replace the single combined field with two `KafiTextField`s:
  `KafiTextField(label: AppStrings.expCountry.tr, controller: _country, hint: 'e.g. Philippines')`
  then
  `KafiTextField(label: AppStrings.expCity.tr, controller: _city, hint: 'e.g. Dubai')`.
  No maps/GPS (already none). Keep Job role dropdown, dates, children, duties, reason
  as-is.

### 3.7 `lib/views/nanny/nanny_edit_profile_screen.dart` — MODIFY

- **Add import** `kafi_chip_wrap.dart` and `nanny_constants.dart`.
- **Languages section (37–79):** replace the hardcoded 6-item list + bespoke
  `GestureDetector` chips with an `Obx` `Wrap` of `KafiChip` over
  `NannyConstants.languages`, `selected: ctrl.selectedLanguages.contains(l)`,
  `onTap: () => ctrl.toggleLanguage(l)` (reuse the controller's existing
  `toggleLanguage`). This converges the third language list to the single source.
- **Remove the entire Emergency Contact `_section(...)` block (80–102).**
- `saveProfileDraft` already updated in §3.4 (no emergency args) — no further change
  here; the Save button flow (128–141) is unchanged.
- Update the class doc comment (10–12) to drop "emergency contact" from the list of
  editable fields.

### 3.8 l10n — MODIFY `lib/l10n/app_strings.dart` + `locales/en_us.dart` + `locales/ar_ae.dart`

Add these keys (constant in `app_strings.dart`, value in **both** locale maps —
Arabic translated, not English placeholder). Suggested EN values:

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

- **Reuse** existing keys: `nannyCurrentAreaRequired` (current-emirate required
  message), `fldEmirates` (preferred-location label), `secWorkLoc` (section title),
  `fldRelocate`, `fldBio`, `secBio`.
- **Do not delete** the now-unused emergency keys (`secEmergency`, `fldEmergency*`,
  `nannyEmergency*Required`, `editEmergencyContact`) or `fldCurrentArea`/`expCityCountry`
  — leaving orphaned constants is harmless and avoids touching unrelated call sites;
  optionally note them as dead for a later sweep. (If the developer prefers, they may
  remove the ones with zero remaining references after this change — reviewer's call,
  not required.)

### 3.9 `test/onboarding/onboarding_validation_test.dart` — MODIFY

- `_fillValidPersonalInfo` (277–294): replace
  `c.currentAreaCtrl.text = 'Dubai Marina';` with
  `c.currentEmirate.value = Emirate.dubai;`; **remove** the three emergency fills;
  **add** `c.employmentTypes.assignAll([EmploymentType.fullTimeLiveIn]);` so the base
  "passes" case stays valid under the new required-employment rule.
- Test "empty current area is rejected" (96–99): change body to
  `c.currentEmirate.value = null;`, keep `expect(..., AppStrings.nannyCurrentAreaRequired)`.
- **Remove** the three emergency tests (123–134).
- **Add** three tests:
  - `no employment type is rejected` → `c.employmentTypes.clear();` expect
    `nannyEmploymentTypeRequired`.
  - `part-time with no availability is rejected` →
    `c.employmentTypes.assignAll([EmploymentType.partTime]);` (leave
    `partTimeAvailability` empty) expect `nannyPartTimeAvailabilityRequired`.
  - `part-time with a day and times passes` → add a `DayAvailability(weekday:1,
    from:'08:00', until:'17:00')` to `partTimeAvailability`, keep employment=[partTime],
    expect `isNull`.

### 3.10 `test/services/match_service_test.dart` — MODIFY (compile-fix only)

- `exp(int years)` helper (112–116) constructs `WorkExperience(... cityCountry:
  'Dubai' ...)`. Replace with `country: 'UAE', city: 'Dubai'`. No other change; this
  does **not** touch `match_service.dart`.

## 4. Work units & parallelization

- **WU-1 — Model + codec + constants** (`nanny_model.dart`, `nanny_map_codec.dart`,
  `nanny_constants.dart`). **SEQUENTIAL, foundation.** Everything depends on it. Build
  first.
- **WU-2 — l10n** (`app_strings.dart`, `en_us.dart`, `ar_ae.dart`). **INDEPENDENT**
  (no file overlap with any other unit). Can run in parallel with WU-1. Screens in
  WU-3/WU-4 reference these keys, so land it before/with them.
- **WU-3 — Controller + onboarding screen + edit screen**
  (`nanny_profile_controller.dart`, `nanny_info_screen.dart`,
  `nanny_edit_profile_screen.dart`). **SEQUENTIAL after WU-1 & WU-2.** These three
  share controller contracts, so one developer owns them as a set.
- **WU-4 — Experience screen** (`nanny_exp_screen.dart`). **INDEPENDENT** of WU-3
  (only shares the `WorkExperience` shape from WU-1). Can run in parallel with WU-3
  once WU-1 lands.
- **WU-5 — Tests** (`onboarding_validation_test.dart`, `match_service_test.dart`).
  **SEQUENTIAL, last** — depends on all of the above; run `flutter analyze` +
  `flutter test`.

Parallel-safe pairs: WU-2 ∥ WU-1; WU-4 ∥ WU-3 (after WU-1). No two units write the
same file.

## 5. Refactor callouts / design notes (no separate refactor needed)

The affected code is sound and idiomatic (clean controller/screen/codec separation,
consistent design-system usage) — **no pre-work refactor required.** Two contained
improvements are folded into the change itself:

1. **Emirate label single-source.** The 8-box hardcoded grid (with the Al Ain bug) is
   replaced by iterating `Emirate.values` + `EmirateX.label`, so the emirate set can
   never drift out of sync with the enum again.
2. **Language list single-source.** Three lists converge to `NannyConstants.languages`.

Noted, **not acted on** (out of scope): `employmentTypes` (new) conceptually overlaps
`jobTypePreference` (live-in/out/both), which `match_service._jobTypeScore` consumes.
Consolidating them would require editing `match_service.dart` (out of scope + a
cross-phase collision zone). Left as an additive parallel field; flag for a future
matching-alignment task if the client wants employment type to influence scoring.

## 6. Test plan

Automated (must pass):
- `flutter analyze` — zero new issues (enum removal, field renames, removed emergency
  refs all resolved).
- `flutter test test/onboarding/onboarding_validation_test.dart` — updated + 3 new
  cases green.
- `flutter test test/services/match_service_test.dart` — green after the `exp()`
  helper fix.

Manual/review flows to exercise:
1. Fresh nanny onboarding Step 1: pick current emirate (single), preferred emirates
   (multi + "Any Emirate" selects all 7 and reflects as selected), select employment
   types; select Part-Time → day multi-select + per-day from/until appear; a
   Part-Time selection with no day (or a day with missing time) blocks Next with the
   localized message; filling one day+times unblocks. No Al Ain anywhere. No map/GPS
   picker anywhere on the screen.
2. Work-experience add: Country + City are separate plain-text fields; save + reload
   round-trips both.
3. Emergency section absent in both onboarding Step 1 and edit-profile; Bio present
   and functional; removing it does not block Step 1 completion for an otherwise-valid
   profile.
4. Edit-profile languages show the 12 + Other list (KafiChip), toggle persists.
5. Codec remap: a nanny doc with `workEmirates:['alAin','dubai']` and
   `currentEmirate:'alAin'` loads as `[abuDhabi, dubai]` (de-duped) and
   `currentEmirate == abuDhabi`; a legacy experience with only `cityCountry` shows its
   text in the City field.

## 7. Definition of done (buildable, gradable checklist)

- [ ] `Emirate` enum has exactly 7 values (no `alAin`); both emirate grids render the
      same 7 from `Emirate.values` + `EmirateX.label`.
- [ ] Codec `_emirateByName` remaps `'alAin' → 'abuDhabi'` on read for `workEmirates`
      (de-duped) and `currentEmirate`; exercised (covered by review flow 5 / a test if
      the developer adds a codec test).
- [ ] `NannyConstants.languages` is the canonical 12 + Other list, verbatim; both
      onboarding `_basic()` and edit-profile read it; no other hardcoded nanny language
      list remains.
- [ ] Current location is a single-select of the 7 emirates writing
      `currentEmirate` (+ `currentArea` label mirror); the `KafiLocationPicker`/GPS
      call site is removed from `nanny_info_screen.dart`; no GPS/Places call is
      reachable from the current-location or work-experience-city fields.
- [ ] Preferred job location = 7-emirate multi-select + working "Any Emirate" (writes
      all 7).
- [ ] Employment-type section (Full-Time Live-In / Full-Time Live-Out / Part-Time,
      multi-select) exists, persists, and is required for completion.
- [ ] Part-time availability shows only when Part-Time is selected; each selected day
      has independent from/until; a Part-Time selection with zero days or any missing
      time blocks completion via `nannyPartTimeAvailabilityRequired`.
- [ ] Work experience collects Country + City (plain text) + Job role + Start + End +
      Main responsibilities; legacy `cityCountry` migrates into `city`; no map/GPS.
- [ ] Emergency Contact removed from model, codec, controller, both screens, and its
      validation + tests; `validatePersonalInfo` no longer references emergency;
      removing it doesn't break Step-1 completion.
- [ ] All new user-facing strings are `AppStrings` keys present in both `en_us.dart`
      and `ar_ae.dart`.
- [ ] `flutter analyze` clean; onboarding + match_service tests updated and passing.

## 8. Scope-boundary confirmation

- **Untouched (out of scope):** `nanny_refs_screen.dart`, `trial_offer_screen.dart`,
  `KafiLocationPicker`/`LocationService`/`PlacesService`, `match_service.dart`,
  everything in `functions/` and `admin-panel/`, family side (phase 2), trial flow
  (phase 3).
- **No cross-phase collision:** this plan does **not** edit `match_service.dart`,
  `firestore_job_service.dart`, or `nanny_dashboard_screen.dart` (the `currentArea`
  display mirror keeps the latter two green). The family phase's `match_service`/
  `firestore.ts` work does not overlap any file here.
- **Admin-panel note for the build doc:** the admin panel reads `emergencyName/…`
  and (after this change) will find them absent on newly-saved nanny docs, and will
  not know `currentEmirate`/`employmentTypes`/`partTimeAvailability`. This is expected
  (fields removed/added by product decision); flag in `builds/<slug>.md` as a
  follow-up for a future admin-panel task — do not expand scope to fix it here.
