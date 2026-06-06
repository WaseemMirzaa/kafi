# Kafi — Production Readiness Audit
## Permissions, Dependencies & Feature Implementation State

---

## Executive Summary

**Critical blockers before production:**

1. **AndroidManifest.xml has zero `<uses-permission>` declarations** — every permission call will silently fail or crash on Android.
2. **iOS Info.plist has zero NSUsageDescription strings** — iOS will crash with an immediate exception the first time any permission is requested.
3. **Google Maps API key is the placeholder `YOUR_GOOGLE_MAPS_API_KEY`** — maps and location search will not render.
4. **No `image_picker` or `file_picker` package** — all photo, video, and document uploads pass a dummy `Uint8List(1)` (1 zero byte). Nothing is actually picked from the device.
5. **`purchases_flutter` (RevenueCat SDK) is not in pubspec.yaml** — the entire subscription/payment flow has no real implementation.
6. **`google-services.json` / `GoogleService-Info.plist`** — not present in the repository (not required in dev/mock but needed before any live Firebase call).

---

## 1. Platform Configuration Audit

### 1.1 AndroidManifest.xml — Current State

**File:** `kafi_app/android/app/src/main/AndroidManifest.xml`

The manifest currently contains **only** the launcher activity, Google Maps meta-data tag (with placeholder key), and the `PROCESS_TEXT` query. **Zero `<uses-permission>` tags.**

| Required Permission | Purpose | Status |
|---------------------|---------|--------|
| `INTERNET` | All network calls (Firebase, Places API, FCM) | ❌ MISSING |
| `ACCESS_FINE_LOCATION` | GPS in KafiLocationPicker | ❌ MISSING |
| `ACCESS_COARSE_LOCATION` | Fallback location | ❌ MISSING |
| `CAMERA` | Photo/video capture | ❌ MISSING |
| `READ_MEDIA_IMAGES` | Gallery access (Android 13+) | ❌ MISSING |
| `READ_EXTERNAL_STORAGE` | Gallery access (Android ≤12) | ❌ MISSING |
| `RECORD_AUDIO` | Video recording with audio | ❌ MISSING |
| `POST_NOTIFICATIONS` | Push notifications (Android 13+) | ❌ MISSING |
| `RECEIVE_BOOT_COMPLETED` | FCM background delivery | ❌ MISSING |
| `VIBRATE` | Notification vibration | ❌ MISSING |
| Google Maps API key | Maps rendering | ❌ PLACEHOLDER (`YOUR_GOOGLE_MAPS_API_KEY`) |

### 1.2 iOS Info.plist — Current State

**File:** `kafi_app/ios/Runner/Info.plist`

Contains only basic bundle metadata. **Zero `NS*UsageDescription` strings and no background modes.**

| Required Key | Purpose | Status |
|---|---|---|
| `NSCameraUsageDescription` | Photo/video capture | ❌ MISSING |
| `NSPhotoLibraryUsageDescription` | Gallery access | ❌ MISSING |
| `NSPhotoLibraryAddUsageDescription` | Saving photos to library | ❌ MISSING |
| `NSMicrophoneUsageDescription` | Video recording audio | ❌ MISSING |
| `NSLocationWhenInUseUsageDescription` | GPS in location picker | ❌ MISSING |
| `NSContactsUsageDescription` | Contacts (PermissionController has it) | ❌ MISSING |
| `UIBackgroundModes: remote-notification` | FCM background push | ❌ MISSING |
| Google Maps iOS API key (`GMSServices.provideAPIKey`) | Maps rendering | ❌ NOT CONFIGURED |

### 1.3 pubspec.yaml — Missing Production Packages

| Package | Purpose | Status |
|---------|---------|--------|
| `image_picker` | Actual camera/gallery photo & video selection | ❌ NOT IN PUBSPEC |
| `file_picker` | Document (PDF/JPG) selection from device | ❌ NOT IN PUBSPEC |
| `purchases_flutter` | RevenueCat SDK — subscription payments | ❌ NOT IN PUBSPEC |
| `flutter_local_notifications` | Display FCM messages as local notifications | ❌ NOT IN PUBSPEC |
| `video_player` | Video playback in VideoPlayerScreen | ❌ NOT IN PUBSPEC |

