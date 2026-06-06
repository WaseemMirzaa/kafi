/// App-wide non-UI constants (branding keys reference l10n for display text).
class AppConstants {
  static const defaultLocale = 'en_US';
  static const supportedLocales = ['en_US', 'ar_AE'];

  /// Replace with your Google Cloud project API key.
  /// Enable: Maps SDK (iOS/Android), Places API, Geocoding API.
  static const googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  /// UAE bounding box used to bias Places Autocomplete results.
  static const placesBiasLat = 24.4539;
  static const placesBiasLng = 54.3773;
  static const placesRegion = 'ae';
}
