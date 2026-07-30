import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memory_ai/features/memories/data/exif_metadata_service.dart';

void main() {
  group('ExifMetadataService', () {
    test('resolveTakenAt bevorzugt DateTimeOriginal', () {
      final meta = PhotoExifMetadata(
        dateTimeOriginal: DateTime(2024, 6, 15, 10, 30),
        dateTimeDigitized: DateTime(2024, 6, 16),
        imageDateTime: DateTime(2024, 6, 17),
        fileLastModified: DateTime(2024, 6, 18),
      );
      expect(meta.resolveTakenAt(), DateTime(2024, 6, 15, 10, 30));
      expect(meta.resolveDateSource(), 'exif');
    });

    test('resolveTakenAt nutzt DateTimeDigitized als Fallback', () {
      final meta = PhotoExifMetadata(
        dateTimeDigitized: DateTime(2024, 3, 1, 8, 0),
        imageDateTime: DateTime(2024, 3, 2),
      );
      expect(meta.resolveTakenAt(), DateTime(2024, 3, 1, 8, 0));
      expect(meta.resolveDateSource(), 'exif');
    });

    test('resolveTakenAt nutzt Image DateTime vor Datei', () {
      final meta = PhotoExifMetadata(
        imageDateTime: DateTime(2024, 3, 2),
        fileLastModified: DateTime(2024, 3, 3),
      );
      expect(meta.resolveTakenAt(), DateTime(2024, 3, 2));
      expect(meta.resolveDateSource(), 'exif');
    });

    test('resolveTakenAt nutzt Dateierstellungsdatum zuletzt', () {
      final meta = PhotoExifMetadata(fileLastModified: DateTime(2024, 3, 3));
      expect(meta.resolveTakenAt(), DateTime(2024, 3, 3));
      expect(meta.resolveDateSource(), 'file');
    });

    test('resolveTakenAt nutzt manuelles Datum', () {
      final meta = PhotoExifMetadata();
      final manual = DateTime(2025, 1, 1);
      expect(meta.resolveTakenAt(manualDate: manual), manual);
      expect(meta.resolveDateSource(manualDate: manual), 'manual');
    });

    test('leere / ungültige Bytes führen nicht zum Absturz', () async {
      final result = await ExifMetadataService.read(
        Uint8List.fromList([0xFF, 0xD8]),
        fileLastModified: DateTime(2024, 1, 1),
      );
      expect(result.dateTimeOriginal, isNull);
      expect(result.fileLastModified, DateTime(2024, 1, 1));
      expect(result.resolveDateSource(), 'file');
      expect(result.resolveLocationSource(), 'unknown');
    });

    test('WebP-ähnliche Bytes ohne EXIF stürzen nicht ab', () async {
      // RIFF....WEBP Prefix ohne gültiges EXIF
      final bytes = Uint8List.fromList([
        0x52,
        0x49,
        0x46,
        0x46,
        0x00,
        0x00,
        0x00,
        0x00,
        0x57,
        0x45,
        0x42,
        0x50,
        0x00,
        0x00,
        0x00,
        0x00,
      ]);
      final result = await ExifMetadataService.read(bytes);
      expect(result.hasGps, isFalse);
      expect(result.resolveDateSource(), 'unknown');
      expect(result.resolveLocationSource(), 'unknown');
    });

    test('HEIC-ähnliche Bytes ohne EXIF stürzen nicht ab', () async {
      // ftypheic
      final bytes = Uint8List.fromList([
        0x00,
        0x00,
        0x00,
        0x18,
        0x66,
        0x74,
        0x79,
        0x70,
        0x68,
        0x65,
        0x69,
        0x63,
        0x00,
        0x00,
        0x00,
        0x00,
        0x6D,
        0x69,
        0x66,
        0x31,
        0x68,
        0x65,
        0x69,
        0x63,
      ]);
      final result = await ExifMetadataService.read(
        bytes,
        fileLastModified: DateTime(2023, 5, 5),
      );
      expect(result.dateTimeOriginal, isNull);
      expect(result.resolveDateSource(), 'file');
      expect(result.hasGps, isFalse);
    });
  });
}
