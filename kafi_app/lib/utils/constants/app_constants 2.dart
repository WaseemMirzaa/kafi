/// App-wide non-UI constants (branding keys reference l10n for display text).
class AppConstants {
  static const defaultLocale = 'en_US';
  static const supportedLocales = ['en_US', 'ar_AE'];

  /// Google Cloud API key for Maps SDK (iOS/Android), Places API and Geocoding
  /// API. Prefer `--dart-define=GOOGLE_MAPS_API_KEY=…` (see launch.json /
  /// docs/GOOGLE_MAPS_SETUP.md). The default matches the iOS
  /// `GMSServices.provideAPIKey` value so local runs open the live map without
  /// an extra flag. Restrict this key in Google Cloud (bundle id / SHA-1).
  static const googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyDqQUR6ygHdXRDDUmJ7Xr02A2HCMH92Lvk',
  );

  /// UAE bounding box used to bias Places Autocomplete results.
  static const placesBiasLat = 24.4539;
  static const placesBiasLng = 54.3773;
  static const placesRegion = 'ae';
}
