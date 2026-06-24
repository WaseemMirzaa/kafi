---
slug: mobile-auth-onboarding-backend
project: kafi_app (Flutter mobile)
title: Firebase phone auth + spec-complete onboarding validation (both roles)
owner: developer
status: BUILT (partial — UI-polish follow-ups listed)
updated: 2026-06-21
branch: claude/quirky-goldberg-7jxx5a
commits: f28a2ed (auth) · 394f54c (nanny) · 16cec01 (family)
---

# Build note — Mobile auth + onboarding backend

## What shipped

### Phase 0 — Foundation
- `AppConfig.useMock = false` → live Firebase by default; `environment = 'prod'`.
- `AuthConstants.otpLength` 4 → **6** (Firebase SMS codes); mock OTP → `123456`.
  Propagates to `KafiOtpBoxes` and the password-reset screen automatically.
- New `lib/utils/validators.dart` — `phone`, `contactPhone`, `dateOfBirth`
  (age ≥ 18, no future date), `salaryRange`, `required`, `nonEmptyList`. Each
  returns an **l10n key** (or null), mapped to System Spec §14.1 / §14.4.
- `kafi_app/FIREBASE_SETUP.md` — config files, Phone Auth, SHA/APNs, rules deploy.
- New EN + AR l10n keys for every auth/validation message added this build.

### Phase 1 — Auth (Firebase phone)
- `AuthController`: validates phone format pre-send; maps `FirebaseAuthException`
  codes → localized §14.1 messages (`_authErrorMessage`); gates the mock-OTP
  snackbar behind `useMock` (live shows a neutral "code sent"); inline
  `phoneError` / `otpError` Rx state; removed the dev-prefilled phone number.
- Login (nanny + family) + OTP screens: inline error display, full §1.5 country
  code lists, localized remaining literals (terms row, learn-more, resend, etc.).
- `MockAuthService.loginWithPassword` now persists the session (restart bug).

### Phase 2 — Nanny onboarding
- Cleared presumptive demo defaults (languages/emirates/visa/marital) so a new
  nanny must actively choose them (they were saved verbatim before).
- `_validatePersonalInfo()` enforces §3.2 required fields with localized
  first-error messages (nationality, visa, marital, children-count, emergency
  name/relationship/phone, bio).
- Wired the previously-dead "comfortable with different faith" toggle to a real
  persisted field (`comfortableWithDifferentFaith`).
- Localized the hardcoded nanny-info section labels.

### Phase 3 — Family onboarding
- `_validateFamily()` enforces §3.3 + §3.4 required fields with localized
  messages: nationality, children-ages (when children > 0), home languages,
  roles, schedule, duties, benefits, salary order (min ≤ max), trial
  duration > 0, trial daily rate > 0. Reasonable UAE defaults retained.

### Phase 4 — DOB picker + nanny work preferences (was F1 / F2)
- Real **date picker** on the nanny DOB field (tappable via GestureDetector +
  AbsorbPointer; `firstDate`/`lastDate` enforce ages 18–70), wired to `dob.value`
  with a live computed age; dropped the hardcoded `1992-03-14` default. DOB is
  now strictly required (age ≥ 18).
- New **Work preferences** section on the nanny info screen: expected salary
  min/max, job-type preference (live-in / live-out / both), and availability
  (now / from a date — with its own date picker). Persisted to the model and
  validated (salary min ≤ max via Validators; start date required when
  "from a date"). 6 new EN+AR l10n keys.

### Phase 5 — City auto-detect + location picker (family form)
- `LocationService` implemented for real (Geolocator permission + GPS +
  `PlacesService.reverseGeocode`); `PlaceDetails` now parses city/emirate from
  Google address components.
- Family **"City / Emirate" auto-detects on load** (requests location
  permission) with a "Detecting…" state; cleared the presumptive `'Dubai'`
  default. Falls back to manual entry when no Maps key.
- `KafiLocationPicker` now reflects externally-set values (`didUpdateWidget`)
  and shows an explicit **"Change"** affordance. Its Uber-style map + Places
  autocomplete + "use current location" already existed.
- Platform location usage was already declared (Android `ACCESS_FINE/COARSE`,
  iOS `NSLocation*`); the Google Maps key remains a placeholder in 3 files —
  documented in `FIREBASE_SETUP.md`.

## Key discoveries (the production audit was stale)
- Pickers (`image_picker`/`file_picker`) are already wired with real bytes;
  16 Android permissions present; `firebase_options.dart` present; mock OTP no
  longer rendered in the OTP UI. Those audit blockers are resolved.
- **DOB field had no date picker** — `dob.value` was hardcoded to `1992-03-14`
  for every nanny. **Fixed in Phase 4** (real picker + strict age ≥ 18).
- Nanny `willingToTransferVisa == null` legitimately means "Depends" (not unset),
  so it is intentionally not required-validated.

## Deferred (need a compile/test loop — no Flutter toolchain in this env)
- **F1 — DONE (Phase 4)** DOB date picker + strict age ≥ 18; hardcoded default cleared.
- **F2 — DONE (Phase 4)** Nanny work-preferences UI (salary / availability /
  job type) added and enforced.
- **F3** Per-field **inline** error placement on the onboarding screens (current
  onboarding errors surface as a localized snackbar of the first failure).
- **F4** Validation for the nanny experience (≥1 complete entry, §14.4 V11) and
  references (complete details when declared, V12) steps + their screen labels.
- **F5** Localize remaining inline toggle micro-labels and the family-form field
  labels (auth + nanny-info section labels + all error messages are done).
- **F6** Wire the docs-screen "No EID" button and the emergency country-code
  picker (currently no-ops).

## Verification (run locally — could not compile here)
1. `cd kafi_app && fvm flutter pub get`
2. `fvm flutter analyze` (expect clean; this build is static-only).
3. Mock smoke test: set `AppConfig.useMock = true`, `fvm flutter run`; OTP `123456`.
4. Live: add `google-services.json` / `GoogleService-Info.plist`, enable Phone
   Auth, `fvm flutter run`; verify real 6-digit SMS, invalid-number + wrong-code
   localized errors, and that onboarding blocks until required fields are filled.