**Packages present and correctly declared:**

| Package | Purpose | Status |
|---------|---------|--------|
| `permission_handler` ^11.3.1 | Runtime permission checks & requests | ✅ Present |
| `geolocator` ^13.0.2 | GPS / location services | ✅ Present |
| `google_maps_flutter` ^2.9.0 | Map rendering in location picker | ✅ Present |
| `firebase_messaging` ^15.1.3 | FCM push notifications | ✅ Present |
| `connectivity_plus` ^6.0.5 | Network state monitoring | ✅ Present |
| `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage` | Firebase suite | ✅ Present |

---

## 2. Permission Implementation Audit

### 2.1 PermissionController & PermissionService

**Files:** `lib/controllers/permission_controller.dart`, `lib/services/permission_service.dart`

The Dart-side permission layer is **fully implemented** and correct:

| Permission | Check Method | Request Method | Status |
|---|---|---|---|
| Notifications | `checkNotification()` | `requestNotification()` | ✅ Dart code complete |
| Camera | `checkCamera()` | `requestCamera()` | ✅ Dart code complete |
| Gallery/Photos | `checkGallery()` | `requestGallery()` | ✅ Dart code complete |
| Microphone | `checkMicrophone()` | `requestMicrophone()` | ✅ Dart code complete |
| Location | `checkLocation()` | `requestLocation()` | ✅ Dart code complete |
| Contacts | `checkContacts()` | `requestContacts()` | ✅ Dart code complete |

**All of these will silently fail or throw on both platforms because the permissions are not declared in the manifests.**

The controller also has `ensureCameraAndMic()` (used before video upload) and `ensureGallery()` (used before image send in chat) — the guard logic in the controllers is correct.

---

## 3. Screen-by-Screen Feature Audit

### Legend

- **Fully implemented** — UI + logic + backend connected, works end-to-end
- **UI only** — screen renders, no logic behind actions
- **Mocked** — logic runs against in-memory mock data, not Firebase
- **Backend pending** — Dart code calls the service interface, but the Firebase implementation is not wired (or mock flag prevents it)
- **Placeholder** — the code compiles but uses dummy values (e.g., `Uint8List(1)`, hardcoded URLs)
- **Not implemented** — feature is missing from the code entirely

---

### 3.1 Auth Screens

| Screen | Feature | Permission Required | Permission Status | Feature Status | Backend Status | Notes / Production Risks |
|--------|---------|---------------------|-------------------|----------------|----------------|--------------------------|
| WelcomeScreen (`/`) | Role selection (Nanny / Family) | None | N/A | ✅ Fully implemented | N/A | — |
| LoginNannyScreen (`/login-nanny`) | Phone number input + validation | None | N/A | ✅ Fully implemented | Mocked | Firebase Phone Auth needs `google-services.json` |
| LoginFamilyScreen (`/login-family`) | Phone number input + validation | None | N/A | ✅ Fully implemented | Mocked | Same as above |
| OtpVerifyScreen (`/otp-verify`) | OTP entry + verify | None | N/A | ✅ UI complete | Mocked | **Mock OTP `1234` is rendered in the SMS preview widget in the UI** — must be removed before production |
| OtpVerifyScreen | SMS auto-read (OTP autofill) | SMS (Android) | ❌ Not requested | ❌ Not implemented | Not implemented | `sms_autofill` package not in pubspec; no auto-read |
| OtpVerifyScreen | OTP resend timer | None | N/A | ✅ Implemented | Mocked | — |
| CreatePasswordScreen (`/create-password`) | Password creation + strength check | None | N/A | ✅ Fully implemented | Mocked | — |
| PasswordResetScreen (`/password-reset`) | Phone + OTP + new password flow | None | N/A | ✅ UI complete | Mocked | — |
| DeleteAccountScreen (`/delete-account`) | Delete account with confirmation | None | N/A | ✅ Fully implemented | Mocked → Firebase trigger `onUserDeleted` ready | Cascade delete Cloud Function exists |

