# Google Maps / Places setup

The nanny onboarding **location picker** (current area, work-experience
city/country, reference city) uses Google Maps for an Uber-style map with a
centre pin, Places autocomplete search, and reverse geocoding into
`{lat, lng, address, city, country}`.

Until a real API key is configured the app **falls back to a curated UAE-areas
list** (no map). Everything else works; only the live map/search needs the key.

The same client key is read in **three** places — the Dart REST calls (Places +
Geocoding) and the two native Maps SDKs (Android + iOS). All three currently
hold the placeholder `YOUR_GOOGLE_MAPS_API_KEY`.

## 1. Enable APIs & create a key

In the [Google Cloud console](https://console.cloud.google.com/):

1. Enable: **Maps SDK for Android**, **Maps SDK for iOS**, **Places API**, **Geocoding API**.
2. Create an **API key** (APIs & Services → Credentials).
3. **Restrict** it (strongly recommended — this key ships in the app binary):
   - *Application restrictions*: add your Android app (package name +
     SHA-1 of the signing certs) and your iOS bundle id.
   - *API restrictions*: limit to the four APIs above.

> A client Maps key is embedded in the app by design; the restrictions above —
> not secrecy — are what protect it. Keep the raw key out of git regardless.

## 2. Provide the key

### a. Dart side (Places autocomplete + reverse geocoding)

Read from a build-time define — no source edit needed:

```bash
flutter run   --dart-define=GOOGLE_MAPS_API_KEY=AIza...your-key
flutter build apk --release --dart-define=GOOGLE_MAPS_API_KEY=AIza...your-key
```

`AppConstants.googleMapsApiKey` picks this up (`String.fromEnvironment`) and
falls back to the placeholder when it is absent.

### b. Android native map (tiles)

`kafi_app/android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>   <!-- ← replace -->
```

Either replace the value directly, or (recommended for CI, to keep the key out
of git) inject it via a Gradle `manifestPlaceholder`:

```gradle
// android/app/build.gradle → android { defaultConfig { … } }
manifestPlaceholders["MAPS_API_KEY"] =
    (project.findProperty("MAPS_API_KEY") ?: "YOUR_GOOGLE_MAPS_API_KEY")
```

```xml
android:value="${MAPS_API_KEY}"
```

then build with `-PMAPS_API_KEY=AIza...` (or a git-ignored `key.properties`).

### c. iOS native map (tiles)

`kafi_app/ios/Runner/AppDelegate.swift`:

```swift
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")   // ← replace
```

For CI/secret hygiene, read it from a git-ignored xcconfig / Info.plist entry
and pass it here instead of hardcoding.

## 3. Verify

Open nanny onboarding → **About You → Current area / neighbourhood**. With a
valid key you get the interactive map + search; without it, the curated
UAE-areas list. On confirm, the profile persists `currentLocation`
(coords + address + city + country); likewise `location` on each work
experience and reference.

## UAE bias

Autocomplete is biased to the UAE via `AppConstants.placesRegion = 'ae'` and
`placesBiasLat/Lng`. Adjust those to widen or move the search region.
