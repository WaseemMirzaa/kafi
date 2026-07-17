import 'dart:math' as math;

/// A curated UAE area with approximate coordinates. Coordinates power the
/// "use my current location" nearest-area resolver so the picker can turn real
/// GPS into a human-readable area even when no Google Maps/Geocoding key is
/// configured (the fallback picker path).
class UaeArea {
  const UaeArea(this.name, this.emirate, this.lat, this.lng);

  final String name;
  final String emirate;
  final double lat;
  final double lng;
}

/// Curated UAE neighbourhood / area labels used by the fallback location
/// picker when a Google Maps/Places API key is not configured.
class LocationConstants {
  LocationConstants._();

  /// Searchable UAE areas with approximate coordinates.
  static const List<UaeArea> uaeAreas = <UaeArea>[
    // Dubai
    UaeArea('Dubai Marina', 'Dubai', 25.0805, 55.1403),
    UaeArea('Jumeirah Lake Towers (JLT)', 'Dubai', 25.0693, 55.1440),
    UaeArea('Downtown Dubai', 'Dubai', 25.1972, 55.2744),
    UaeArea('Business Bay', 'Dubai', 25.1857, 55.2650),
    UaeArea('Jumeirah', 'Dubai', 25.2048, 55.2440),
    UaeArea('Jumeirah Beach Residence (JBR)', 'Dubai', 25.0785, 55.1339),
    UaeArea('Palm Jumeirah', 'Dubai', 25.1124, 55.1390),
    UaeArea('Arabian Ranches', 'Dubai', 25.0510, 55.2670),
    UaeArea('Dubai Hills', 'Dubai', 25.1010, 55.2480),
    UaeArea('Al Barsha', 'Dubai', 25.1120, 55.2000),
    UaeArea('Al Quoz', 'Dubai', 25.1400, 55.2330),
    UaeArea('Deira', 'Dubai', 25.2710, 55.3140),
    UaeArea('Bur Dubai', 'Dubai', 25.2630, 55.2970),
    UaeArea('Mirdif', 'Dubai', 25.2170, 55.4180),
    UaeArea('Silicon Oasis', 'Dubai', 25.1210, 55.3770),
    UaeArea('Sports City', 'Dubai', 25.0350, 55.2170),
    UaeArea('Motor City', 'Dubai', 25.0470, 55.2410),
    UaeArea('International City', 'Dubai', 25.1590, 55.4090),
    UaeArea('Discovery Gardens', 'Dubai', 25.0430, 55.1400),
    UaeArea('The Springs', 'Dubai', 25.0640, 55.1900),
    UaeArea('The Meadows', 'Dubai', 25.0750, 55.1780),
    UaeArea('Emirates Hills', 'Dubai', 25.0730, 55.1720),
    // Abu Dhabi
    UaeArea('Al Reem Island', 'Abu Dhabi', 24.4990, 54.4050),
    UaeArea('Al Maryah Island', 'Abu Dhabi', 24.4990, 54.3880),
    UaeArea('Khalifa City', 'Abu Dhabi', 24.4190, 54.5760),
    UaeArea('Al Raha', 'Abu Dhabi', 24.4560, 54.6060),
    UaeArea('Saadiyat Island', 'Abu Dhabi', 24.5430, 54.4300),
    UaeArea('Yas Island', 'Abu Dhabi', 24.4890, 54.6070),
    UaeArea('Corniche', 'Abu Dhabi', 24.4750, 54.3220),
    UaeArea('Mussafah', 'Abu Dhabi', 24.3510, 54.5030),
    // Al Ain
    UaeArea('Al Ain City', 'Al Ain', 24.2075, 55.7447),
    // Sharjah
    UaeArea('Al Nahda', 'Sharjah', 25.3050, 55.3720),
    UaeArea('Al Majaz', 'Sharjah', 25.3220, 55.3830),
    UaeArea('Al Khan', 'Sharjah', 25.3260, 55.3820),
    UaeArea('Muwaileh', 'Sharjah', 25.2960, 55.4650),
    UaeArea('University City', 'Sharjah', 25.2880, 55.4900),
    // Ajman
    UaeArea('Ajman Downtown', 'Ajman', 25.4110, 55.4350),
    UaeArea('Al Nuaimiya', 'Ajman', 25.3900, 55.4750),
    // Ras Al Khaimah
    UaeArea('Ras Al Khaimah City', 'Ras Al Khaimah', 25.7895, 55.9432),
    UaeArea('Al Hamra', 'Ras Al Khaimah', 25.6870, 55.7790),
    // Fujairah
    UaeArea('Fujairah City', 'Fujairah', 25.1288, 56.3265),
    // Umm Al Quwain
    UaeArea('Umm Al Quwain City', 'Umm Al Quwain', 25.5647, 55.5552),
  ];

  /// Nearest curated area to the given GPS coordinates (great-circle distance),
  /// or null if the list is empty. Lets "use my current location" resolve real
  /// device coordinates to an area label without any Geocoding API key.
  static UaeArea? nearestArea(double lat, double lng) {
    UaeArea? best;
    var bestKm = double.infinity;
    for (final a in uaeAreas) {
      final d = _haversineKm(lat, lng, a.lat, a.lng);
      if (d < bestKm) {
        bestKm = d;
        best = a;
      }
    }
    return best;
  }

  /// Emirate label for a curated area name, or null if it is not a known area.
  static String? emirateFor(String name) {
    final q = name.trim().toLowerCase();
    for (final a in uaeAreas) {
      if (a.name.toLowerCase() == q) return a.emirate;
    }
    return null;
  }

  static double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const earthKm = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180.0);
}