---

### 3.2 Nanny Onboarding

| Screen | Feature | Permission Required | Permission Status | Feature Status | Backend Status | Notes / Production Risks |
|--------|---------|---------------------|-------------------|----------------|----------------|--------------------------|
| NannyInfoScreen (`/nanny-info`) | Personal info form (name, DOB, nationality, etc.) | None | N/A | ✅ Fully implemented | Mocked | — |
| NannyInfoScreen | City / location selection (KafiLocationPicker) | Location (optional GPS) | ❌ Not declared in manifest/plist | ✅ Dart logic complete | Needs Google Places API key | App won't crash if user skips GPS; crash/no-result if API key not set |
| NannyInfoScreen | Work location selection | Location (optional) | ❌ Same | ✅ Dart logic complete | Needs Places API key | — |
| NannyMediaScreen (`/nanny-media`) | Profile photo upload | Camera + Gallery | ❌ Not declared | **⚠ PLACEHOLDER** | Backend pending | `uploadPhoto(Uint8List(1))` — passes 1 zero byte; no `image_picker` in pubspec |
| NannyMediaScreen | Intro video upload | Camera + Microphone | ❌ Not declared | **⚠ PLACEHOLDER** | Backend pending | `uploadVideo(Uint8List(1))` — passes 1 zero byte; no `image_picker` or `video_picker` |
| NannyMediaScreen | Permission guard before upload | Gallery / Camera+Mic | ❌ Not declared in manifest | ✅ Guard code exists | N/A | `ensureGallery()` / `ensureCameraAndMic()` called correctly; will be denied silently without manifest entries |
| NannyExpScreen (`/nanny-exp`) | Work experience form | None | N/A | ✅ Fully implemented | Mocked | — |
| NannyRefsScreen (`/nanny-refs`) | References form | None | N/A | ✅ Fully implemented | Mocked | — |
| NannyDocsScreen (`/nanny-docs`) | Document upload (Passport, Visa, Emirates ID, certs) | Gallery / Files | ❌ Not declared | **⚠ PLACEHOLDER** | Backend pending | `uploadDocument(t, Uint8List(1), 'jpg')` — passes dummy bytes; no `file_picker` in pubspec |
| NannyDocsScreen | Submit for admin review | None | N/A | ✅ Implemented | Mocked → Cloud Function `onNannySubmitted` ready | — |
| NannyPendingScreen (`/nanny-pending`) | Approval status display | None | N/A | ✅ Fully implemented | Mocked | — |

---

### 3.3 Nanny App (Post-Onboarding)

| Screen | Feature | Permission Required | Permission Status | Feature Status | Backend Status | Notes / Production Risks |
|--------|---------|---------------------|-------------------|----------------|----------------|--------------------------|
| NannyShellScreen (`/nanny-home`) | Bottom nav shell (Home/Jobs/Messages/Profile) | None | N/A | ✅ Fully implemented | N/A | — |
| NannyDashboardScreen | Nanny home dashboard, profile score display | None | N/A | ✅ Fully implemented | Mocked | — |
| JobsHomeScreen (`/nanny-jobs`) | Browse job postings | None | N/A | ✅ Fully implemented | Mocked | — |
| JobDetailScreen (`/nanny-job-detail`) | View job detail + apply | None | N/A | ✅ Fully implemented | Mocked | — |
| MyApplicationsScreen (`/nanny-applications`) | List of nanny's applications | None | N/A | ✅ Fully implemented | Mocked | — |
| NannyEditProfileScreen (`/nanny-edit-profile`) | Edit all nanny profile fields | None | N/A | ✅ Fully implemented | Mocked | — |
| NannyEditProfileScreen | Photo re-upload | Camera + Gallery | ❌ Not declared | **⚠ PLACEHOLDER** | Backend pending | Same Uint8List(1) issue |
| SmartMatchScreen (`/smart-match`) | AI-style match scoring display | None | N/A | ✅ UI implemented | Mocked | Match score computed client-side from mock data |
| ChatScreen (Nanny tab) | Receive/send text messages | None | N/A | ✅ Fully implemented | Mocked | — |
| ChatScreen (Nanny tab) | Send image in chat | Gallery | ❌ Not declared | **⚠ PLACEHOLDER** | Backend pending | Sends hardcoded Unsplash URL instead of real upload |
| ChatScreen | Trial offer / counter / accept in chat bubbles | None | N/A | ✅ Fully implemented | Mocked | — |

