---
slug: mobile-auth-onboarding-backend
project: kafi_app (Flutter mobile)
title: Backend integration — Firebase phone auth, session, and spec-complete onboarding validation (both roles)
owner: architect
status: IN_PROGRESS (Phases 0–3 built; see builds/ note for deferred UI items)
updated: 2026-06-21
branch: claude/quirky-goldberg-7jxx5a
---

# Plan — Mobile auth + onboarding backend integration

## 1. Goal (from request)

1. Update the auth flow to use **Firebase phone-number auth** (activate + harden).
2. Make **all spec-mandatory fields required**, with **inline, localized error messages**.
3. Go **screen-by-screen** through onboarding (nanny ×5, family ×1) up to the home
   screen, for **both** user types.
4. Everything user-facing must be **localized via l10n** (`.tr`); Arabic added for all
   **new** keys.

## 2. Decisions (confirmed with user)

| Topic | Decision |
| ----- | -------- |
| Firebase mode | **Switch to live now** — `AppConfig.useMock = false` as default. |
| Validation strictness | **Spec-complete (strict)** — every field §3.2–3.4 marks required. |
| Arabic l10n | **Route everything through l10n**; add Arabic for all **new** keys. Backfill of pre-existing Arabic gaps is a later pass. |

## 3. Constraints / environment facts

- **No Flutter toolchain in this container** → cannot `flutter analyze`/`run`/test here.
  All changes are static and must be compiled & smoke-tested by the user (or CI).
- **No `google-services.json` / `GoogleService-Info.plist`** in repo (Firebase project
  secrets). With `useMock = false`, the app will **not run until these are added**. This
  is an accepted consequence of the "switch to live now" decision. A setup guide will be
  added (`kafi_app/FIREBASE_SETUP.md`).
- Already in place (audit was stale): `firebase_options.dart`, all `Firestore*`/`FirebaseAuthService`
  impls, 16 Android permissions, `image_picker`/`file_picker`/`video_player`,
  real picker wiring (no dummy bytes), `SessionMonitor` (auth-state + 90-day inactivity).

## 4. Spec-derived REQUIRED-field matrix (strict)

Required = field has **no `?`** in the §3.2–3.4 TS interfaces. Conditionals from §14.4.

### 4.1 Nanny — `nanny_info_screen` (§3.2 Basic/Visa/Work/Personal/Health/Prefs/Emergency)
Required: `fullName`, `dateOfBirth` (V2 age≥18, V3 not future), `nationality`, `languages` (V6 ≥1),
`visaStatus`, `hasEmiratesId`, `willingToTransferVisa`, `workEmirates` (V7 ≥1),
`willingToRelocate`, `jobTypePreference`, `expectedSalaryMin`/`expectedSalaryMax` (V8 min≤max),
`availability`, `maritalStatus`, `hasChildren` (V10: if yes → `childrenCount`≥1 + ages),
`hasHealthConditions` (+details if yes), `takesMedication` (+details if yes),
`hasAllergies` (+details if yes), `comfortableWithCameras`, `comfortableWithPets`,
`canCook`, `canDoNightShifts`, `comfortableWithDifferentFaith`,
`emergencyName`/`emergencyRelationship`/`emergencyPhone` (V4 valid phone), `bio` (V5 ≤300).
Optional: `eidNumber`, `currentArea`, `availableFrom`, `childrenAges` (unless hasChildren),
`cameraNote`, `petTypes`, `cuisines`, `religion`, `religiousNotes`.

