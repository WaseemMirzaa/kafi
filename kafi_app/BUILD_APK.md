# Build an installable Android APK (live Firebase)

Produces an APK that runs against **live Firebase** so you can test the full
nanny + family journeys on a real device.

## Recommended: build in CI (no local Android SDK)

The **Build APK** GitHub Actions workflow (`.github/workflows/build-apk.yml`)
compiles the APK on GitHub's runners and uploads it as a downloadable artifact.
It reuses the **same Firebase secrets as the web deploy** — the `VITE_FIREBASE_*`
values in the `FIREBASE_PROJECT_ID` GitHub Environment — so there is **nothing new
to configure** once the deploy secrets are set.

1. **Actions → “Build APK” → Run workflow** (choose `release` or `debug`).
2. When it finishes, download the `kafi-release-apk` artifact from the run and
   install the `.apk` on a device.

On the runner, `scripts/materialize-secrets.sh` generates `firebase_options.dart`
from those secrets, where the **Android app config mirrors the web app config**
(`android = web`). No credentials are committed — the file exists only on the
runner.

## Alternative: build locally

Needs Flutter + the Android SDK (`flutter doctor` shows Android ✓; run
`flutter doctor --android-licenses` once), then either:

- **Reuse the web credentials** — export the same `VITE_FIREBASE_*` values, run
  `bash scripts/materialize-secrets.sh` from the repo root, then
  `cd kafi_app && flutter build apk --release`; or
- **Use a native Android app config** — drop `google-services.json` (Firebase
  console → your Android app, package `com.kafi.kafi_app`) into
  `kafi_app/android/app/` and run `scripts/build_apk.sh`. This file is git-ignored.

Output: `kafi_app/build/app/outputs/flutter-apk/app-release.apk`
Install: `adb install -r build/app/outputs/flutter-apk/app-release.apk`

## How Firebase is wired (no secrets in source)

- `AppConfig.useMock = false` → the app initializes live Firebase on launch.
- If a native `google-services.json` is present, the `com.google.gms.google-services`
  Gradle plugin (applied only when that file exists) auto-initializes Firebase and
  the app reuses it; otherwise the app initializes from `firebase_options.dart`.
- So the CI build works from the web secrets alone, and a mock/offline build needs
  no Firebase config at all.

## Test credentials

- Phone **+92 302 5453549**, OTP **123456**.
- Add it under Firebase console → Authentication → Sign-in method → Phone →
  *Phone numbers for testing*, otherwise no SMS is sent. **Test numbers bypass
  reCAPTCHA / Play Integrity**, so they work even though the APK is signed with a
  debug key and uses the web app config.

## Caveats when reusing the web credentials for Android

- The web app config is enough for **Auth + Firestore + Storage** testing, which
  covers both flows. It is not a *proper* Android app registration:
  - **API key restrictions:** if the `VITE_FIREBASE_API_KEY` is a browser key
    restricted to HTTP referrers, Android requests will be rejected — use an
    unrestricted key (or register a real Android app and its key).
  - **FCM push** and **real-number** phone auth (reCAPTCHA / Play Integrity) need a
    real Android app + its `google-services.json` and the app's SHA-1/SHA-256
    fingerprints registered in the Firebase project.

## Release signing (optional, for distribution)

`--release` signs with the debug keystore (fine for sideloading to testers). For
Play / wider distribution, add a release keystore + `android/key.properties` (both
git-ignored) and a `signingConfigs.release` block in
`android/app/build.gradle.kts`.
