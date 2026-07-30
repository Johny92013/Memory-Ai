import 'package:memory_ai/features/map/data/coordinate_key.dart';
import 'package:memory_ai/features/map/data/location_cache_repository.dart';
import 'package:memory_ai/features/map/data/location_place_model.dart';
import 'package:memory_ai/features/map/data/nominatim_rate_limit_queue.dart';
import 'package:memory_ai/features/map/data/nominatim_service.dart';

/// Koordinaten → Land, Code, Region, Stadt, Standortname (Nominatim + Cache).
class LocationService {
  LocationService({
    LocationCacheRepository? cacheRepository,
    NominatimService? nominatimService,
    NominatimRateLimitQueue? rateLimitQueue,
  }) {
    final cache = cacheRepository ?? LocationCacheRepository();
    final nominatim = nominatimService ?? NominatimService();
    _cache = cache;
    _nominatim = nominatim;
    _queue =
        rateLimitQueue ??
        NominatimRateLimitQueue(
          executor: (lat, lon) => nominatim.reverse(lat, lon),
        );
  }

  late final LocationCacheRepository _cache;
  late final NominatimService _nominatim;
  late final NominatimRateLimitQueue _queue;
  DateTime? _lastSearchAt;

  /// Liefert Standortdaten; Fehler werden abgefangen (null = kein Ergebnis).
  Future<LocationPlace?> resolveCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final rounded = CoordinateKey.roundedPair(latitude, longitude);

      final cached = await _cache.get(rounded.lat, rounded.lon);
      if (cached != null && cached.hasAnyPlaceData) {
        return cached.withContinentFromCode();
      }

      final place = await _queue.reverse(rounded.lat, rounded.lon);
      final enriched = place?.withContinentFromCode();
      if (enriched != null && enriched.hasAnyPlaceData) {
        await _cache.put(rounded.lat, rounded.lon, enriched);
      }
      return enriched;
    } catch (_) {
      return null;
    }
  }

  /// Ortssuche mit demselben Rate-Limit (max. ~1 Anfrage/Sekunde).
  Future<List<NominatimSearchResult>> searchPlaces(String query) async {
    try {
      if (_lastSearchAt != null) {
        final elapsed = DateTime.now()
            .difference(_lastSearchAt!)
            .inMilliseconds;
        if (elapsed < 1100) {
          await Future<void>.delayed(Duration(milliseconds: 1100 - elapsed));
        }
      }
      _lastSearchAt = DateTime.now();
      final results = await _nominatim.search(query);
      return results
          .map(
            (r) => NominatimSearchResult(
              latitude: r.latitude,
              longitude: r.longitude,
              place: r.place.withContinentFromCode(),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }
}