> **UI gap to resolve:** `expectedSalaryMin/Max`, `availability`, `jobTypePreference` are
> spec-required but have **no input** in onboarding today (model defaults only).
> **Plan default:** add a compact "Work preferences" subsection to `nanny_info_screen`
> (salary range AED + availability + live-in/out/both) so the required rule is satisfiable.
> *(Flag: this adds 3 inputs the user didn't name. Veto → we instead keep them optional.)*

### 4.2 Nanny — `nanny_media_screen`
Required: ≥1 photo (V/F10, already enforced). Optional: `introVideo`.

### 4.3 Nanny — `nanny_exp_screen`
Required: **≥1 work experience** (V11), and each added entry must have `jobTitle`,
`employer`, `cityCountry`, `fromDate`, `toDate` (to ≥ from), `children`, `duties`,
`reasonLeaving` complete (currently 0 enforcement).

### 4.4 Nanny — `nanny_refs_screen`
`hasReferences` required (bool). If `hasReferences == true` → **≥1 reference** with
`relationship`, `city`, `yearsWorked`(>0), `canConfirm` complete (V12). Commitment
checkbox required when references declared.

### 4.5 Nanny — `nanny_docs_screen`
Required: `passport`, `visa` uploaded (F11, already enforced). `eid` conditional on
`hasEmiratesId` (wire the dead "No EID" button). Optional: training cert, police clearance.

### 4.6 Family — `family_form_screen` (§3.3 Family + §3.4 Job Post)
Family required: `fullName`, `nationality`, `city`, `languagesAtHome` (≥1), `hasCameras`,
`hasPets`, `numberOfChildren`, `childrenAges` (V10), `hasSpecialNeedsChild`,
`nannyReligionPreference`.
Job required: `jobTitle`, `rolesNeeded` (≥1), `jobType`, `schedule`, `startDate`,
`duration`, `experienceYears`, `languagesRequired` (≥1), `skillsRequired`/`duties` (≥1),
`salaryMin`/`salaryMax` (V8 min≤max), `benefits` (≥1), `visaSponsorshipType`,
`trialDuration` (V14 >0), `trialDailyRate` (V13 >0).
Optional: `petTypes`, `specialNeedsDetails`, `religion`, `houseRules`, `contractMonths`,
`languagesPreferred`, `nationalityPreference`, `additionalNotes`.

## 5. Error / validation message catalogue → l10n keys

New keys (EN + AR) covering §14.4 V1–V15 and the §14.1 auth set we surface:
`valRequired` ("This field is required"), `valAgeMin18`, `valDobInvalid`, `valPhoneInvalid`,
`valBioMax`, `valLangMin1`, `valEmirateMin1`, `valSalaryOrder`, `valChildAgeMin1`,
`valExpMin1`, `valRefIncomplete`, `valTrialRateZero`, `valTrialDurationZero`,
`valRolesMin1`, `valDutiesMin1`, `valBenefitsMin1`, `valSkillsMin1`,
`valSchedule`, `valYearsExp`, plus auth: `authPhoneInvalid`, `authNoAccount`,
`authAccountExists`, `authWrongRole`, `authOtpSendFailed`, `authOtpRateLimited`,
`authOtpExpired`, `authOtpIncorrect`, `authOtpMaxAttempts`, `authNetwork`,
`authQuotaExceeded`, `authPasswordWeak`, `authPasswordsMismatch`, `authWrongPassword`,
`authReauthRequired`. Existing keys reused where present (`phoneRequired`, `errorTitle`,
`authInvalidOtp`, `familyNameRequired`, `familyCityRequired`, etc.).

All currently-hardcoded labels found in screens (e.g. "Any health conditions?",
"Home cameras?", "Role(s) needed", "Reason for leaving", emergency country picker, etc.)
get keys + `.tr` wiring.

## 6. Work breakdown (phased; commit per phase)

**Phase 0 — Foundation**
- `config/app_config.dart`: `useMock = false`.
- Add `kafi_app/FIREBASE_SETUP.md` (config files, Phone Auth enable, SHA keys, APNs).
- Add `utils/validators.dart` — pure functions returning **l10n keys** (phone by country
  per §1.5, DOB/age, salary order, generic required, etc.).
- Add all new l10n keys to `app_strings.dart` + values to `en_us.dart` + Arabic to `ar_ae.dart`.

**Phase 1 — Auth (Firebase phone)**
- `auth_controller.dart`: real phone-format validation pre-send; remove dev-prefilled
  `'50 234 5678'`; gate the mock-OTP snackbar body behind `useMock`; map
  `FirebaseAuthException` codes → localized A-series messages; surface inline errors
  (Rx error strings) instead of generic `e.toString()`.
- `login_nanny_screen.dart` / `login_family_screen.dart`: inline field error display + country
  code list per §1.5.
- `otp_verify_screen.dart`: localized invalid/expired/attempts messaging.
- `mock_auth_service.dart`: persist `loginWithPassword` session (restart-survival bug).
- Confirm `_restoreSession()` / `SessionMonitor` cover live persistence (FirebaseAuth auto-persists).

**Phase 2 — Nanny onboarding (5 screens + controller)**
- `nanny_profile_controller.dart`: per-screen validators returning localized errors;
  enforce 4.1–4.5 matrix; wire dead toggles (comfort-different-faith, emergency country
  code, "No EID"); add Work-preferences inputs (salary/availability/jobType) if not vetoed.
- The 5 screens: inline error UI under fields; localize all hardcoded labels.

**Phase 3 — Family onboarding (form + controller)**
- `family_profile_controller.dart`: enforce 4.6 matrix; salary min≤max; trial rate/duration>0;
  children-ages when numberOfChildren>0.
- `family_form_screen.dart`: inline errors; localize hardcoded labels.

**Phase 4 — Wrap-up**
- Update `KAFI_PRODUCTION_READINESS_AUDIT.md` (stale items) + short build note under
  `docs/agents/builds/`.
- List manual verification steps (since no toolchain here).

## 7. Risks / divergences to confirm during review

- **R1 (spec vs code):** §6.1/6.2 include a *Create Password* step, but current code is
  **phone-only** (`skipPassword: true`) by deliberate design. Plan **preserves phone-only**
  (keeps password login/reset working & localized). Reintroducing mandatory password = veto.
- **R2:** Adding salary/availability/jobType inputs to nanny onboarding (4.1 UI gap).
- **R3:** Strict validation lengthens forms; users with incomplete drafts can't advance.
  Mitigated by clear inline errors + keeping the "save draft / edit later" paths intact.
- **R4:** Cannot compile here → user must run `flutter analyze` + `flutter run` (mock first
  by flipping flag back, then live with config files) to verify.

## 8. Acceptance criteria

- [ ] `useMock=false`; setup guide present; app path documented.
- [ ] Phone auth: invalid numbers blocked pre-send with localized error; Firebase error
      codes mapped to A-series messages; no mock OTP shown in live mode; no dev-prefilled number.
- [ ] Every required field in §4 enforced with an **inline localized** message; advancing is
      blocked until valid; optional fields still optional.
- [ ] No hardcoded user-facing literals remain in the touched auth/onboarding screens; new
      keys exist in both `en_us` and `ar_ae`.
- [ ] Both flows reach their home screen only after their required set is satisfied.
