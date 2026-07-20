/// A structured, persisted location: coordinates + human-readable address +
/// city + country. Produced from the map/Places picker and stored on the nanny
/// profile (current area), work experiences and references.
///
/// Kept independent of the UI `KafiLocation` (widgets layer) — screens convert
/// a picked `KafiLocation` into this for persistence.
class GeoLocation {
  const GeoLocation({
    this.lat,
    this.lng,
    this.address = '',
    this.city = '',
    this.country = '',
  });

  final double? lat;
  final double? lng;
  final String address;
  final String city;
  final String country;

  bool get isEmpty =>
      lat == null &&
      lng == null &&
      address.isEmpty &&
      city.isEmpty &&
      country.isEmpty;

  bool get isNotEmpty => !isEmpty;

  Map<String, dynamic> toMap() => {
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'address': address,
        'city': city,
        'country': country,
      };

  /// Parse from a stored map; null when the map itself is absent.
  static GeoLocation? fromMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    return GeoLocation(
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      address: m['address'] as String? ?? '',
      city: m['city'] as String? ?? '',
      country: m['country'] as String? ?? '',
    );
  }
}
