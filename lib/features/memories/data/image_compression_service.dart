import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:memory_ai/core/constants/storage_constants.dart';
import 'package:memory_ai/core/errors/app_exception.dart';

/// Ergebnis der Bildkompression.
class CompressedImage {
  const CompressedImage({
    required this.bytes,
    required this.mimeType,
    required this.extension,
    required this.wasCompressed,
  });

  final Uint8List bytes;
  final String mimeType;
  final String extension;
  final bool wasCompressed;
}

/// Komprimiert Familienfotos clientseitig auf ca. 2 MB.
class ImageCompressionService {
  ImageCompressionService._();

  static const int targetBytes = StorageConstants.targetFamilyImageBytes;

  /// Komprimiert [bytes] auf höchstens [targetBytes], sofern möglich.
  ///
  /// Behält die Auflösung möglichst bei und reduziert zuerst die JPEG-Qualität.
  /// Schlägt das Dekodieren fehl und die Datei ist bereits klein genug,
  /// wird das Original zurückgegeben.
  static CompressedImage compressForUpload({
    required Uint8List bytes,
    required String sourceMimeType,
  }) {
    if (bytes.lengthInBytes <= targetBytes) {
      return CompressedImage(
        bytes: bytes,
        mimeType: sourceMimeType,
        extension: _extensionForMime(sourceMimeType),
        wasCompressed: false,
      );
    }

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      if (bytes.lengthInBytes <= StorageConstants.maxFamilyImageBytes) {
        return CompressedImage(
          bytes: bytes,
          mimeType: sourceMimeType,
          extension: _extensionForMime(sourceMimeType),
          wasCompressed: false,
        );
      }
      throw const AppException(
        message:
            'Dieses Bildformat konnte nicht komprimiert werden und ist zu groß.',
        code: 'image_compress_failed',
      );
    }

    // Orientierungen aus EXIF anwenden, falls vorhanden.
    final oriented = img.bakeOrientation(decoded);

    var quality = 88;
    Uint8List? best;

    while (quality >= 40) {
      final encoded = Uint8List.fromList(
        img.encodeJpg(oriented, quality: quality),
      );
      best = encoded;
      if (encoded.lengthInBytes <= targetBytes) {
        return CompressedImage(
          bytes: encoded,
          mimeType: 'image/jpeg',
          extension: 'jpg',
          wasCompressed: true,
        );
      }
      quality -= 8;
    }

    // Noch zu groß: leichte Verkleinerung bei gleichbleibender Qualität.
    var working = oriented;
    var scale = 0.9;
    for (var i = 0; i < 6; i++) {
      final width = math.max(1, (working.width * scale).round());
      final height = math.max(1, (working.height * scale).round());
      working = img.copyResize(
        oriented,
        width: width,
        height: height,
        interpolation: img.Interpolation.linear,
      );
      final encoded = Uint8List.fromList(img.encodeJpg(working, quality: 75));
      best = encoded;
      if (encoded.lengthInBytes <= targetBytes) {
        return CompressedImage(
          bytes: encoded,
          mimeType: 'image/jpeg',
          extension: 'jpg',
          wasCompressed: true,
        );
      }
      scale *= 0.85;
    }

    if (best != null &&
        best.lengthInBytes <= StorageConstants.maxFamilyImageBytes) {
      return CompressedImage(
        bytes: best,
        mimeType: 'image/jpeg',
        extension: 'jpg',
        wasCompressed: true,
      );
    }

    throw const AppException(
      message:
          'Das Bild ist auch nach Kompression zu groß. Bitte wähle ein kleineres Foto.',
      code: 'image_too_large',
    );
  }

  static String _extensionForMime(String mimeType) {
    switch (mimeType) {
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      case 'image/heic':
        return 'heic';
      case 'image/heif':
        return 'heif';
      default:
        return 'jpg';
    }
  }
}
