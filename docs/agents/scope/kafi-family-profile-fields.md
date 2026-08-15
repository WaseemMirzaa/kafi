---
slug: kafi-family-profile-fields
project: kafi
title: Family profile — emirate-only location, expanded languages, multi-select role with "Other", days-off replacing free-text schedule
owner: project-manager
status: READY_FOR_ARCH
updated: 2026-08-15
epic: kafi-profile-trial-overhaul (phase 2 of 3 — parallel with kafi-nanny-profile-fields and kafi-trial-completion-flow)
---

## Requirements (verbatim from Waseem)

**Family Location** — remove Google Maps, GPS location, map pins, and
exact-address requirements. Ask "Select your emirate:" — single selection from
the 7 emirates (Abu Dhabi, Dubai, Sharjah, Ajman, Umm Al Quwain, Ras Al
Khaimah, Fujairah).

**Languages Spoken at Home** — allow multiple selections: Arabic, English,
Hindi, Urdu, Tagalog, French, Russian, Other. If Other is selected, do not
request additional information.

**Required Role** — ask "What type of help are you looking for?" Multiple
selections: Maid & Nanny, Nanny, Maid, Babysitter, Mother's Helper, Child
Caregiver, Elderly Caregiver, Cook, Household Helper, Pet Caregiver, Other.
Only for this section, selecting Other opens a text field: "Please specify the
role you are looking for."

**Days Off** — remove the Working Days field. Replace with "How many days off
will you provide each week?" Options: 1 day off, 2 days off, Other. If Other
is selected, do not show an additional field (single-select, no elaboration
even for Other — this differs from the Required Role "Other", which does get
a text field).

**General** — no GPS/maps/exact-address anywhere these fields touch; keep
questions simple.

## Current state (investigated; verify before planning — line numbers may drift)

All paths relative to `kafi_app/` unless noted.

- **Location is split across two models**, kept in sync manually, not
  derived: `FamilyModel.city` (`lib/models/family_model.dart:200`, plain
  `String`) and `JobPostModel.city` (`lib/models/job_post_model.dart:87`,
  separate plain `String`) — both written from the same
  `FamilyProfileController.city` (`Rx<String>`) in `_persist()`
  (`lib/controllers/family_profile_controller.dart:257,295`). Both need to
  become the 7-emirate value (single-select), same enum the nanny phase is
  fixing on `NannyModel` (`Emirate` in `nanny_model.dart:6`, now 7 values —
  reuse that enum rather than defining a second one; if it doesn't already
  live somewhere shared/importable by both models, consider whether it should
  move to a shared location — flag in the plan if this creates an
  import-direction problem between family/nanny model files).
- **`KafiLocationPicker` family call sites** (all 3, remove all 3): job-post
  create (`lib/views/family/family_form_screen.dart:163`), profile edit
  (`lib/views/family/family_edit_screen.dart:132`), both bound to
  `controller.city`. The **third** site,
  `lib/views/family/trial_offer_screen.dart:278`, is a **different field**
  (trial logistics location, bound to `controller.location`, not
  `controller.city`) — **out of scope, do not touch** (see epic doc).
  `FamilyProfileController.autoDetectCity()`
  (`family_profile_controller.dart:154-166`, GPS auto-prefill on first load)
  should be removed/no longer called once `city` is emirate-typed.
- **`FamilyConstants`** (`lib/utils/constants/family_constants.dart`, 20
  lines total — the whole file):
  - `homeLanguages` (line 3, 6 entries, no Other, "Filipino" not "Tagalog", no
    Russian) — replace wholesale with the requirements' 8-item list (Arabic,
    English, Hindi, Urdu, Tagalog, French, Russian, Other).
  - `roles` (lines 5–7, 7 entries, no Other) — replace wholesale with the
    requirements' 11-item list (…, Other). Bound as a chip `Wrap` **twice**,
    independently implemented, in `family_form_screen.dart:415-423`
    (`_roleJobType()`) and `family_edit_screen.dart:191-200`
    (`_roleSection()`) — per the team's no-duplication bar, consolidate into
    one shared widget/method both screens call, while adding this phase's new
    "Other reveals a text field" behavior once instead of twice.
  - No existing "select Other → reveal text field" component exists anywhere
    in the app to reuse (checked: nationality picker's "Other" is a plain
    catch-all string with no elaboration; family/nanny religion chips' "Other"
    doesn't reveal a field either — nanny's religion screen reuses one shared
    text controller as a hack, not a real pattern). This phase is building
    that pattern for the first time — keep it small and reusable (a family
    that later needs it again — e.g. NannyConstants.nationalities already ends
    in a bare "Other" with no field — shouldn't be blocked from adopting it,
    but that's not this phase's job to retrofit).