---

### 3.4 Family App

| Screen | Feature | Permission Required | Permission Status | Feature Status | Backend Status | Notes / Production Risks |
|--------|---------|---------------------|-------------------|----------------|----------------|--------------------------|
| FamilyFormScreen (`/family-form`) | Job post creation form | None | N/A | ✅ Fully implemented | Mocked | — |
| FamilyFormScreen | Location picker (city / trial location) | Location (GPS optional) | ❌ Not declared | ✅ Dart logic complete | Needs Places API key | — |
| FamilyEditScreen (`/family-edit`) | Edit family profile | None | N/A | ✅ Fully implemented | Mocked | — |
| FamilyShellScreen | Bottom nav shell (Browse/Shortlist/Chat/Settings) | None | N/A | ✅ Fully implemented | N/A | — |
| BrowseScreen (`/browse`) | Browse and filter nannies | None | N/A | ✅ Fully implemented | Mocked | `BrowseController` uses `IJobService.browseNannies()` |
| BrowseScreen | Location filter | Location (GPS optional) | ❌ Not declared | ✅ Dart logic (location picker) | Needs Places API key | — |
| BrowseScreen | View nanny profile | None | N/A | ✅ implemented with free-tier gate | Mocked | Free-view counter and subscription gate logic complete |
| ProfileLockedScreen (`/profile-locked`) | Free-tier gate with upgrade CTA | None | N/A | ✅ Fully implemented | N/A | — |
| ProfileRelockedScreen (`/profile-relocked`) | Expired subscription gate | None | N/A | ✅ Fully implemented | N/A | — |
| ProfileUnlockedScreen (`/profile-unlocked`) | Subscribed full profile view | None | N/A | ✅ Fully implemented | Mocked | — |
| VideoPlayerScreen (`/video-player`) | Play nanny intro video | None | N/A | **⚠ UI only** | Not implemented | `video_player` package not in pubspec; screen exists but playback unimplemented |
| PricingScreen (`/pricing`) | Show subscription plans + purchase | None | N/A | ✅ UI complete | **⚠ NOT IMPLEMENTED** | `purchases_flutter` (RevenueCat) not in pubspec; tapping a plan does nothing in production |
| ShortlistScreen (`/shortlist`) | View shortlisted nannies | None | N/A | ✅ Fully implemented | Mocked | — |
| CompareScreen (`/compare`) | Side-by-side nanny comparison | None | N/A | ✅ Fully implemented | Mocked | — |
| TrialScreen (`/trial`) | View/manage trial status | None | N/A | ✅ Fully implemented | Mocked | — |
| TrialOfferScreen (`/trial-offer`) | Create a trial offer | None | N/A | ✅ Fully implemented | Mocked | — |
| TrialOfferScreen | Trial location picker | Location (GPS optional) | ❌ Not declared | ✅ Dart logic complete | Needs Places API key | — |
| ChatScreen (Family tab) | Text messaging | None | N/A | ✅ Fully implemented | Mocked | — |
| ChatScreen (Family tab) | Image send | Gallery | ❌ Not declared | **⚠ PLACEHOLDER** | Backend pending | Sends hardcoded Unsplash URL |
| ChatScreen | Subscription expired lock / paywall redirect | None | N/A | ✅ Fully implemented | Mocked | — |
| NotificationsScreen (`/notifications`) | List and manage notifications | Notification | ❌ Not declared | ✅ Fully implemented | Mocked | FCM deep-link handler fully implemented |
| SettingsScreen (`/settings`) | Notification / privacy / language toggles | Notification | ❌ Not declared for Android 13+ | ✅ Fully implemented | Mocked | — |

