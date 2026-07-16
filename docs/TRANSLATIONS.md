# Translation-aware app data

Kafi is a bilingual **English/Arabic** app. Static UI strings are handled by the
in-app localization (`AppStrings` / `AppTranslations`). This document covers
**user-generated free-text content** — nanny bios, family "about" text, job
notes, etc. — which is entered in one language but must be readable in the other.

## Schema convention

Each translatable field `X` keeps its original value **and** a sibling map
`X_i18n` keyed by language code:

```jsonc
// nannies/{id}
{
  "bio": "Loves kids and cooking",           // original (source of truth)
  "bio_i18n": {                               // maintained by Cloud Functions
    "en": "Loves kids and cooking",
    "ar": "تحب الأطفال والطبخ"
  }
}
```

The original field is untouched, so this is **backward compatible** — old readers
keep working; new readers prefer `X_i18n[locale]` and fall back to `X`.

### Translatable fields

| Collection | Fields |
|------------|--------|
| `nannies`  | `bio`, `healthConditions`, `religiousNotes` |
| `families` | `aboutFamily`, `houseRules` |
| `jobs`     | `jobTitle`, `schedule`, `additionalNotes` |

(Configured in `functions/src/utils/translate.ts`; add a field to the relevant
`*_TX` list to make it translation-aware.)

## How translations stay in sync (Cloud Functions)

`functions/src/triggers/translate.ts` registers `onDocumentWritten` triggers for
`nannies`, `families`, and `jobs`. On every **create and edit**:

1. For each configured field, if the source text changed (or its `_i18n` map is
   missing/incomplete), it is (re)translated into all app languages via the
   **Google Cloud Translation API**.
2. The `_i18n` maps are written back with `merge: true`.

The write-back is **loop-safe**: when only the `_i18n` maps change, the source
text is unchanged and the maps are complete, so `computeTranslationUpdates`
returns nothing and the trigger stops (covered by `functions/test/translate.test.js`).

## One-time setup to deploy this

1. **Enable the API** in the Firebase/GCP project:
   `gcloud services enable translate.googleapis.com` (or Console → APIs & Services).
2. **Grant the Functions runtime service account** the Cloud Translation user
   role (uses Application Default Credentials — no API key in code):
   `roles/cloudtranslate.user` on the project.
3. Deploy: `firebase deploy --only functions`.

> Cost note: Cloud Translation bills per character. Because translation only runs
> when the source text actually changes, steady-state edits are cheap; a bulk
> backfill of existing docs would incur a one-off cost.

## Client usage

`kafi_app/lib/utils/localized_text.dart` exposes `localize(original, i18n, [lang])`
— returns the current-locale translation, falling back to the original.

Models parse the `_i18n` maps into an `i18n` field and expose `localizedX()`
getters, e.g. `NannyModel`:

```dart
Text(nanny.localizedBio());          // current app locale
Text(nanny.localizedBio('ar'));      // explicit language
```

`toMap()` never serializes the `_i18n` maps — they are **server-owned** (written
only by the translate functions), exactly like the admin review fields.

## Rollout status

- ✅ Server: all fields above are translated on write (nannies/families/jobs).
- ✅ Client: `localize()` helper + parse + `localizedX()` getters on all three
  models:
  - `NannyModel` — `bio`, `healthConditions`, `religiousNotes`
  - `FamilyModel` — `aboutFamily`, `houseRules`
  - `JobPostModel` — `jobTitle`, `schedule`, `additionalNotes`
- 🔧 Follow-up: switch the display widgets to the `localizedX()` getters as those
  detail views are built. Today no view renders these free-text fields directly
  (families browse nannies via `NannyCardModel` cards), so there is no display
  site to switch yet.
