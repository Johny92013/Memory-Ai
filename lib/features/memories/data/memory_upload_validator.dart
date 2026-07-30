import 'package:memory_ai/core/constants/storage_constants.dart';
import 'package:memory_ai/core/errors/app_exception.dart';

/// Client-seitige Validierung für Familienfoto-Uploads.
class MemoryUploadValidator {
  MemoryUploadValidator._();

  static const String imageTooLargeCode = 'image_too_large';
  static const String invalidImageTypeCode = 'invalid_image_type';

  static const String videoTooLargeCode = 'video_too_large';
  static const String invalidVideoTypeCode = 'invalid_video_type';

  /// Wirft [AppException], wenn Größe oder MIME-Typ ungültig sind.
  static void validateImageBytes(List<int> bytes, String mimeType) {
    if (bytes.length > StorageConstants.maxFamilyImageBytes) {
      throw const AppException(
        message: 'Das Bild ist zu groß. Maximal 20 MB erlaubt.',
        code: imageTooLargeCode,
      );
    }

    if (!StorageConstants.allowedFamilyImageMimeTypes.contains(mimeType)) {
      throw const AppException(
        message:
            'Ungültiger Dateityp. Erlaubt sind JPEG, PNG, WebP, HEIC und HEIF.',
        code: invalidImageTypeCode,
      );
    }
  }

  static void validateVideoBytes(List<int> bytes, String mimeType) {
    if (bytes.length > StorageConstants.maxMediaVideoBytes) {
      throw const AppException(
        message: 'Das Video ist zu groß. Maximal 200 MB erlaubt.',
        code: videoTooLargeCode,
      );
    }

    final normalized = mimeType.toLowerCase().trim();
    if (!StorageConstants.allowedVideoMimeTypes.contains(normalized)) {
      throw const AppException(
        message: 'Ungültiger Videotyp. Erlaubt sind MP4 und MOV.',
        code: invalidVideoTypeCode,
      );
    }
  }
}
