class LocationService {
  Future<String?> getCurrentEmirate() async {
    return 'Dubai';
  }

  Future<Map<String, double>?> getCurrentCoordinates() async {
    return {'lat': 25.2048, 'lng': 55.2708};
  }
}