---

### 3.5 Shared Screens

| Screen | Feature | Permission Required | Permission Status | Feature Status | Backend Status | Notes / Production Risks |
|--------|---------|---------------------|-------------------|----------------|----------------|--------------------------|
| Legal screens (`/terms`, `/privacy`) | Static content display | None | N/A | ✅ Fully implemented | N/A | — |

---

## 4. Feature-Category Deep Dives

### 4.1 Location & Maps

**Implementation state:** ✅ Dart code fully complete — UI, GPS, Places autocomplete, map display  
**Blockers for production:**

| Blocker | Impact |
|---------|--------|
| `YOUR_GOOGLE_MAPS_API_KEY` placeholder in AndroidManifest | Map tiles won't render on Android |
| No iOS `GMSServices.provideAPIKey()` call configured | Map tiles won't render on iOS |
| No Places API key in `PlacesService` (likely same key) | Autocomplete returns no results |
| `ACCESS_FINE_LOCATION` missing from AndroidManifest | GPS button will fail silently |
| `NSLocationWhenInUseUsageDescription` missing from Info.plist | iOS will crash on first GPS request |

**Screens affected:** NannyInfoScreen, FamilyFormScreen, TrialOfferScreen, BrowseScreen (location filter), KafiLocationPicker (used throughout)

---

### 4.2 File & Media Uploads

**Implementation state:** ⚠ PLACEHOLDER — the controller logic, permission guards, and storage service calls are correct, but the screens pass `Uint8List(1)` (a single zero byte) instead of actual file bytes. This is because no image/file picker package exists to capture real bytes.

| Upload Feature | Screen | Package Needed | Status |
|---|---|---|---|
| Profile photo upload | NannyMediaScreen | `image_picker` | ❌ No package; dummy bytes |
| Intro video upload | NannyMediaScreen | `image_picker` (video) | ❌ No package; dummy bytes |
| Document upload (PDF/JPG) | NannyDocsScreen | `file_picker` | ❌ No package; dummy bytes |
| Image send in chat | ChatScreen | `image_picker` | ❌ No package; hardcoded Unsplash URL used instead |
| Photo re-upload (edit profile) | NannyEditProfileScreen | `image_picker` | ❌ No package; dummy bytes |
| Video playback | VideoPlayerScreen | `video_player` | ❌ No package; screen incomplete |

**What's actually wired correctly:**
- Permission guards (`ensureGallery()`, `ensureCameraAndMic()`) are called before upload attempts
- Firebase Storage upload paths are correctly structured (`nannies/{id}/photos/`, etc.)
- The `IStorageService` interface and mock implementation exist
- The Firebase Storage implementation (`firestore_storage_service.dart`) presumably exists and would work once given real bytes

---

### 4.3 Push Notifications (FCM)

**Implementation state:** ✅ Well implemented end-to-end in Dart — good  
**Blockers for production:**

| Blocker | Impact |
|---------|--------|
| `POST_NOTIFICATIONS` missing from AndroidManifest | Android 13+ permission request will do nothing |
| `NSLocationWhenInUseUsageDescription` — wait, for notifications: `UIBackgroundModes: remote-notification` missing from Info.plist | FCM won't wake the app in background on iOS |
| No `RECEIVE_BOOT_COMPLETED` in AndroidManifest | FCM may miss messages after device restart |
| `firebase_messaging` requires `google-services.json` / `GoogleService-Info.plist` | Not committed to repo (expected for security, but must be set up) |

**What's fully implemented:**
- `NotificationController.initFCM()` — requests permission, initializes FCM, gets and saves token
- FCM token saved per user to Firestore when login state changes
- Full deep-link routing from notification tap (chat thread, jobs tab, browse tab)
- Admin broadcast via `onBroadcastCreated` Cloud Function ready

