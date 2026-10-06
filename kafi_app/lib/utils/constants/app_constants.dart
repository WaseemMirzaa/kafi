/// App-wide non-UI constants (branding keys reference l10n for display text).
class AppConstants {
  static const defaultLocale = 'en_US';
  static const supportedLocales = ['en_US', 'ar_AE'];

  /// Google Cloud API key for Maps SDK (iOS/Android), Places API and Geocoding
  /// API. Prefer `--dart-define=GOOGLE_MAPS_API_KEY=…` (see launch.json /
  /// docs/GOOGLE_MAPS_SETUP.md). The default matches the iOS
  /// `GMSServices.provideAPIKey` value so local runs open the live map without
  /// an extra flag. Restrict this key in Google Cloud (bundle id / SHA-1).
  /// Supplied at build time via `--dart-define=GOOGLE_MAPS_API_KEY=…` (CI)
  /// or falls back to the key stored in android/local.properties / AppDelegate.swift
  /// for local runs. Never commit a live key as the defaultValue.
  static const googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  /// UAE bounding box used to bias Places Autocomplete results.
  static const placesBiasLat = 24.4539;
  static const placesBiasLng = 54.3773;
  static const placesRegion = 'ae';
}
