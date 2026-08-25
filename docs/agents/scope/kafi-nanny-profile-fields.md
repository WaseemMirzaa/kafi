---
slug: kafi-nanny-profile-fields
project: kafi
title: Nanny profile — languages, emirate-only location, employment type + part-time availability, restructured work experience, drop emergency contact
owner: project-manager
status: READY_FOR_ARCH
updated: 2026-08-15
epic: kafi-profile-trial-overhaul (phase 1 of 3 — parallel with kafi-family-profile-fields and kafi-trial-completion-flow)
---

## Requirements (verbatim from Waseem)

**Languages Spoken** — allow multiple selections: English, Arabic,
Filipino/Tagalog, Bahasa Indonesia, Hindi, Urdu, Bengali, Amharic, Oromo,
Swahili, Punjabi, Malayalam, Other. If Other is selected, do not request
additional information.

**Current Location** — remove Google Maps, GPS, map pins, and exact-address
requirements. Ask "Which emirate do you currently live in?" Single selection
from the 7 emirates (Abu Dhabi, Dubai, Sharjah, Ajman, Umm Al Quwain, Ras Al
Khaimah, Fujairah).

**Preferred Job Location** — ask "In which emirates are you looking for a
job?" Multiple selections from the 7 emirates + "Any Emirate". Selecting "Any
Emirate" auto-includes all 7.

**Preferred Employment Type** — new section: "What type of job are you
looking for?" Multiple selections: Full-Time — Live-In, Full-Time — Live-Out,
Part-Time.

**Part-Time Availability** — shown only if Part-Time is selected. Ask "Which
days are you available?" Multi-select Mon–Sun. For every selected day, require
Available-from and Available-until times, independently per day. A part-time
profile can't be completed without at least one day + time set.

**Work Experience** — when adding a previous job, ask for: Country, City or
location (plain text field, no maps/GPS/pins/exact-address), Job role, Start
date, End date, Main responsibilities.

**Bio** — remove the Emergency Contact section completely; keep only Bio
("Tell families a little about yourself" — keep it short, she also has an
intro video).

**General** — no GPS/maps/exact-address anywhere in the nanny profile; keep
questions simple; preserve existing account/profile data across
available↔hired/hidden status changes (that transition itself is phase 3's
concern, not this phase's — just don't design anything here that would lose
data on a status flip).

## Current state (investigated; verify before planning — line numbers may drift)

All paths relative to `kafi_app/`.

- **`lib/models/nanny_model.dart`**: `Emirate` enum (line 6) currently has 8
  values incl. `alAin` — **per the epic doc, fix to the real 7** (drop
  `alAin`; any nanny doc holding it remaps to `abuDhabi`). `languages`
  (`List<String>`, line 258). `currentArea` (`String`, line 265) +
  `currentLocation` (`GeoLocation?`, line 269) — hybrid GPS+text, **replace
  with a single `Emirate` value**, drop the GPS side. `workEmirates`
  (`List<Emirate>`, line 263) — already the closest analog to "Preferred Job
  Location"; extend with an "Any Emirate" UX affordance that writes all 7.
  `jobTypePreference` (`JobTypePreference` enum `{liveIn, liveOut, both}`,
  line 270) — already covers live-in/live-out; **no** full-time/part-time
  field exists anywhere on this model today — net new. `experiences`
  (`List<WorkExperience>`, line 302). `bio` (`String`, line 299). Emergency
  contact: `emergencyName`, `emergencyRelationship`, `emergencyCountryCode`,
  `emergencyPhone` (lines 295–298) — remove.
- **`WorkExperience`** (`lib/models/nanny_model.dart:22-62`): current shape is
  `jobTitle` (dropdown from `NannyConstants.jobTitles`), `employer`,
  `cityCountry` (**single combined free-text field**, not separate
  country/city), `fromDate`/`toDate`, `children`, `duties` (maps to "main
  responsibilities"), `reasonLeaving`, `location` (`GeoLocation?`, captured
  alongside `cityCountry` via the map picker). Needs: split `cityCountry` into
  a `country` field + a plain-text `city` field (drop the GPS `location`
  entirely). Keep `jobTitle` as "Job role" (dropdown is fine — spec doesn't
  say free text). Keep `children`/`reasonLeaving`/`duties` — spec's field list
  is additive ("ask for at least this"), not exhaustive-exclusive; nothing in
  the requirements says remove them.
- **UI**: `lib/views/nanny/nanny_info_screen.dart` — `_workLocation()`
  (~lines 320–384, current-area picker + the existing 8-box emirate grid for
  `workEmirates`) and `_emergency()` + `_bio()` (~lines 612–691, back-to-back
  in the same step-1 screen — remove `_emergency()`, keep `_bio()`). Employment
  type + part-time availability are net-new UI in this screen (or a new
  section within it — architect's call on placement/step count, but note
  `NannyConstants.totalSteps = 6` and the step-progress header may need
  adjusting if a new step is added instead of a new section in an existing
  step).