- **Days off replaces `JobPostModel.schedule`**
  (`lib/models/job_post_model.dart:64`, free-text `String`, currently
  required — `family_profile_controller.dart:221`). Bound via
  `scheduleCtrl` (`family_profile_controller.dart:51`) in both
  `family_form_screen.dart:477-482` and `family_edit_screen.dart:263-267`.
  This field is **displayed downstream** and needs its display sites updated
  to the new days-off value, not just the input form:
  - `lib/views/nanny/job_detail_screen.dart:146-147` (nanny-facing job detail,
    `_detailRow('Schedule', job.schedule...)`).
  - Admin panel: `admin-panel/src/pages/families/FamilyDetail.tsx:48-64`
    (inline `JobPostCard`, `Field label="Schedule" value={job.schedule}`) and
    `admin-panel/src/pages/trials/TrialDetail.tsx:292`. TS shape:
    `admin-panel/src/services/firestore.ts:201` (`schedule?: string` on
    `JobPostRow`) plus mock seed rows (~lines 561–605) — these are
    **admin-panel/**, technically a different codebase; update the display
    labels/type to read the new field, but this phase does not need to build
    any new admin UI for it (plain text rendering of whatever the new value
    is, e.g. "2 days off").
  - `schedule` is **not** used in `match_service.dart` today (confirmed absent
    from the 11 weighted dimensions) — no matching-logic change forced by this
    swap, though the architect may decide it's worth adding as a future
    signal (not required for this phase).
- **Languages-at-home matching**: `match_service.dart:_languageScore`
  (~line 70) falls back to `family.languagesAtHome` only when
  `job.languagesRequired` is empty — this fallback wiring is unaffected by
  swapping the constant list's values, no code change needed there beyond the
  constants swap itself.
- **Role field lives on `JobPostModel.rolesNeeded`**
  (`lib/models/job_post_model.dart:62`, `List<String>`), not on `FamilyModel`
  — despite the requirement being titled "Family Profile Changes", the actual
  UI is the job-post form/edit screens (there is no separate stand-alone
  "family profile" screen with its own role field) — apply the change there.

## Explicit scope boundaries

**In scope**: `FamilyModel.city`, `JobPostModel.city`, `JobPostModel.schedule`
(→ days-off), `JobPostModel.rolesNeeded` (+ "Other" free text — needs a new
model field to hold the custom text, e.g. `rolesOther` or similar),
`FamilyConstants` (all of it except `duties`/`benefits`/`trialDurations`,
unaffected), `family_form_screen.dart`, `family_edit_screen.dart`,
`family_profile_controller.dart`, downstream display sites listed above
(`job_detail_screen.dart` + the two named admin-panel files/types — display
only, not new admin UI).

**Out of scope** (do not touch): `trial_offer_screen.dart`'s location field,
anything in `functions/` (no Cloud Function reads/writes these family fields
today per the investigation — verify this holds before assuming no backend
change is needed), the nanny side (phase 1), the trial-completion flow
(phase 3). Do not build new admin-panel UI beyond fixing display labels/types
for the renamed/reshaped fields.

## Acceptance criteria

- No `KafiLocationPicker`/GPS call remains reachable from the family's city
  field (job-post form and profile-edit screen) or from
  `autoDetectCity()`/`LocationService` on the family side.
- Family location is a single-select from the 7 real emirates, same enum
  values as the (now-fixed) nanny `Emirate` enum.
- Languages-at-home chip list matches the 8-item requirements list exactly
  (incl. Russian, "Tagalog" not "Filipino"), Other has no elaboration field.
- Required-role chip list matches the 11-item requirements list exactly,
  multi-select, "Other" reveals a required text field ("Please specify the
  role you are looking for") only when selected; the two previously-duplicated
  chip implementations are now one shared component.
- Schedule/working-days free-text field is gone from both the job-post form
  and edit screen, replaced by the 1/2/Other days-off single-select with no
  elaboration field even for Other.
- `job_detail_screen.dart` (nanny-facing) and the two named admin-panel files
  display the new days-off value instead of the old free-text schedule.
- `flutter analyze` (CI) and the admin-panel `tsc -b && vite build` both pass.
