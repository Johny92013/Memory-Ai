import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memory_ai/features/upload/services/mp4_metadata_reader.dart';
import 'package:memory_ai/features/upload/services/video_metadata_extractor.dart';

void main() {
  group('Mp4MetadataReader', () {
    test('parst mvhd Dauer und Erstellungszeit', () {
      // Minimaler moov/mvhd (version 0): mvhd = 8 + 20 = 28, moov = 8 + 28 = 36
      final bytes = <int>[
        0x00, 0x00, 0x00, 0x24, 0x6D, 0x6F, 0x6F, 0x76, // moov
        0x00, 0x00, 0x00, 0x1C, 0x6D, 0x76, 0x68, 0x64, // mvhd
        0x00, 0x00, 0x00, 0x00, // version + flags
        0xDF, 0x0B, 0x5B, 0x00, // creation
        0xDF, 0x0B, 0x5B, 0x00, // modification
        0x00, 0x00, 0x03, 0xE8, // timescale 1000
        0x00, 0x00, 0x27, 0x10, // duration 10000 → 10s
      ];
      final meta = Mp4MetadataReader.parse(bytes);
      expect(meta.durationSeconds, 10);
      expect(meta.creationTime, isNotNull);
    });

    test('parst ©xyz GPS', () {
      final xyz = '+48.137+11.575/';
      final payload = <int>[
        0x00, 0x00, // lang
        0x00, xyz.length,
        ...xyz.codeUnits,
      ];
      // Atom type is 4 bytes: 0xA9 'x' 'y' 'z'
      final atom = <int>[
        0x00,
        0x00,
        0x00,
        8 + payload.length,
        0xA9,
        0x78,
        0x79,
        0x7A,
        ...payload,
      ];
      final meta = Mp4MetadataReader.parse(atom);
      expect(meta.latitude, closeTo(48.137, 0.001));
      expect(meta.longitude, closeTo(11.575, 0.001));
    });
  });

  group('VideoMetadataExtractor', () {
    test('Video ohne Metadaten stürzt nicht ab', () async {
      final extractor = VideoMetadataExtractor(
        thumbnailGenerator: (_) async => null,
      );
      final result = await extractor.extract(
        bytes: Uint8List.fromList([0x00, 0x01, 0x02, 0x03]),
        fileLastModified: DateTime(2024, 2, 2),
      );
      expect(result.takenAt, DateTime(2024, 2, 2));
      expect(result.dateSource, 'file');
      expect(result.locationSource, 'unknown');
      expect(result.hasGps, isFalse);
    });

    test('leere Bytes ohne Datei-Datum → unknown', () async {
      final extractor = VideoMetadataExtractor(
        thumbnailGenerator: (_) async => null,
      );
      final result = await extractor.extract(bytes: Uint8List(0));
      expect(result.takenAt, isNull);
      expect(result.dateSource, 'unknown');
      expect(result.metadataStatus, 'missing_location_and_date');
    });

    test('extrahiert Dauer aus Container-Bytes', () async {
      final container = <int>[
        0x00, 0x00, 0x00, 0x24, 0x6D, 0x6F, 0x6F, 0x76,
        0x00, 0x00, 0x00, 0x1C, 0x6D, 0x76, 0x68, 0x64,
        0x00, 0x00, 0x00, 0x00,
        0xDF, 0x0B, 0x5B, 0x00,
        0xDF, 0x0B, 0x5B, 0x00,
        0x00, 0x00, 0x03, 0xE8,
        0x00, 0x00, 0x13, 0x88, // 5000 → 5s
      ];
      final extractor = VideoMetadataExtractor(
        thumbnailGenerator: (_) async => Uint8List.fromList([0xFF, 0xD8]),
      );
      final result = await extractor.extract(
        bytes: Uint8List.fromList(container),
      );
      expect(result.durationSeconds, 5);
      expect(result.dateSource, 'video_metadata');
      expect(result.takenAt, isNotNull);
      expect(result.thumbnailJpeg, isNotNull);
    });
  });
}
