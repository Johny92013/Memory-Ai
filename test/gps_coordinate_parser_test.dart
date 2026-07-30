import 'package:exif/exif.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_ai/features/memories/data/gps_coordinate_parser.dart';

IfdTag _gpsTag({required String printable, required List<Ratio> ratios}) {
  return IfdTag(
    tag: 0,
    tagType: 'Rational',
    printable: printable,
    values: IfdRatios(ratios),
  );
}

IfdTag _refTag(String ref) {
  return IfdTag(tag: 0, tagType: 'ASCII', printable: ref, values: IfdNone());
}

void main() {
  group('GpsCoordinateParser', () {
    test('parst nördliche/e östliche Koordinaten', () {
      final tags = <String, IfdTag>{
        'GPS GPSLatitude': _gpsTag(
          printable: '[48, 8, 0]',
          ratios: [Ratio(48, 1), Ratio(8, 1), Ratio(0, 1)],
        ),
        'GPS GPSLatitudeRef': _refTag('N'),
        'GPS GPSLongitude': _gpsTag(
          printable: '[11, 34, 0]',
          ratios: [Ratio(11, 1), Ratio(34, 1), Ratio(0, 1)],
        ),
        'GPS GPSLongitudeRef': _refTag('E'),
      };

      final lat = GpsCoordinateParser.parseCoordinate(
        tags,
        valueKey: 'GPS GPSLatitude',
        refKey: 'GPS GPSLatitudeRef',
        positiveRefs: {'N', 'n'},
      );
      final lon = GpsCoordinateParser.parseCoordinate(
        tags,
        valueKey: 'GPS GPSLongitude',
        refKey: 'GPS GPSLongitudeRef',
        positiveRefs: {'E', 'e'},
      );

      expect(lat, closeTo(48.133333, 0.001));
      expect(lon, closeTo(11.566667, 0.001));
    });

    test('parst südliche Koordinate negativ', () {
      final tags = <String, IfdTag>{
        'GPS GPSLatitude': _gpsTag(
          printable: '[33, 0, 0]',
          ratios: [Ratio(33, 1), Ratio(0, 1), Ratio(0, 1)],
        ),
        'GPS GPSLatitudeRef': _refTag('S'),
      };

      final lat = GpsCoordinateParser.parseCoordinate(
        tags,
        valueKey: 'GPS GPSLatitude',
        refKey: 'GPS GPSLatitudeRef',
        positiveRefs: {'N', 'n'},
      );
      expect(lat, -33);
    });
  });
}
