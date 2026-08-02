import 'dart:typed_data';

import 'package:exif/exif.dart';
import 'package:memory_ai/features/memories/data/gps_coordinate_parser.dart';

/// Vollständige EXIF-Metadaten für den Foto-Upload.
class PhotoExifMetadata {
  const PhotoExifMetadata({
    this.dateTimeOriginal,
    this.dateTimeDigitized,
    this.createDateTag,
    this.imageDateTime,
    this.dateModifiedTag,
    this.fileLastModified,
    this.latitude,
    this.longitude,
    this.altitude,
    this.orientation,
    this.make,
    this.model,
    this.imageWidth,
    this.imageHeight,
    this.rawExifJson = const {},
  });

  final DateTime? dateTimeOriginal;
  final DateTime? dateTimeDigitized;

  /// EXIF CreateDate / Media CreateDate (falls vorhanden).
  final DateTime? createDateTag;
  final DateTime? imageDateTime;

  /// EXIF DateModified / ModifyDate.
  final DateTime? dateModifiedTag;
  final DateTime? fileLastModified;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final int? orientation;
  final String? make;
  final String? model;
  final int? imageWidth;
  final int? imageHeight;
  final Map<String, dynamic> rawExifJson;

  /// Alias für ältere Aufrufer (DateTimeDigitized / CreateDate).
  DateTime? get createDate =>
      createDateTag ?? dateTimeDigitized ?? imageDateTime;

  /// Alias für Dateierstellungs-/Änderungsdatum.
  DateTime? get dateModified =>
      dateModifiedTag ?? fileLastModified ?? imageDateTime;

  bool get hasGps => latitude != null && longitude != null;

  /// Priorität: Manual → DateTimeOriginal → Digitized → CreateDate →
  /// Image DateTime → DateModified → Dateisystem.
  DateTime? resolveTakenAt({DateTime? manualDate}) {
    if (manualDate != null) return manualDate;
    return dateTimeOriginal ??
        dateTimeDigitized ??
        createDateTag ??
        imageDateTime ??
        dateModifiedTag ??
        fileLastModified;
  }

  /// Quelle von [resolveTakenAt] ohne manuelles Override.
  String resolveDateSource({DateTime? manualDate}) {
    if (manualDate != null) return 'manual';
    if (dateTimeOriginal != null) return 'exif';
    if (dateTimeDigitized != null) return 'exif';
    if (createDateTag != null) return 'exif';
    if (imageDateTime != null) return 'exif';
    if (dateModifiedTag != null) return 'exif';
    if (fileLastModified != null) return 'file';
    return 'unknown';
  }

  /// Debug-Diagnose (nur für Logs in Debug-Builds).
  String debugDateSourceLabel({DateTime? manualDate}) {
    if (manualDate != null) return 'manual';
    if (dateTimeOriginal != null) return 'DateTimeOriginal';
    if (dateTimeDigitized != null) return 'DateTimeDigitized';
    if (createDateTag != null) return 'CreateDate';
    if (imageDateTime != null) return 'ImageDateTime';
    if (dateModifiedTag != null) return 'DateModified';
    if (fileLastModified != null) return 'FileSystem';
    return 'unknown';
  }

  String resolveLocationSource() => hasGps ? 'exif' : 'unknown';

