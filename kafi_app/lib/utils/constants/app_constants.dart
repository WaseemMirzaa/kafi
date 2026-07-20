/// App-wide non-UI constants (branding keys reference l10n for display text).
class AppConstants {
  static const defaultLocale = 'en_US';
  static const supportedLocales = ['en_US', 'ar_AE'];

  /// Google Cloud API key for Maps SDK (iOS/Android), Places API and Geocoding
  /// API. Supplied at build time via
  /// `--dart-define=GOOGLE_MAPS_API_KEY=…` (kept out of git); falls back to the
  /// placeholder, in which case the location picker uses the curated UAE-areas
  /// list instead of the live map. See docs/GOOGLE_MAPS_SETUP.md.
  static const googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'YOUR_GOOGLE_MAPS_API_KEY',
  );

  /// UAE bounding box used to bias Places Autocomplete results.
  static const placesBiasLat = 24.4539;
  static const placesBiasLng = 54.3773;
  static const placesRegion = 'ae';
}