- **`lib/views/nanny/nanny_exp_screen.dart`** (~lines 270–302): work-experience
  entry form — replace the `KafiLocationPicker` city/country field with plain
  text field(s) per the split above.
- **`lib/views/nanny/nanny_edit_profile_screen.dart`**: post-approval
  edit-profile screen ("Screen 27A") — has its OWN emergency-contact section
  (~lines 81–102, remove) and its OWN separate, **inconsistent**, hardcoded
  language list (~lines 43–49: `['English','Arabic','French','Hindi','Tagalog','Amharic']`,
  missing Urdu/Swahili, spells "Arabic" differently than the onboarding list) —
  consolidate to one canonical language list (the new 12-language + Other list
  above) used by **both** this screen and onboarding.
- **`lib/utils/constants/nanny_constants.dart`**: `languages` (lines 51–54,
  only 8 generic entries) — replace with the canonical 12 + Other list from the
  requirements. `nationalities`, `jobTitles`, `reasonsLeaving`,
  `referenceRelations` are unaffected — leave as-is.
- **`KafiLocationPicker`** (`lib/views/widgets/kafi_location_picker.dart`) is
  used at 3 nanny sites: `nanny_info_screen.dart:375` (current area — **in
  scope, remove**), `nanny_exp_screen.dart:280` (work-experience city — **in
  scope, remove**), `nanny_refs_screen.dart:393` (reference's city — **out of
  scope, leave untouched**, per epic doc).
- **Onboarding completion**: `hasPersonalInfo` getter
  (`nanny_model.dart:364-370`) checks `fullName`, `dateOfBirth`, `visaStatus`,
  `workEmirates`, `currentArea`, `bio` — **does not check emergency-contact
  fields**, so removing them doesn't break completeness. It *does* check
  `currentArea` (a `String`) — since current-location becomes an `Emirate`,
  update this getter's check accordingly (e.g. non-null emirate). Decide
  whether/how completeness should also require an employment-type selection
  and (if Part-Time is chosen) at least one part-time day+time — the
  requirements say a part-time profile can't be completed without this;
  reflect that in whatever validation gates step progression.
- **Matching**: `lib/services/match_service.dart` reads `nanny.languages`
  (`_languageScore`, ~line 70) and (per the family-phase scope doc)
  `nanny.workEmirates` for location scoring (`_locationScore`, ~line 60,
  currently compares `enum.name` against a free-text `job.city` — will need to
  compare against the family phase's new emirate field instead; coordinate but
  do not edit `match_service.dart` here if the family phase's plan already
  claims it — check for collision first, since both phases touch nanny↔job
  matching. If only nanny-side enum values changed (8→7, dropping `alAin`) and
  the comparison shape is untouched, no edit is needed here).
- **`lib/models/nanny_map_codec.dart`**: `_experienceFromMap` (~lines 27–38)
  parses `WorkExperience` from Firestore — update for the field-shape change.

## Explicit scope boundaries

**In scope**: `NannyModel`, `WorkExperience`, `Emirate` enum,
`NannyConstants.languages`, `nanny_map_codec.dart`, `nanny_info_screen.dart`,
`nanny_exp_screen.dart`, `nanny_edit_profile_screen.dart`,
`nanny_profile_controller.dart` (validation + persistence for all of the
above), any new part-time-availability model/widget this requires.

**Out of scope** (do not touch): `nanny_refs_screen.dart`'s location picker,
`trial_offer_screen.dart`, anything in `functions/` or `admin-panel/` (if the
admin panel displays any of these changed fields and breaks, note it in the
build doc for a follow-up — do not silently expand scope), the family side
(phase 2), the trial-completion flow (phase 3).

## Acceptance criteria

- No `KafiLocationPicker`/GPS/Geolocator/Google Places call remains reachable
  from the nanny's current-location or work-experience-city fields.
- Emirate lists (current location single-select, preferred job location
  multi-select incl. "Any Emirate") show exactly the 7 real emirates, nowhere
  showing "Al Ain" as a distinct option.
- Any existing nanny doc with `Emirate.alAin` reads back as `abuDhabi` (verify
  the architect's chosen mechanism — codec-level remap or migration script —
  actually covers this).
- Employment-type section (Full-Time Live-In / Full-Time Live-Out / Part-Time,
  multi-select) exists and persists.
- Part-time availability section appears only when Part-Time is selected;
  each selected day has independent from/until times; a part-time selection
  with zero days+times blocks profile completion.
- Work-experience entries collect Country, City (plain text), Job role, Start
  date, End date, Main responsibilities — no map/GPS anywhere in that form.
- Emergency Contact section is gone from both onboarding (`nanny_info_screen`)
  and edit-profile (`nanny_edit_profile_screen`); Bio remains, unaffected.
  Removing it does not corrupt `hasPersonalInfo`/onboarding routing for
  existing drafts.
- Exactly one canonical language list (12 + Other), used identically by
  onboarding and edit-profile — the old 3-way inconsistency is gone.
- `flutter analyze` (CI) passes; existing tests touching `NannyModel`/
  `WorkExperience`/onboarding routing still pass or are updated to match the
  new shape.
