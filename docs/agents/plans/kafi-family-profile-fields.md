---
slug: kafi-family-profile-fields
project: kafi
title: Family profile — emirate-only location, expanded languages, multi-select role with "Other", days-off replacing free-text schedule
owner: architect
status: READY_FOR_BUILD
updated: 2026-08-15
epic: kafi-profile-trial-overhaul (phase 2 of 3 — parallel with kafi-nanny-profile-fields and kafi-trial-completion-flow)
branch: (developer to create, one worktree per this task)
---

# Plan — Family profile field overhaul (phase 2)

Read against the live source on 2026-08-15. The scope doc's line refs had
drifted (the controller is now 320 lines with `startJobEdit`/`_selectEditPost`,
not the 277-line version the scope described); everything below is verified
against current files.

## 0. Decisions, scope risks & cross-phase notes (READ FIRST)

Three findings change or extend the scope. The PM should note them; none block
the build.

### D1 — `city` stays a `String` field storing a canonical emirate LABEL; it is NOT retyped to `Emirate`
The scope says "free String → the shared 7-value Emirate enum." Taken literally
(retyping `FamilyModel.city`/`JobPostModel.city` to `Emirate?`) this ripples into
~14 consumers that read `city` as a `String` — `browse_screen`, `browse_controller`,
`smart_match_screen`, `compare_screen`, `job_post_controller`, `jobs_home_screen`,
`nanny_dashboard_screen`, `my_applications_screen`, `application_detail_screen`,
`kafi_nanny_card`, `profile_hero`, **`match_service._locationScore`/`_cardLocation`**,
plus both Firestore deserializers and the admin panel — almost all **out of scope**
and some plausibly owned by sibling phases. That contradicts the scope's own
"Explicit scope boundaries" and the epic's "no two phases edit the same file" rule.

