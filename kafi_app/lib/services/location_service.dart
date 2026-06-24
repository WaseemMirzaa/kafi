import 'package:geolocator/geolocator.dart';
import 'package:kafi_app/services/places_service.dart';
import 'package:kafi_app/utils/constants/app_constants.dart';

/// Device location + reverse-geocoding helper.
///
/// Used to auto-detect the user's city/emirate. Reverse geocoding requires a
/// valid Google Maps/Geocoding API key (`AppConstants.googleMapsApiKey`); when
/// the key is still the placeholder, [detectCurrentCity] returns null and the
/// UI falls back to manual entry.
class LocationService {
  LocationService({PlacesService? places}) : _places = places ?? PlacesService();

  final PlacesService _places;

  bool get hasMapsKey =>
      AppConstants.googleMapsApiKey != 'YOUR_GOOGLE_MAPS_API_KEY';

  /// Ensures location services are on and permission is granted, requesting it
  /// once if currently denied. Returns false on denied/disabled.
  Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Current device position, or null if unavailable / denied.
  Future<Position?> currentPosition() async {
    if (!await ensurePermission()) return null;
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
    } catch (_) {
      return null;
    }
  }

  /// Detects the user's city / emirate via GPS + reverse geocoding.
  /// Returns null if no API key, permission denied, services off, or no result.
  Future<String?> detectCurrentCity() async {
    if (!hasMapsKey) return null;
    final pos = await currentPosition();
    if (pos == null) return null;
    final details = await _places.reverseGeocode(pos.latitude, pos.longitude);
    if (details == null) return null;
    final label = details.emirate ?? details.city ?? details.formattedAddress;
    return label.trim().isEmpty ? null : label.trim();
  }
}
