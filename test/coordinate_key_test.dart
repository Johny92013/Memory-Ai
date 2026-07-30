import 'package:flutter_test/flutter_test.dart';
import 'package:memory_ai/features/map/data/coordinate_key.dart';

void main() {
  group('CoordinateKey', () {
    test('rundet Koordinaten auf 4 Nachkommastellen', () {
      expect(CoordinateKey.roundCoordinate(48.123456789), 48.1235);
      expect(CoordinateKey.roundCoordinate(-11.99999), -12.0);
    });

    test('nahe Koordinaten erzeugen gleichen Cache-Key', () {
      final key1 = CoordinateKey.fromLatLon(48.12341, 11.56781);
      final key2 = CoordinateKey.fromLatLon(48.12344, 11.56784);
      expect(key1, key2);
    });

    test('unterschiedliche Koordinaten erzeugen verschiedene Keys', () {
      final key1 = CoordinateKey.fromLatLon(48.12, 11.56);
      final key2 = CoordinateKey.fromLatLon(48.13, 11.57);
      expect(key1, isNot(key2));
    });

    test('roundedPair nutzt groupingDecimals', () {
      final pair = CoordinateKey.roundedPair(52.518620, 13.404954);
      expect(pair.lat, 52.5186);
      expect(pair.lon, 13.405);
    });
  });
}
