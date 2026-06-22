# Firebase Setup — Kafi Mobile App

The app now runs against **live Firebase** by default (`AppConfig.useMock = false`
in `lib/config/app_config.dart`). It will **not start** until the platform Firebase
config files below are present. To work fully offline against in-memory mock data,
flip `useMock` back to `true`.

## 1. Firebase project

Create / use a Firebase project and register an **Android** app and an **iOS** app.

## 2. Config files (NOT committed — they are project secrets)

| Platform | File | Location |
| -------- | ---- | -------- |
| Android  | `google-services.json`       | `kafi_app/android/app/google-services.json` |
| iOS      | `GoogleService-Info.plist`   | `kafi_app/ios/Runner/GoogleService-Info.plist` |

`lib/firebase_options.dart` is already present; regenerate it with
`flutterfire configure` if you use a different project.

## 3. Enable Authentication

- Firebase Console → **Authentication → Sign-in method → Phone**: enable.
- Add test numbers under Phone → *Phone numbers for testing* for QA without real SMS.
- **Android:** add your app's **SHA-1** and **SHA-256** fingerprints
  (Project Settings → Your app) — required for phone-auth reCAPTCHA / Play Integrity.
- **iOS:** upload an **APNs auth key** (Project Settings → Cloud Messaging) so phone
  auth + FCM work; ensure `Push Notifications` and `Background Modes → Remote
  notifications` capabilities are enabled in Xcode.

## 4. Firestore + Storage

- Create a **Cloud Firestore** database.
- Deploy the repo rules/indexes from the project root:
  ```bash
  firebase deploy --only firestore:rules,firestore:indexes,storage
  ```
- Enable **Cloud Storage** (used for nanny photos / video / documents).

## 5. Run

```bash
cd kafi_app
fvm flutter pub get
fvm flutter run        # live Firebase (config files required)
```

### Phone auth notes
- SMS verification codes are **6 digits** (`AuthConstants.otpLength = 6`).
- On Android, auto-retrieval may auto-verify without manual entry; otherwise the
  user types the 6-digit code on the OTP screen.
- Auth errors are mapped to localized messages in `AuthController._authErrorMessage`
  per System Spec §14.1.

## Google Maps / Location (city auto-detect + picker)

The family "City / Emirate" field auto-detects the user's city via GPS and opens
an Uber-style location picker (map + Places search). This needs a Google Cloud
key with **Maps SDK (Android + iOS) + Places API + Geocoding API** enabled, set in
THREE places (replace the `YOUR_GOOGLE_MAPS_API_KEY` placeholder in each):

- `lib/utils/constants/app_constants.dart` → `googleMapsApiKey`
- `android/app/src/main/AndroidManifest.xml` → `com.google.android.geo.API_KEY`
- `ios/Runner/AppDelegate.swift` → `GMSServices.provideAPIKey(...)`

Until a real key is set, the picker falls back to manual text entry and city
auto-detect is skipped (no permission prompt). Location permission/usage is
already declared on both platforms:
- Android: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`
- iOS: `NSLocationWhenInUseUsageDescription`,
  `NSLocationAlwaysAndWhenInUseUsageDescription`
