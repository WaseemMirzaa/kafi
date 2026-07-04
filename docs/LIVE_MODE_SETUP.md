# Kafi — Live Mode Setup (Secrets & Configuration)

This is the single source of truth for the credentials needed to run **Kafi** against
live Firebase, and **how to add them** — both on a normal dev machine and inside the
**Claude Code on the web** remote environment (so I can build/run/test in live mode).

There are three deployables:

| Deployable | Path | Live toggle |
| --- | --- | --- |
| Mobile app (Flutter) | `kafi_app/` | `lib/config/app_config.dart` → `useMock = false` (already false) |
| Admin panel (React/Vite) | `admin-panel/` | `.env` → `VITE_USE_MOCK=false` (prod build is live automatically) |
| Cloud Functions (Node 20) | `functions/` | always live once deployed |

> **Mock mode needs none of this.** `kafi_app/lib/main.dart` skips `Firebase.initializeApp`
> entirely when `useMock = true`, and the admin panel/`npm run dev` default to mock. Every
> screenshot walkthrough can be produced in mock mode. The secrets below are **only** for
> exercising the real backend (Auth / Firestore / Storage / FCM / RevenueCat).

---

## 0. Quickstart — let Claude test everything in live mode

Do these in order. Steps 1–5 are yours (one-time, in the Firebase/Google consoles);
step 6 is what you paste into the environment so I can build/run/test live.

1. **Create a Firebase project** (e.g. `kafi-prod`) and register a **Web** app, an
   **Android** app, and an **iOS** app (§2).
2. **Authentication → Sign-in method → Phone**: enable it, then add a **test phone
   number with a fixed code** (e.g. `+971500000001` → `123456`). This lets me log in with
   no real SIM. (Android also needs SHA-1/256; iOS needs an APNs key — only for device builds.)
3. **Firestore** → create the database; **Storage** → enable. Then from the repo root run
   `firebase deploy --only firestore:rules,firestore:indexes,storage` (or give me a
   `FIREBASE_TOKEN` and I'll deploy).
4. **Admin user**: create one email/password user in Firebase Auth, then run
   `admin-panel/scripts/set-admin-claims.ts` with a service-account JSON to grant it
   `admin: true` (§4.2).
5. **Copy your Web app config** (Project settings → Your apps → SDK setup) — you'll paste
   those 6 values below. Create a **Google Maps** API key with Maps JS + Places + Geocoding.
6. **In the environment settings → Environment variables**, add:
   ```
   VITE_FIREBASE_API_KEY=…
   VITE_FIREBASE_AUTH_DOMAIN=<project>.firebaseapp.com
   VITE_FIREBASE_PROJECT_ID=…
   VITE_FIREBASE_STORAGE_BUCKET=<project>.appspot.com
   VITE_FIREBASE_MESSAGING_SENDER_ID=…
   VITE_FIREBASE_APP_ID=…
   GOOGLE_MAPS_API_KEY=…
   TEST_PHONE=+971500000001         # the number from step 2 (so I know which to use)
   TEST_OTP=123456
   ADMIN_EMAIL=admin@yourdomain.com # from step 4
   ADMIN_PASSWORD=…
   # optional, only if testing purchases:
   REVENUECAT_WEBHOOK_SECRET=…
   FIREBASE_TOKEN=…                 # `firebase login:ci`, lets me deploy rules/functions
   ```
   Then set **`scripts/materialize-secrets.sh` as the environment's setup script** (it turns
   those vars into `admin-panel/.env`, injects the Maps key, and — with the 6 web values —
   I regenerate `firebase_options.dart` via `flutterfire configure`).

Once step 6 is saved, tell me and I'll: materialize the config, run the admin panel and the
mobile app (web) against live Firebase, log in with the test number/admin account, and walk
every screen end-to-end (real Firestore/Auth/Storage), then update the gallery with live shots.

The rest of this document is the full reference behind each step.

---

## 1. Secret inventory (what to gather)

Everything you need, in one table. "Type" tells you how it's injected (see §6).

