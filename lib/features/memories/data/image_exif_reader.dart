import 'dart:typed_data';

import 'package:exif/exif.dart';

/// Metadaten aus dem EXIF-Block einer Bilddatei.
class ImageExifData {
  const ImageExifData({this.takenAt, this.latitude, this.longitude});

  final DateTime? takenAt;
  final double? latitude;
  final double? longitude;
}

/// Liest Aufnahmedatum und GPS aus Bild-Bytes.
///
/// Fehlende oder ungültige EXIF-Daten führen nicht zu einem Fehler.
class ImageExifReader {
  ImageExifReader._();

  /// Extrahiert Metadaten. Bei Fehlern wird ein leeres [ImageExifData] geliefert.
  static Future<ImageExifData> read(Uint8List bytes) async {
    try {
      final tags = await readExifFromBytes(bytes);
      if (tags.isEmpty) {
        return const ImageExifData();
      }

      return ImageExifData(
        takenAt: _parseTakenAt(tags),
        latitude: _parseGpsCoordinate(
          tags,
          valueKey: 'GPS GPSLatitude',
          refKey: 'GPS GPSLatitudeRef',
          positiveRefs: {'N', 'n'},
        ),
        longitude: _parseGpsCoordinate(
          tags,
          valueKey: 'GPS GPSLongitude',
          refKey: 'GPS GPSLongitudeRef',
          positiveRefs: {'E', 'e'},
        ),
      );
    } catch (_) {
      return const ImageExifData();
    }
  }

  static DateTime? _parseTakenAt(Map<String, IfdTag> tags) {
    final candidates = [
      tags['EXIF DateTimeOriginal']?.printable,
      tags['EXIF DateTimeDigitized']?.printable,
      tags['Image DateTime']?.printable,
    ];

    for (final raw in candidates) {
      final parsed = _parseExifDateTime(raw);
      if (parsed != null) return parsed;
    }
    return null;
  }

  /// EXIF-Format: `yyyy:MM:dd HH:mm:ss`
  static DateTime? _parseExifDateTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final normalized = raw.trim();
    if (normalized.length >= 19 && normalized[4] == ':') {
      final datePart = normalized.substring(0, 10).replaceAll(':', '-');
      final timePart = normalized.substring(11, 19);
      return DateTime.tryParse('${datePart}T$timePart');
    }
    return DateTime.tryParse(normalized);
  }

  static double? _parseGpsCoordinate(
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
