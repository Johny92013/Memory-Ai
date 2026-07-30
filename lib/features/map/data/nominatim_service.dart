import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:memory_ai/features/map/data/location_place_model.dart';

/// OpenStreetMap Nominatim Reverse- und Forward-Geocoding.
class NominatimService {
  NominatimService({http.Client? client}) : _client = client ?? http.Client();

  static const _reverseUrl = 'https://nominatim.openstreetmap.org/reverse';
  static const _searchUrl = 'https://nominatim.openstreetmap.org/search';
  static const _userAgent =
      'MemoryAiFamilyApp/1.0 (contact: admin@memoryai.app)';

  final http.Client _client;

  Future<LocationPlace?> reverse(double latitude, double longitude) async {
    final uri = Uri.parse(_reverseUrl).replace(
      queryParameters: {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'format': 'json',
        'addressdetails': '1',
        'zoom': '18',
      },
    );

    final response = await _client.get(
      uri,
      headers: {'User-Agent': _userAgent, 'Accept': 'application/json'},
    );

    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json.isEmpty) return null;

    return LocationPlace.fromNominatimJson(json);
  }

  /// Ortssuche (Forward). Liefert bis zu [limit] Treffer mit Koordinaten.
  Future<List<NominatimSearchResult>> search(
    String query, {
    int limit = 8,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    final uri = Uri.parse(_searchUrl).replace(
      queryParameters: {
        'q': trimmed,
        'format': 'json',
        'addressdetails': '1',
        'limit': limit.toString(),
      },
    );

    final response = await _client.get(
      uri,
      headers: {'User-Agent': _userAgent, 'Accept': 'application/json'},
    );
    if (response.statusCode != 200) return [];

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return [];

    final results = <NominatimSearchResult>[];
    for (final entry in decoded) {
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      final lat = double.tryParse(map['lat']?.toString() ?? '');
      final lon = double.tryParse(map['lon']?.toString() ?? '');
      if (lat == null || lon == null) continue;
      results.add(
        NominatimSearchResult(
          latitude: lat,
          longitude: lon,
          place: LocationPlace.fromNominatimJson(map),
        ),
      );
    }
    return results;
  }
}

class NominatimSearchResult {
  const NominatimSearchResult({
    required this.latitude,
    required this.longitude,
    required this.place,
  });

  final double latitude;
  final double longitude;
  final LocationPlace place;
}