| # | Secret / value | Type | Consumed by | Where it lands |
| --- | --- | --- | --- | --- |
| 1 | `google-services.json` | file | mobile (Android) | `kafi_app/android/app/google-services.json` |
| 2 | `GoogleService-Info.plist` | file | mobile (iOS) | `kafi_app/ios/Runner/GoogleService-Info.plist` |
| 3 | Firebase **web/android/ios** options (apiKey, appId, messagingSenderId, projectId, authDomain, storageBucket, iosBundleId) | values | mobile (all platforms + web) | `kafi_app/lib/firebase_options.dart` (regen via `flutterfire configure`) |
| 4 | Google **Maps API key** (Maps SDK Android+iOS, Maps JS, Places, Geocoding) | value | mobile | 4 spots — see §3.3 |
| 5 | Firebase **web config** (6 `VITE_FIREBASE_*` values) | values | admin panel | `admin-panel/.env` |
| 6 | **Admin service-account** JSON | file | one-time script | `scripts/` (used by `set-admin-claims.ts`) |
| 7 | Admin **email + password** (+ `admin:true` claim) | value | admin login | Firebase Auth user |
| 8 | `REVENUECAT_WEBHOOK_SECRET` | value | functions | function env / secret |
| 9 | Firebase **CI token** or service account (for `firebase deploy`) | value/file | functions + rules deploy | CI env |
| 10 | **Test phone numbers** (+ fixed OTP) | value | Auth QA | Firebase Console (no real SIM needed) |

All of these are **secrets** — never commit #1, #2, #6, #8, #9, or real values in #3/#5. They are
already covered by `.gitignore` (verify before pushing).

---

## 2. Create the Firebase project

1. Firebase Console → **Add project** (e.g. `kafi-prod`).
2. Register apps: **Android** (`package_name` from `android/app/build.gradle`), **iOS**
   (bundle id from Xcode), and **Web** (for the admin panel + Flutter web).
