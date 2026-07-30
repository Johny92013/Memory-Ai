import 'package:exif/exif.dart';

/// Konvertiert EXIF-GPS-Rationalwerte in Dezimalkoordinaten.
class GpsCoordinateParser {
  GpsCoordinateParser._();

  static double? parseCoordinate(
    Map<String, IfdTag> tags, {
    required String valueKey,
    required String refKey,
    required Set<String> positiveRefs,
  }) {
    final valueTag = tags[valueKey];
    final refTag = tags[refKey];
    if (valueTag == null) return null;

    try {
      final values = valueTag.values.toList();
      if (values.length < 3) return null;

      final degrees = _ratioToDouble(values[0]);
      final minutes = _ratioToDouble(values[1]);
      final seconds = _ratioToDouble(values[2]);
      if (degrees == null || minutes == null || seconds == null) return null;

      var decimal = degrees + (minutes / 60.0) + (seconds / 3600.0);
      final ref = refTag?.printable.trim() ?? '';
      if (ref.isNotEmpty && !positiveRefs.contains(ref)) {
        decimal = -decimal;
      }
      if (decimal.isNaN || decimal.isInfinite) return null;
      return decimal;
    } catch (_) {
      return null;
    }
  }

  static double? parseAltitude(Map<String, IfdTag> tags) {
    final altTag = tags['GPS GPSAltitude'];
    if (altTag == null) return null;
    final values = altTag.values.toList();
    if (values.isEmpty) return null;
    final value = _ratioToDouble(values.first);
    if (value == null) return null;
    final ref = tags['GPS GPSAltitudeRef']?.printable.trim() ?? '0';
    return ref == '1' ? -value : value;
  }

  static double? _ratioToDouble(Object value) {
    if (value is num) return value.toDouble();
    if (value is Ratio) {
      if (value.denominator == 0) return null;
      return value.numerator / value.denominator;
    }
    final text = value.toString();
    if (text.contains('/')) {
      final parts = text.split('/');
      if (parts.length == 2) {
        final nume = double.tryParse(parts[0]);
        final deno = double.tryParse(parts[1]);
        if (nume != null && deno != null && deno != 0) {
          return nume / deno;
        }
      }
    }
    return double.tryParse(text);
  }
}
