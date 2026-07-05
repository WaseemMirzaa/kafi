# Build an installable Android APK (live Firebase)

Produces an APK that runs against **live Firebase**, so you can test the full
nanny + family journeys on a real device. For the broader Firebase project setup
(Phone auth, test numbers, SHA fingerprints, Firestore/Storage rules) see
[`FIREBASE_SETUP.md`](./FIREBASE_SETUP.md).

## Prerequisites

1. **Flutter** on PATH — `flutter --version` (this repo pins 3.44.x).
2. **Android SDK / Android Studio** — `flutter doctor` shows the Android toolchain ✓.
   Accept licenses once: `flutter doctor --android-licenses`.
3. **Firebase Android config** — download `google-services.json` from the Firebase
   console (Project settings → your Android app, package `com.kafi.kafi_app`) and
   save it to:
   ```
   kafi_app/android/app/google-services.json
   ```
   This file is **git-ignored** — it is a project secret and is never committed.

## Build

```bash
cd kafi_app
scripts/build_apk.sh            # release APK (installable, debug-signed)
# or:
scripts/build_apk.sh debug     # debug APK
```

Output:
```
kafi_app/build/app/outputs/flutter-apk/app-release.apk
```

Install on a connected device (USB debugging enabled):
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## How Firebase is wired (no secrets in source)

- `AppConfig.useMock = false` → the app initializes live Firebase on launch.
- On **Android**, Firebase initializes from the native `google-services.json` via
  the `com.google.gms.google-services` Gradle plugin, which is applied **only when
  that file is present** (`android/app/build.gradle.kts`). So a mock/offline build
  needs no Firebase credentials, and no real config is baked into any tracked file.

## Test credentials

- Phone **+92 302 5453549**, OTP **123456**.
- This is a Firebase **test phone number**: add it under Firebase console →
  Authentication → Sign-in method → Phone → *Phone numbers for testing*, otherwise
  no SMS is sent and the code won't verify.
- For **real** phone numbers, ensure the app's **SHA-1/SHA-256** fingerprints are
  registered (Project settings → your Android app) and that the target country's
  SMS region is allowed in Auth settings.

## Release signing (optional, for distribution)

`--release` currently signs with the debug keystore (fine for sideloading to
testers). For Play / wider distribution, add a release keystore plus
`android/key.properties` (both git-ignored) and a `signingConfigs.release` block
in `android/app/build.gradle.kts`.