3. **Authentication → Sign-in method → Phone**: enable.
   - Add **test phone numbers** with a fixed code under *Phone numbers for testing*
     (secret #10) so QA never needs a real SIM. Example: `+971500000001 → 123456`.
   - **Android:** add the app's **SHA-1** + **SHA-256** (Project Settings → Your app).
   - **iOS:** upload an **APNs auth key** (Cloud Messaging) for phone-auth + FCM.
4. **Firestore** → create database (production mode).
5. **Storage** → enable (nanny photos / video / documents).
6. Deploy rules + indexes from repo root (files already present: `firestore.rules`,
   `firestore.indexes.json`, `storage.rules`, `firebase.json`):
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes,storage
   ```

---

## 3. Mobile app (`kafi_app/`)

### 3.1 Platform config files
Drop the downloaded files (secrets #1, #2) at:
- `kafi_app/android/app/google-services.json`
- `kafi_app/ios/Runner/GoogleService-Info.plist`

### 3.2 `firebase_options.dart` (secret #3)
Currently a **placeholder** (`apiKey: 'mock-api-key'`, `projectId: 'kafi-mock'`). Regenerate:
```bash
cd kafi_app
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-project-id>
```
This rewrites `lib/firebase_options.dart` with real **web + android + ios** options — required
for Flutter **web** live mode (web has no `google-services.json`).

### 3.3 Google Maps key (secret #4) — 4 spots
Enable **Maps SDK for Android + iOS, Maps JavaScript API, Places API, Geocoding API** on one
Google Cloud key, then set it (replace `YOUR_GOOGLE_MAPS_API_KEY`):
- `lib/utils/constants/app_constants.dart` → `googleMapsApiKey`
- `android/app/src/main/AndroidManifest.xml` → `com.google.android.geo.API_KEY`
- `ios/Runner/AppDelegate.swift` → `GMSServices.provideAPIKey(...)`
- **Web:** add to `web/index.html` before `flutter_bootstrap.js`:
  ```html
  <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_GOOGLE_MAPS_API_KEY&libraries=places"></script>
  ```
Until set, the location picker falls back to manual text entry (city auto-detect skipped).

### 3.4 Run
```bash
cd kafi_app
flutter pub get
flutter run                       # device/emulator, live Firebase
flutter run -d chrome             # web, live Firebase
```

---

## 4. Admin panel (`admin-panel/`)

1. Create `admin-panel/.env` from `.env.example` (secret #5):
   ```
   VITE_USE_MOCK=false
   VITE_FIREBASE_API_KEY=...
   VITE_FIREBASE_AUTH_DOMAIN=<project>.firebaseapp.com
   VITE_FIREBASE_PROJECT_ID=...
   VITE_FIREBASE_STORAGE_BUCKET=<project>.appspot.com
   VITE_FIREBASE_MESSAGING_SENDER_ID=...
   VITE_FIREBASE_APP_ID=...
   ```
   `npm run dev` is mock unless `VITE_USE_MOCK=false`; `vite build` is live automatically.
2. Seed an admin (secrets #6, #7):
   1. Create an email/password user in Firebase Auth.
   2. Run `scripts/set-admin-claims.ts` with a **service-account** JSON — it sets the
      `admin:true` claim (checked in `src/hooks/useAuth.ts`) and creates `admins/{uid}`.
   3. Admin signs out/in once for the claim to take effect.
3. `npm install && npm run build` (or `npm run dev`).

---

## 5. Cloud Functions (`functions/`)

1. Set the RevenueCat webhook secret (secret #8):
   ```bash
   firebase functions:secrets:set REVENUECAT_WEBHOOK_SECRET
   ```
   (or a `.env` for the emulator). `triggers/webhook.ts` rejects webhook calls without it.
2. Deploy:
   ```bash
   cd functions && npm install && npm run build
   firebase deploy --only functions
   ```
3. Point the **RevenueCat dashboard** webhook at the deployed `revenueCatWebhook` URL with
   the same shared secret.

---

## 6. Injecting secrets into the Claude Code on the web environment

The remote environment supports **environment variables** and a **setup script** that runs at
session start. Files (JSON/plist) can't be pasted as-is, so store them **base64-encoded** in
env vars and let the setup script materialize them.

### 6.1 Environment variables to add (in the environment's settings)
```
# Files (base64 — `base64 -w0 file` then paste)
GOOGLE_SERVICES_JSON_B64=<base64 of google-services.json>
GOOGLE_SERVICE_INFO_PLIST_B64=<base64 of GoogleService-Info.plist>
FIREBASE_SA_JSON_B64=<base64 of the admin service-account json>

# Plain values
GOOGLE_MAPS_API_KEY=<maps key>
REVENUECAT_WEBHOOK_SECRET=<secret>
FIREBASE_TOKEN=<`firebase login:ci` token, for deploys>

# Admin panel web config
VITE_FIREBASE_API_KEY=...
VITE_FIREBASE_AUTH_DOMAIN=...
VITE_FIREBASE_PROJECT_ID=...
VITE_FIREBASE_STORAGE_BUCKET=...
VITE_FIREBASE_MESSAGING_SENDER_ID=...
VITE_FIREBASE_APP_ID=...
```

### 6.2 Setup script
Add `scripts/materialize-secrets.sh` (a template is committed alongside this doc) as the
environment's **setup script**, or invoke it from a `.claude` SessionStart hook. It:
- decodes the `*_B64` vars to their file paths,
- writes `admin-panel/.env` from the `VITE_*` vars,
- injects the Maps key into `web/index.html` + the three native spots,
- runs `flutterfire configure` (if `FIREBASE_TOKEN` is present) or expects a pre-supplied
  `firebase_options.dart`.

After it runs, `flutter run`, `npm run build`, and `firebase deploy` all work in live mode.

### 6.3 Minimum set for *me* to test live in this environment
To have me exercise the real backend screen-by-screen (web), the smallest set is:
1. `FIREBASE_SA_JSON_B64` **or** the 6 web-config values (for `firebase_options.dart` + admin `.env`),
2. `GOOGLE_MAPS_API_KEY` (only for the location-picker screen),
3. at least one **test phone number + fixed OTP** (Auth QA),
4. `REVENUECAT_WEBHOOK_SECRET` (only if testing purchases).

Nothing else is required to walk both apps in live mode.

---

## 7. Security notes
- Keep all files in §1 out of git (already `.gitignore`d — verify).
- Use a **separate** Firebase project for staging vs production.
- The Maps key should be **restricted** (by package/bundle/HTTP referrer + the 5 APIs above).
- Rotate the RevenueCat secret and Firebase CI token if they ever land in a log.
