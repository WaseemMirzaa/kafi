import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kafi_app/utils/constants/app_constants.dart';

class PlacePrediction {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String fullDescription;

  const PlacePrediction({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.fullDescription,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structured = json['structured_formatting'] as Map<String, dynamic>? ?? {};
    return PlacePrediction(
      placeId: json['place_id'] as String,
      mainText: structured['main_text'] as String? ?? json['description'] as String,
      secondaryText: structured['secondary_text'] as String? ?? '',
      fullDescription: json['description'] as String,
    );
  }
}

class PlaceDetails {
  final String placeId;
  final String name;
  final String formattedAddress;
  final double lat;
  final double lng;
  final String? city;
  final String? emirate;
  final String? neighbourhood;
  final String? country;

  const PlaceDetails({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.lat,
    required this.lng,
    this.city,
    this.emirate,
    this.neighbourhood,
    this.country,
  });

  /// Short area label for form fields (neighbourhood → city → name).
  String get shortLabel {
    final n = neighbourhood?.trim();
    if (n != null && n.isNotEmpty) return n;
    final c = city?.trim();
    if (c != null && c.isNotEmpty) return c;
    final e = emirate?.trim();
    if (e != null && e.isNotEmpty) return e;
    if (name.trim().isNotEmpty) return name.trim();
    return formattedAddress;
  }
}

class PlacesService {
  static const _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const _detailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';
  static const _geocodeUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';

  final String _apiKey;
  PlacesService({String? apiKey}) : _apiKey = apiKey ?? AppConstants.googleMapsApiKey;

  /// Returns autocomplete predictions for [input] biased to UAE.
  Future<List<PlacePrediction>> autocomplete(String input) async {
    if (input.trim().isEmpty) return [];
    final uri = Uri.parse(_autocompleteUrl).replace(queryParameters: {
      'input': input,
      'key': _apiKey,
      'components': 'country:${AppConstants.placesRegion}',
      'location': '${AppConstants.placesBiasLat},${AppConstants.placesBiasLng}',
      'radius': '200000',
      'language': 'en',
    });
    final response = await http.get(uri);
    if (response.statusCode != 200) return [];
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') return [];
    final predictions = data['predictions'] as List<dynamic>? ?? [];
    return predictions
        .map((p) => PlacePrediction.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  /// Returns full [PlaceDetails] (coords + address) for a [placeId].
  Future<PlaceDetails?> getDetails(String placeId) async {
    final uri = Uri.parse(_detailsUrl).replace(queryParameters: {
      'place_id': placeId,
      'key': _apiKey,
      'fields': 'place_id,name,formatted_address,geometry',
      'language': 'en',
    });
    final response = await http.get(uri);
    if (response.statusCode != 200) return null;
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['status'] != 'OK') return null;
    final result = data['result'] as Map<String, dynamic>;
    final location = (result['geometry'] as Map)['location'] as Map;
    return PlaceDetails(
      placeId: placeId,
      name: result['name'] as String? ?? '',
      formattedAddress: result['formatted_address'] as String? ?? '',
      lat: (location['lat'] as num).toDouble(),
      lng: (location['lng'] as num).toDouble(),
    );
  }

  /// Reverse geocodes [lat]/[lng] to a human-readable address.
  Future<PlaceDetails?> reverseGeocode(double lat, double lng) async {
    final uri = Uri.parse(_geocodeUrl).replace(queryParameters: {
      'latlng': '$lat,$lng',
      'key': _apiKey,
      'language': 'en',
    });
    final response = await http.get(uri);
    if (response.statusCode != 200) return null;
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['status'] != 'OK') return null;
    final results = data['results'] as List<dynamic>;
    if (results.isEmpty) return null;
    final r = results.first as Map<String, dynamic>;
    final comps = r['address_components'] as List<dynamic>? ?? const [];
    return PlaceDetails(
      placeId: r['place_id'] as String? ?? '',
      name: r['formatted_address'] as String? ?? '',
      formattedAddress: r['formatted_address'] as String? ?? '',
      lat: lat,
      lng: lng,
      neighbourhood: _component(comps, 'neighborhood') ??
          _component(comps, 'sublocality_level_1') ??
          _component(comps, 'sublocality'),
      city: _component(comps, 'locality') ??
          _component(comps, 'administrative_area_level_2'),
      emirate: _component(comps, 'administrative_area_level_1'),
      country: _component(comps, 'country'),
    );
  }

  /// Returns the `long_name` of the first address component matching [type].
  static String? _component(List<dynamic> comps, String type) {
    for (final c in comps) {
      final m = c as Map<String, dynamic>;
      final types = (m['types'] as List?)?.cast<String>() ?? const [];
      if (types.contains(type)) return m['long_name'] as String?;
    }
    return null;
  }
}
