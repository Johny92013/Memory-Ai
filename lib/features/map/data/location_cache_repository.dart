import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:memory_ai/features/map/data/coordinate_key.dart';
import 'package:memory_ai/features/map/data/location_place_model.dart';
import 'package:path_provider/path_provider.dart';

/// Dauerhafter Cache für Reverse-Geocoding-Ergebnisse (Schlüssel: gerundete Koordinaten).
class LocationCacheRepository {
  LocationCacheRepository();

  static const _fileName = 'location_cache.json';

  Map<String, LocationPlace> _cache = {};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    if (kIsWeb) {
      _loaded = true;
      return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      if (await file.exists()) {
        final raw = await file.readAsString();
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _cache = decoded.map(
          (key, value) => MapEntry(
            key,
            LocationPlace.fromJson(Map<String, dynamic>.from(value as Map)),
          ),
        );
      }
    } catch (_) {
      _cache = {};
    }
    _loaded = true;
  }

  Future<LocationPlace?> get(double latitude, double longitude) async {
    await _ensureLoaded();
    final key = CoordinateKey.fromLatLon(latitude, longitude);
    return _cache[key];
  }

  Future<void> put(
    double latitude,
    double longitude,
    LocationPlace place,
  ) async {
    await _ensureLoaded();
    final key = CoordinateKey.fromLatLon(latitude, longitude);
    _cache[key] = place;
    await _persist();
  }

  Future<void> _persist() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      final encoded = jsonEncode(
        _cache.map((key, place) => MapEntry(key, place.toJson())),
      );
      await file.writeAsString(encoded);
    } catch (_) {
      // Cache-Persistenz ist optional
    }
  }
}