**Chosen design (smallest change that meets the acceptance criteria):** keep the
model field as `String`; make the *selection* strongly typed via the shared
`Emirate` enum and persist `emirateLabel(e)` — one of exactly 7 canonical strings
("Abu Dhabi", "Dubai", "Sharjah", "Ajman", "Umm Al Quwain", "Ras Al Khaimah",
"Fujairah"). This satisfies the behavioral criterion ("single-select from the 7
real emirates, same enum values as the nanny `Emirate` enum") at the input +
validation layer, touches zero out-of-scope consumers, improves display
everywhere (canonical "Dubai" instead of legacy free-text "Dubai Marina, Villa 3"),
and is tolerant of existing data. The enum is **reused** (imported), not
re-declared.
_Alternative if the PM/Waseem require a strictly enum-typed field: that is a
larger, boundary-crossing change (all consumers above + `match_service`) and
should be re-scoped as its own task. Do not do it inside this phase without
re-approval._

### D2 — Cloud Functions DO touch `schedule` (scope's "no backend change" assumption is FALSE for this field)
Verified: `functions/src/utils/translate.ts:30` lists `'schedule'` in `JOB_TX.fields`
and `functions/src/triggers/translate.ts` auto-translates it (en/ar). No function
touches family `city`, `rolesNeeded`, `daysOff`, or `languagesAtHome`.
Renaming `schedule` → `daysOff` means `JOB_TX` will reference a field that no
longer exists on new docs. **This is harmless:** `computeTranslationUpdates`
(`translate.ts:64-66`) does `const src = String(after[field] ?? '').trim(); if
(!src) continue;` — an absent field is skipped. Days-off values are a fixed
3-item canonical set that does not need per-doc machine translation.
**Decision: leave `functions/` untouched** (respecting the scope boundary "do not
touch `functions/`") and file the stale `'schedule'` entry as a follow-up cleanup
for a functions-owning task. Documented here so the reviewer does not flag it as
a miss.

### D3 — Shared-infra files this phase edits (collision watch for phases 1 & 3)
This phase edits, besides the family-only files, these shared/infra files:
`kafi_app/lib/models/job_post_model.dart`,
`kafi_app/lib/services/firebase/firestore_job_service.dart`,
`kafi_app/lib/views/nanny/job_detail_screen.dart`,
`kafi_app/lib/views/family/my_jobs_screen.dart`,
`kafi_app/lib/l10n/app_strings.dart` + `locales/en_us.dart` + `locales/ar_ae.dart`,
and `admin-panel/src/services/firestore.ts` + two admin pages.
It **only imports** (never edits) `nanny_model.dart` (phase 1's file) for the
`Emirate` enum. If phase 1 or 3 also edit any file above, the PM should sequence
the merges. No overlap is expected (phase 1 = nanny profile, phase 3 = trial
flow), but `job_post_model.dart` and `app_strings`/locales are the realistic
contention points.

### D4 — Emirate enum reuse without editing phase 1's file
`Emirate` lives in `nanny_model.dart` (phase 1 is fixing it from 8→7 by removing
`alAin`). We reuse it by **import**, and we **never reference `Emirate.alAin`**
anywhere in this phase's code (we declare an explicit 7-item option list and a
7-key label map). Result: our code compiles both on our branch (where `alAin`
still exists pre-merge) and after phase 1 lands (where it is gone). We do **not**
relocate the enum to a shared file — that would require editing `nanny_model.dart`
and collide with phase 1. If phase 1 relocates the enum instead of fixing it in
place, only the import path in two new/edited files needs updating (flagged in
those files' notes).

### D5 — `my_jobs_screen.dart` quick-edit sheet reads `job.schedule` (not in scope's file list, but forced)
`_JobEditSheet` in `my_jobs_screen.dart` edits `schedule` via a free-text field.
Removing the model field forces a change here or it won't compile. We remove the
schedule field from that quick-edit sheet (title + salary remain); days-off is
edited via the full editor (`family_edit_screen`), reachable from the sheet's
existing "Full details" bridge. In-scope-by-necessity.

---

## 1. Architecture summary

Data flow is unchanged in shape: `FamilyFormScreen`/`FamilyEditScreen` (both
`GetView<FamilyProfileController>`) drive one controller whose `_persist()`
writes a `FamilyModel` (via `IUserService.saveFamily`) and a `JobPostModel` (via
`IJobService.saveJobPost`). Location is still written from one controller value
into both `FamilyModel.city` and `JobPostModel.city` — that dual-write pattern is
**kept** (it is correct and simple); we only change the source from a free-text
`RxString city` to a typed `Rx<Emirate?> cityEmirate`, persisting the same
`emirateLabel(e)` string into both fields.

New/changed module boundaries:
- **`lib/utils/emirate_ui.dart`** (CREATE) — the single source of truth for the
  family emirate option list, label lookup, and stored-string → enum parsing.
  Reuses the shared `Emirate` enum.
- **`lib/views/widgets/family_job_selectors.dart`** (CREATE) — three small shared
  stateless selectors (`FamilyEmirateSelector`, `FamilyRoleSelector`,
  `FamilyDaysOffSelector`) so the form and edit screens stop duplicating the
  role/emirate/days-off UI (satisfies the no-duplication bar and the scope's
  explicit "consolidate the two role chip implementations" requirement).

Everything else is field renames/type-narrowing that stays inside existing
patterns (GetX Rx state, `KafiChip`/`KafiToggleTile` design components, `KafiSection`
layout, `_jobFromMap` deserialization, admin `Field`/`FieldGrid` display).

---

## 2. Reuse map (use these — do NOT invent new UI or utilities)

- **`Emirate` enum** — `kafi_app/lib/models/nanny_model.dart` (imported, not
  redefined). Values used: `abuDhabi, dubai, sharjah, ajman, uaq, rak, fujairah`.
- **`KafiChip`** — `lib/views/widgets/kafi_chip_wrap.dart` (the `purple`-bool
  variant the family screens already import; NOT the `kafi_chip.dart` variant).
  Use for emirate single-select chips, role multi-select chips, and days-off
  single-select chips, all with `purple: true`.
- **`KafiTextField`** — `lib/views/widgets/kafi_text_field.dart`, `purple: true`,
  for the role "Other" reveal field.
- **`KafiSection`** / **`KafiToggleTile`** — existing section + toggle widgets;
  job-type / employment toggles are unchanged.
- **Design tokens** (`lib/views/shared/kafi_theme.dart`): reuse `KafiColors.pur`,
  `purL`, `purB`, `inputBgP` and `KafiTheme.nunito/fredoka` exactly as the
  existing chip `Wrap`s do. The `_label(...)` helper style in each screen
  (`KafiTheme.nunito(9, color: 0xFF5A2090, w: FontWeight.w800)`) is the label
  style to reuse for the new field labels. No new colors, radii, or fonts.
- **`FamilyConstants`** lists for the chip sources.
- **Validation snackbar pattern** — `Get.snackbar(AppStrings.errorTitle.tr,
  key.tr)` via the existing `validateFamily()` return-key mechanism.

Do **not** touch `KafiLocationPicker`, `LocationService`, `PlacesService`,
`autoDetectCity` machinery beyond removing the family call sites — they remain
for the out-of-scope trial/reference pickers.

---

## 3. File-by-file change list (in build order)

### CREATE — `kafi_app/lib/utils/emirate_ui.dart`
Shared emirate option list + label + reverse-parse. Reuses `Emirate`.
```dart
import 'package:kafi_app/models/nanny_model.dart';

/// The 7 real UAE emirates in display order, reusing the shared [Emirate] enum.
/// Declared explicitly (not `Emirate.values`) so this list is independent of the
/// enum's declaration/order and never surfaces the removed `Al Ain` value —
/// which keeps it compiling both before and after the nanny phase's 8→7 fix.
const List<Emirate> kFamilyEmirates = [
  Emirate.abuDhabi, Emirate.dubai, Emirate.sharjah, Emirate.ajman,
  Emirate.uaq, Emirate.rak, Emirate.fujairah,
];

const Map<Emirate, String> _emirateLabels = {
  Emirate.abuDhabi: 'Abu Dhabi',
  Emirate.dubai: 'Dubai',
  Emirate.sharjah: 'Sharjah',
  Emirate.ajman: 'Ajman',
  Emirate.uaq: 'Umm Al Quwain',
  Emirate.rak: 'Ras Al Khaimah',
  Emirate.fujairah: 'Fujairah',
};

String emirateLabel(Emirate e) => _emirateLabels[e] ?? e.name;

/// Parses a stored `city` string back to an [Emirate]. Tolerant of legacy
/// free-text: matches a canonical label OR the enum `.name`, case-insensitively;
/// returns null when the stored value is none of the 7 (so old free-text data
/// simply shows nothing pre-selected instead of crashing).
Emirate? emirateFromStored(String? s) {
  final v = (s ?? '').trim().toLowerCase();
  if (v.isEmpty) return null;
  for (final e in kFamilyEmirates) {
    if (emirateLabel(e).toLowerCase() == v || e.name.toLowerCase() == v) return e;
  }
  return null;
}
```
Edge cases handled: null/empty → null; unknown legacy string → null; both
label and `.name` accepted. Never references `Emirate.alAin` (D4).

### MODIFY — `kafi_app/lib/utils/constants/family_constants.dart`
Replace two lists wholesale, add one:
- `homeLanguages` → the 8 verbatim items, in the requirement's order:
  `['Arabic', 'English', 'Hindi', 'Urdu', 'Tagalog', 'French', 'Russian', 'Other']`.
- `roles` → the 11 verbatim items, in order:
  `['Maid & Nanny', 'Nanny', 'Maid', 'Babysitter', "Mother's Helper", 'Child Caregiver', 'Elderly Caregiver', 'Cook', 'Household Helper', 'Pet Caregiver', 'Other']`.
- ADD `static const daysOffOptions = ['1 day off', '2 days off', 'Other'];`.
- Leave `duties`, `benefits`, `trialDurations` unchanged.

### MODIFY — `kafi_app/lib/models/job_post_model.dart`
- Remove `schedule`: delete `this.schedule = ''` (ctor), `final String schedule;`,
  the `String? schedule` copyWith param + `schedule: schedule ?? this.schedule,`
  body line, and `'schedule': schedule,` in `toMap()`.
- ADD `daysOff`: `this.daysOff = ''` (ctor, same position), `final String daysOff;`,
  `String? daysOff` copyWith param + `daysOff: daysOff ?? this.daysOff,` body,
  and `'daysOff': daysOff,` in `toMap()`.
- ADD `rolesOther` (holds the custom "Other" role text; null when not used):
  `this.rolesOther` (ctor), `final String? rolesOther;`, `String? rolesOther`
  copyWith param + `rolesOther: rolesOther ?? this.rolesOther,` body, and
  `'rolesOther': rolesOther,` in `toMap()`.
- `city` unchanged (`String`, per D1).

### MODIFY — `kafi_app/lib/services/firebase/firestore_job_service.dart`
In `_jobFromMap` (~line 129): replace `schedule: m['schedule'] ?? '',` with
`daysOff: m['daysOff'] ?? '',` and ADD `rolesOther: m['rolesOther'] as String?,`.
`city: m['city'] ?? ''` unchanged. (Reads legacy docs safely: missing `daysOff`
→ `''`, missing `rolesOther` → null.)

### MODIFY — `kafi_app/lib/l10n/app_strings.dart` (+ both locale files)
ADD keys (string constants):
- `fldSelectEmirate = 'fld_select_emirate'`
- `fldRolePrompt = 'fld_role_prompt'`
- `fldRoleOther = 'fld_role_other'`
- `fldDaysOff = 'fld_days_off'`
- `familyDaysOffRequired = 'family_days_off_required'`
- `familyRoleOtherRequired = 'family_role_other_required'`

`locales/en_us.dart` values:
- `fldSelectEmirate: 'Select your emirate'`
- `fldRolePrompt: 'What type of help are you looking for?'`
- `fldRoleOther: 'Please specify the role you are looking for'`
- `fldDaysOff: 'How many days off will you provide each week?'`
- `familyDaysOffRequired: 'Please choose how many days off you will provide.'`
- `familyRoleOtherRequired: 'Please specify the role you are looking for.'`
- Update `familyCityRequired` value → `'Please select your emirate.'`

`locales/ar_ae.dart` values:
- `fldSelectEmirate: 'اختر الإمارة'`
- `fldRolePrompt: 'ما نوع المساعدة التي تبحث عنها؟'`
- `fldRoleOther: 'يرجى تحديد الدور الذي تبحث عنه'`
- `fldDaysOff: 'كم يوم إجازة ستوفر كل أسبوع؟'`
- `familyDaysOffRequired: 'يرجى اختيار عدد أيام الإجازة التي ستوفرها.'`
- `familyRoleOtherRequired: 'يرجى تحديد الدور الذي تبحث عنه.'`
- Update `familyCityRequired` (ar) → `'يرجى اختيار الإمارة.'`

Leave `fldSchedule`, `familyScheduleRequired`, `jobFieldSchedule`,
`locationDetecting`, `fldCity` keys defined but unused (harmless; removing them is
optional cleanup, not required — do not spend effort chasing them).

### CREATE — `kafi_app/lib/views/widgets/family_job_selectors.dart`
Three stateless widgets, each taking the controller. Reuse `KafiChip(purple:true)`
and `KafiTextField(purple:true)`; wrap reactive parts in `Obx`. Use `Wrap(spacing:4,
runSpacing:4)` to match the existing chip rows.

- **`FamilyEmirateSelector`** — single-select. `Obx` over `Wrap` of
  `kFamilyEmirates.map((e) => KafiChip(label: emirateLabel(e), purple: true,
  selected: controller.cityEmirate.value == e, onTap: () =>
  controller.cityEmirate.value = e))`. (Single-select: tapping sets the value;
  no toggle-off needed since selection is required.)
- **`FamilyRoleSelector`** — multi-select + "Other" reveal. Column of:
  (1) `Obx` `Wrap` of `FamilyConstants.roles.map((r) => KafiChip(label: r,
  purple: true, selected: controller.roles.contains(r), onTap: () =>
  controller.toggle(controller.roles, r)))`;
  (2) `Obx(() => controller.roles.contains('Other') ? Padding(top:6,
  child: KafiTextField(label: AppStrings.fldRoleOther.tr, controller:
  controller.rolesOtherCtrl, purple: true)) : const SizedBox.shrink())`.
- **`FamilyDaysOffSelector`** — single-select, no elaboration for "Other".
  `Obx` `Wrap` of `FamilyConstants.daysOffOptions.map((o) => KafiChip(label: o,
  purple: true, selected: controller.daysOff.value == o, onTap: () =>
  controller.daysOff.value = o))`. No text field for any option.

Imports: `flutter/material`, `get`, the controller, `family_constants`,
`emirate_ui`, `l10n/app_strings`, `kafi_chip_wrap`, `kafi_text_field`.

### MODIFY — `kafi_app/lib/controllers/family_profile_controller.dart`
- Imports: ADD `package:kafi_app/models/nanny_model.dart` (for `Emirate`) and
  `package:kafi_app/utils/emirate_ui.dart`. REMOVE
  `package:kafi_app/services/location_service.dart`.
- Remove the `LocationService _location = Get.find<LocationService>();` field and
  the `RxBool detectingCity` field.
- Replace `final RxString city = ''.obs;` with
  `final Rx<Emirate?> cityEmirate = Rx<Emirate?>(null);`.
- Replace `final scheduleCtrl = TextEditingController();` with
  `final RxString daysOff = ''.obs;`.
- ADD `final rolesOtherCtrl = TextEditingController();`.
- `onInit`: change to just `_hydrateFromCurrentUser();` (drop
  `.then((_) => autoDetectCity())`).
- Delete the entire `autoDetectCity()` method.
- `_hydrateFromCurrentUser()`:
  - Replace `if (fam.city.isNotEmpty) city.value = fam.city;` with
    `cityEmirate.value = emirateFromStored(fam.city);`.
  - Replace `scheduleCtrl.text = p.schedule;` with
    `daysOff.value = FamilyConstants.daysOffOptions.contains(p.daysOff) ? p.daysOff : '';`
    (guards legacy free-text schedule values so nothing invalid is pre-selected).
  - ADD `rolesOtherCtrl.text = p.rolesOther ?? '';`.
- `onClose`: remove `scheduleCtrl.dispose();`; ADD `rolesOtherCtrl.dispose();`.
- `validateFamily()`:
  - Replace `if (city.value.trim().isEmpty) return AppStrings.familyCityRequired;`
    with `if (cityEmirate.value == null) return AppStrings.familyCityRequired;`.
  - After the `if (roles.isEmpty) return AppStrings.familyRolesRequired;` line, ADD
    `if (roles.contains('Other') && rolesOtherCtrl.text.trim().isEmpty) return AppStrings.familyRoleOtherRequired;`.
  - Replace `if (scheduleCtrl.text.trim().isEmpty) return AppStrings.familyScheduleRequired;`
    with `if (daysOff.value.trim().isEmpty) return AppStrings.familyDaysOffRequired;`.
- `_persist()`:
  - Compute once: `final cityLabel = cityEmirate.value != null ? emirateLabel(cityEmirate.value!) : '';`
    (place after the `err`/`fid` guards).
  - `FamilyModel(... city: cityLabel ...)`.
  - `JobPostModel(... city: cityLabel, ... )`.
  - Replace `schedule: scheduleCtrl.text.trim(),` with `daysOff: daysOff.value,`.
  - ADD `rolesOther: roles.contains('Other') ? rolesOtherCtrl.text.trim() : null,`.

### MODIFY — `kafi_app/lib/views/family/family_form_screen.dart`
- Imports: REMOVE `kafi_location_picker.dart`; ADD
  `package:kafi_app/views/widgets/family_job_selectors.dart`.
- `_yourFamily()`: the current `Row` pairs the city picker (`Obx` with
  `detectingCity`/`KafiLocationPicker`) and the children-count field. Replace that
  whole `Row` with:
  - `_label(AppStrings.fldSelectEmirate.tr)`, `SizedBox(height:4)`,
    `FamilyEmirateSelector(controller)` (full width),
  - then the existing children-count `KafiTextField` (label `fldChildrenCount`,
    `controller.childrenCtrl`) as its own full-width field below.
  Delete the `_detectingCity()` helper method (now unreferenced).
- Languages `Wrap`: no change (reads `FamilyConstants.homeLanguages`, now 8 items).
- `_roleJobType()`:
  - Replace the `_label('Role(s) needed')` + role chips `Obx(Wrap...)` with
    `_label(AppStrings.fldRolePrompt.tr)`, `SizedBox(height:4)`,
    `FamilyRoleSelector(controller)`.
  - Keep the job-type and employment `KafiToggleTile` rows unchanged.
  - Replace the trailing schedule `KafiTextField` block (label `fldSchedule`,
    `controller.scheduleCtrl`) with `_label(AppStrings.fldDaysOff.tr)`,
    `SizedBox(height:4)`, `FamilyDaysOffSelector(controller)`.

### MODIFY — `kafi_app/lib/views/family/family_edit_screen.dart`
- Imports: REMOVE `kafi_location_picker.dart`; ADD `family_job_selectors.dart`.
- `_youSection()`: replace the city label + `Obx(KafiLocationPicker...)` with the
  `fldSelectEmirate` label + `FamilyEmirateSelector(controller)`. Languages `Wrap`
  unchanged.
- `_roleSection()`:
  - Replace the role chips `Obx(Wrap...)` with a `fldRolePrompt` label +
    `FamilyRoleSelector(controller)`.
  - Keep job-type / employment toggles.
  - Replace the trailing schedule `KafiTextField` (label `fldSchedule`,
    `controller.scheduleCtrl`) with `fldDaysOff` label +
    `FamilyDaysOffSelector(controller)`.

### MODIFY — `kafi_app/lib/views/nanny/job_detail_screen.dart`
Line ~146: `_detailRow('Schedule', job.schedule.isNotEmpty ? job.schedule :
'Not specified')` → `_detailRow('Days off', job.daysOff.isNotEmpty ? job.daysOff :
'Not specified')`.

### MODIFY — `kafi_app/lib/views/family/my_jobs_screen.dart` (D5)
In `_JobEditSheet`/`_JobEditSheetState`:
- Remove the `_schedule` `TextEditingController` field (decl + `dispose()`).
- Remove the schedule `KafiTextField(label: AppStrings.jobFieldSchedule.tr,
  controller: _schedule, ...)` from `build`.
- In `_save()`, remove `schedule: _schedule.text.trim(),` from the
  `widget.job.copyWith(...)`. (Title + salary quick-edit remain; days-off is
  edited via the "Full details" bridge.)

### MODIFY — `admin-panel/src/services/firestore.ts`
- `JobPostRow` (line ~203): `schedule?: string;` → `daysOff?: string;`.
- Job mapper (line ~1051): `schedule: data.schedule as string | undefined,` →
  `daysOff: data.daysOff as string | undefined,`.
- Mock seed job rows (`schedule: '...'` at ~552, 565, 574, 584, 596): rename each
  key to `daysOff` with a value from the canonical set, e.g. `daysOff: '1 day off'`
  (or `'2 days off'`) — pick a sensible value per row; do not keep the old
  free-text schedule strings.
- `city` fields unchanged (they already hold display strings; the app now writes
  canonical labels).

### MODIFY — `admin-panel/src/pages/families/FamilyDetail.tsx`
Line ~64: `<Field label="Schedule" value={job.schedule || '—'} />` →
`<Field label="Days off" value={job.daysOff || '—'} />`.

### MODIFY — `admin-panel/src/pages/trials/TrialDetail.tsx`
Line ~275: `<Field label="Schedule" value={job.schedule || '—'} />` →
`<Field label="Days off" value={job.daysOff || '—'} />`.

**Admin note (intentional deferral):** the new `rolesOther` custom text is a NEW
field, and the scope forbids new admin UI, so it is NOT surfaced in the admin
panel this phase. `rolesNeeded` continues to render via `listOr(job.rolesNeeded)`.
Flag as a possible future admin enhancement.

---

## 4. Work units & parallelization

Two lanes: the Flutter lane (A→B→C, sequential — later units depend on earlier
types/widgets) and the admin lane (D, independent codebase, fully parallel).

- **WU-A — Foundation (Flutter data layer).** `emirate_ui.dart` (CREATE),
  `family_constants.dart`, `job_post_model.dart`, `firestore_job_service.dart`,
  `app_strings.dart` + `en_us.dart` + `ar_ae.dart`. SEQUENTIAL — first; B and C
  depend on it. No dependency on D.
- **WU-B — State + shared widgets.** `family_profile_controller.dart`,
  `family_job_selectors.dart` (CREATE). SEQUENTIAL after A.
- **WU-C — Screens + display.** `family_form_screen.dart`,
  `family_edit_screen.dart`, `job_detail_screen.dart`, `my_jobs_screen.dart`.
  SEQUENTIAL after B.
- **WU-D — Admin panel.** `admin-panel/src/services/firestore.ts`,
  `FamilyDetail.tsx`, `TrialDetail.tsx`. INDEPENDENT — no file overlap with A/B/C;
  may be built in parallel from the start.

Recommended: one developer runs A→B→C; D can be the same developer at the end or a
parallel background developer in the same worktree (no file overlap with the
Flutter files). Given the small size, a single developer doing A→B→C→D is fine.

---

## 5. Refactor callouts

The only consolidation required is the duplicated role chip UI
(`_roleJobType()` in the form and `_roleSection()` in the edit screen), plus the
newly-duplicated emirate and days-off selectors — all collapsed into the three
shared widgets in `family_job_selectors.dart`. This is the scope's explicit
no-duplication requirement, executed once. No broader refactor is warranted; the
family controller/screen structure is otherwise sound.

---

## 6. Test plan

No unit tests exist for the family controller today; keep the code structured so
it *could* be tested (pure `emirate_ui` helpers, controller logic unchanged in
shape). The review will exercise:

1. `cd kafi_app && flutter analyze` — must pass (0 errors; new files + renames
   compile, no dangling `schedule`/`city.value`/`detectingCity`/`scheduleCtrl`
   references).
2. `cd admin-panel && npx tsc -b && npx vite build` — must pass (no `job.schedule`
   references remain; `daysOff` typed).
3. Manual/logic trace (mock mode):
   - Job-post form: emirate chips show exactly the 7 real emirates (no Al Ain);
     single-select; submitting with none selected → `familyCityRequired`.
   - Languages chips show the 8-item list incl. Tagalog + Russian + Other;
     multi-select; Other selects with no extra field.
   - Role chips show the 11-item list; multi-select; selecting "Other" reveals the
     "Please specify the role you are looking for" field; submitting with Other
     selected but the field blank → `familyRoleOtherRequired`; deselecting Other
     hides the field.
   - Days-off shows 1/2/Other single-select, no elaboration for Other; submitting
     with none → `familyDaysOffRequired`.
   - Save → reopen edit screen: emirate, languages, roles (+ Other text), days-off
     all re-hydrate correctly; a legacy free-text city hydrates to no selection
     (not a crash); a legacy free-text schedule hydrates to no days-off selection.
   - Nanny job-detail shows "Days off: <value>"; admin FamilyDetail/TrialDetail
     show the "Days off" field.
4. Grep gate (should return nothing in edited files): `job.schedule`,
   `controller.city`, `scheduleCtrl`, `detectingCity`, `KafiLocationPicker` in the
   two family screens.

---

## 7. Definition of done (gradable checklist)

- [ ] No `KafiLocationPicker`/GPS/`autoDetectCity`/`LocationService`/`detectingCity`
      reachable from the family city field (form + edit) or the controller.
- [ ] Family location is a single-select of the 7 real emirates, sourced from the
      reused `Emirate` enum; persisted as a canonical label into both
      `FamilyModel.city` and `JobPostModel.city` from one controller value.
- [ ] `FamilyConstants.homeLanguages` == the 8-item list exactly (Arabic, English,
      Hindi, Urdu, Tagalog, French, Russian, Other); Other has no reveal field.
- [ ] `FamilyConstants.roles` == the 11-item list exactly; role chips are
      multi-select; "Other" reveals a required "Please specify the role you are
      looking for" text field, persisted to `JobPostModel.rolesOther`; the two
      previously-duplicated role UIs are now one shared widget.
- [ ] `JobPostModel.schedule` is gone; `JobPostModel.daysOff` replaces it; the
      form + edit screens use a 1/2/Other single-select with NO elaboration field;
      validation requires a selection.
- [ ] `job_detail_screen.dart`, `FamilyDetail.tsx`, `TrialDetail.tsx`, and the
      `JobPostRow` type + mapper + mock seeds read/display `daysOff` (label
      "Days off"), not `schedule`.
- [ ] `my_jobs_screen.dart` compiles with the schedule quick-edit removed.
- [ ] `flutter analyze` and admin `tsc -b && vite build` both pass.
- [ ] No file owned by phase 1 (nanny) or phase 3 (trial) was edited; `Emirate`
      is imported, never redefined; `Emirate.alAin` is never referenced.
