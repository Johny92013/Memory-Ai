import 'package:flutter_test/flutter_test.dart';
import 'package:memory_ai/features/map/data/coordinate_key.dart';
import 'package:memory_ai/features/map/data/location_place_model.dart';
import 'package:memory_ai/features/map/data/nominatim_rate_limit_queue.dart';

void main() {
  group('NominatimRateLimitQueue', () {
    test('wartet mindestens 1100ms zwischen zwei Anfragen', () async {
      final timestamps = <int>[];
      final queue = NominatimRateLimitQueue(
        minDelayMs: 1100,
        executor: (lat, lon) async {
          timestamps.add(DateTime.now().millisecondsSinceEpoch);
          return const LocationPlace(country: 'Test', city: 'City');
        },
      );

      await queue.reverse(1.0, 1.0);
      await queue.reverse(2.0, 2.0);

      expect(timestamps.length, 2);
      expect(timestamps[1] - timestamps[0], greaterThanOrEqualTo(1100));
    });

    test('bündelt nahe Koordinaten zu einer Anfrage', () async {
      var callCount = 0;
      final queue = NominatimRateLimitQueue(
        minDelayMs: 0,
        executor: (lat, lon) async {
          callCount++;
          return LocationPlace(country: 'Bundled', city: 'City');
        },
      );

      final key = CoordinateKey.fromLatLon(48.12341, 11.56781);
      final futures = <Future<LocationPlace?>>[];
      for (var i = 0; i < 10; i++) {
        futures.add(queue.reverse(48.12341, 11.56781));
      }

      final results = await Future.wait(futures);
      expect(callCount, 1);
      expect(results.every((r) => r?.country == 'Bundled'), isTrue);
      expect(CoordinateKey.fromLatLon(48.12341, 11.56781), key);
    });
  });
}