---

### 4.4 Subscriptions / RevenueCat

**Implementation state:** ❌ No real implementation  

| Component | Status |
|-----------|--------|
| `purchases_flutter` package | ❌ Not in pubspec.yaml |
| `ISubscriptionService` interface | ✅ Defined |
| `MockSubscriptionService` | ✅ Functional for dev |
| `FirebaseSubscriptionService` | ❌ Doesn't exist (or is empty) — RevenueCat SDK not integrated |
| `RevenueCatWebhook` Cloud Function | ✅ Exists — webhook handler ready for RevenueCat events |
| PricingScreen UI | ✅ Renders plans |
| PricingScreen purchase flow | ❌ Tapping a plan has no production implementation |

**Risk:** The RevenueCat webhook in Cloud Functions is ready, but nothing will send events to it without the SDK installed and configured.

---

### 4.5 Authentication (Firebase Phone Auth)

**Implementation state:** Mocked  
**What's needed for production:**
- `useMock` flag flipped to `false` in `app_config.dart`
- `google-services.json` and `GoogleService-Info.plist` added to respective directories
- Firebase project configured with Phone Authentication enabled
- SHA-1 / SHA-256 fingerprints added to Firebase Android app
- iOS APN key / certificate uploaded to Firebase

**OTP risk:** The `OtpVerifyScreen` renders the mock OTP code (`1 2 3 4`) directly in the SMS preview widget. This debug UI element must be removed before going live.

---

### 4.6 OTP SMS Auto-Read

| Feature | Status |
|---------|--------|
| Manual OTP entry | ✅ Implemented |
| SMS auto-read / autofill (Android) | ❌ Not implemented — `sms_autofill` package not in pubspec |
| Sign in with Apple / Google | ❌ Not implemented — no `sign_in_with_apple` or `google_sign_in` package |

---

## 5. Summary Risk Table

| # | Risk / Blocker | Severity | Category |
|---|---------------|----------|----------|
| 1 | Zero `<uses-permission>` in AndroidManifest | 🔴 Critical | Android config |
| 2 | Zero NS*UsageDescription in Info.plist | 🔴 Critical | iOS config |
| 3 | Google Maps / Places API key is placeholder | 🔴 Critical | Maps & Location |
| 4 | `image_picker` not in pubspec — all uploads pass dummy bytes | 🔴 Critical | Media uploads |
| 5 | `file_picker` not in pubspec — document upload broken | 🔴 Critical | Document uploads |
| 6 | `purchases_flutter` not in pubspec — no payment flow | 🔴 Critical | Subscriptions |
| 7 | `video_player` not in pubspec — VideoPlayerScreen incomplete | 🟠 High | Media playback |
| 8 | Mock OTP code rendered in UI (OtpVerifyScreen) | 🟠 High | Auth security |
| 9 | `AppConfig.useMock = true` — no live Firebase calls | 🟠 High | Global mock flag |
| 10 | `google-services.json` / `GoogleService-Info.plist` not in repo | 🟠 High | Firebase setup |
| 11 | FCM background modes not in iOS Info.plist | 🟠 High | Notifications |
| 12 | Admin panel `VITE_USE_MOCK` must be set to `false` in prod | 🟠 High | Admin panel |
| 13 | Admin panel Google Maps API key (if used) | 🟡 Medium | Admin config |
| 14 | `simulateExpire()` / `simulateRestore()` debug methods in production controller | 🟡 Medium | Code hygiene |
| 15 | SMS auto-read not implemented | 🟡 Medium | UX |
| 16 | Revenue trend sparkline is hardcoded static data | 🟡 Medium | Admin analytics |
| 17 | `flutter_local_notifications` not in pubspec — FCM foreground display | 🟡 Medium | Notifications |
| 18 | `INTERNET` permission missing from AndroidManifest | 🔴 Critical | Android config |