  PhotoExifMetadata copyWith({
    DateTime? dateTimeOriginal,
    DateTime? dateTimeDigitized,
    DateTime? createDateTag,
    DateTime? imageDateTime,
    DateTime? dateModifiedTag,
    DateTime? fileLastModified,
    double? latitude,
    double? longitude,
    double? altitude,
    int? orientation,
    String? make,
    String? model,
    int? imageWidth,
    int? imageHeight,
    Map<String, dynamic>? rawExifJson,
    bool clearLatitude = false,
    bool clearLongitude = false,
    bool clearAltitude = false,
  }) {
    return PhotoExifMetadata(
      dateTimeOriginal: dateTimeOriginal ?? this.dateTimeOriginal,
      dateTimeDigitized: dateTimeDigitized ?? this.dateTimeDigitized,
      createDateTag: createDateTag ?? this.createDateTag,
      imageDateTime: imageDateTime ?? this.imageDateTime,
      dateModifiedTag: dateModifiedTag ?? this.dateModifiedTag,
      fileLastModified: fileLastModified ?? this.fileLastModified,
      latitude: clearLatitude ? null : (latitude ?? this.latitude),
      longitude: clearLongitude ? null : (longitude ?? this.longitude),
      altitude: clearAltitude ? null : (altitude ?? this.altitude),
      orientation: orientation ?? this.orientation,
      make: make ?? this.make,
      model: model ?? this.model,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      rawExifJson: rawExifJson ?? this.rawExifJson,
    );
  }
}

/// Liest EXIF aus Bild-Bytes. Fehler führen nicht zum Absturz.
/// Unterstützt JPEG/PNG und versucht HEIC/WebP best-effort (oft ohne EXIF).
class ExifMetadataService {
  ExifMetadataService._();

  static Future<PhotoExifMetadata> read(
    Uint8List bytes, {
    DateTime? fileLastModified,
  }) async {
    try {
      final tags = await readExifFromBytes(bytes);
      if (tags.isEmpty) {
        return PhotoExifMetadata(
          fileLastModified: fileLastModified,
          rawExifJson: const {},
        );
      }

      final raw = <String, dynamic>{};
      for (final entry in tags.entries) {
        raw[entry.key] = entry.value.printable;
      }

      return PhotoExifMetadata(
        dateTimeOriginal: _parseExifDateTime(
          tags['EXIF DateTimeOriginal']?.printable,
        ),
        dateTimeDigitized: _parseExifDateTime(
          tags['EXIF DateTimeDigitized']?.printable,
        ),
        createDateTag: _parseExifDateTime(
          tags['EXIF CreateDate']?.printable ??
              tags['Image CreateDate']?.printable ??
              tags['EXIF MediaCreateDate']?.printable,
        ),
        imageDateTime: _parseExifDateTime(tags['Image DateTime']?.printable),
        dateModifiedTag: _parseExifDateTime(
          tags['EXIF ModifyDate']?.printable ??
              tags['Image ModifyDate']?.printable ??
              tags['EXIF DateModified']?.printable,
        ),
        fileLastModified: fileLastModified,
        latitude: GpsCoordinateParser.parseCoordinate(
          tags,
          valueKey: 'GPS GPSLatitude',
          refKey: 'GPS GPSLatitudeRef',
          positiveRefs: {'N', 'n'},
        ),
        longitude: GpsCoordinateParser.parseCoordinate(
          tags,
          valueKey: 'GPS GPSLongitude',
          refKey: 'GPS GPSLongitudeRef',
          positiveRefs: {'E', 'e'},
        ),
        altitude: GpsCoordinateParser.parseAltitude(tags),
        orientation:
            _parseInt(tags['Image Orientation']?.printable) ??
            _parseInt(tags['EXIF Orientation']?.printable),
        make: tags['Image Make']?.printable.trim(),
        model: tags['Image Model']?.printable.trim(),
        imageWidth:
            _parseInt(tags['EXIF ExifImageWidth']?.printable) ??
            _parseInt(tags['EXIF PixelXDimension']?.printable),
        imageHeight:
            _parseInt(tags['EXIF ExifImageLength']?.printable) ??
            _parseInt(tags['EXIF PixelYDimension']?.printable),
        rawExifJson: raw,
      );
    } catch (_) {
      // Screenshot / Messenger / HEIC ohne lesbares EXIF → kein Abbruch
      return PhotoExifMetadata(fileLastModified: fileLastModified);
    }
  }

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

  static int? _parseInt(String? raw) {
    if (raw == null) return null;
    return int.tryParse(raw.trim());
  }
}
