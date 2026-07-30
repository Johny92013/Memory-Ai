import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:memory_ai/core/constants/storage_constants.dart';
import 'package:memory_ai/features/memories/data/image_compression_service.dart';

void main() {
  group('ImageCompressionService', () {
    test('lässt kleine Bilder unverändert', () {
      final image = img.Image(width: 32, height: 32);
      final bytes = Uint8List.fromList(img.encodeJpg(image, quality: 90));

      final result = ImageCompressionService.compressForUpload(
        bytes: bytes,
        sourceMimeType: 'image/jpeg',
      );

      expect(result.wasCompressed, isFalse);
      expect(result.bytes.lengthInBytes, bytes.lengthInBytes);
    });

    test('komprimiert große Bilder unter das Ziel von ~2 MB', () {
      // Künstlich großes unkomprimiertes Muster → JPEG wird groß genug.
      final image = img.Image(width: 4000, height: 3000);
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          image.setPixelRgba(x, y, x % 255, y % 255, (x + y) % 255, 255);
        }
      }
      final bytes = Uint8List.fromList(img.encodeJpg(image, quality: 100));
      expect(
        bytes.lengthInBytes,
        greaterThan(StorageConstants.targetFamilyImageBytes),
      );

      final result = ImageCompressionService.compressForUpload(
        bytes: bytes,
        sourceMimeType: 'image/jpeg',
      );

      expect(result.wasCompressed, isTrue);
      expect(result.mimeType, 'image/jpeg');
      expect(
        result.bytes.lengthInBytes,
        lessThanOrEqualTo(StorageConstants.targetFamilyImageBytes),
      );
    });
  });
}
