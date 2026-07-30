import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:memory_ai/core/constants/storage_constants.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/features/memories/data/memory_upload_validator.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Hilfsdienst zum Auswählen und Hochladen von Bildern.
class ImageService {
  ImageService._();

  static final ImagePicker _picker = ImagePicker();

  /// Wählt ein Bild aus der Galerie aus.
  static Future<XFile?> pickImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    return _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  /// Wählt ein Familienfoto aus (komprimiert, max. 2048 px).
  static Future<XFile?> pickFamilyImage() {
    return pickImage(maxWidth: 2048, imageQuality: 85);
  }

  /// Wählt mehrere Bilder aus der Galerie aus.
  static Future<List<XFile>> pickMultipleImages({int? limit}) async {
    return _picker.pickMultiImage(imageQuality: 90, limit: limit);
  }

  static Future<Uint8List> readBytes(XFile file) => file.readAsBytes();

  /// Validiert Größe und MIME-Typ client-seitig.
  static void validateImageBytes(List<int> bytes, String mimeType) {
    MemoryUploadValidator.validateImageBytes(bytes, mimeType);
  }

  /// Ermittelt MIME-Typ aus Dateiname oder Bytes.
  static String detectMimeType(XFile file, List<int> bytes) {
    return lookupMimeType(file.path, headerBytes: bytes) ?? 'image/jpeg';
  }

  static Future<String> uploadAvatar({
    required String userId,
    required XFile file,
  }) async {
    final bytes = await file.readAsBytes();
    final extension = p.extension(file.path).replaceFirst('.', '');
    final contentType = detectMimeType(file, bytes);
    final objectPath = '$userId/${const Uuid().v4()}.$extension';

    await SupabaseService.client.storage
        .from(StorageConstants.avatars)
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    return objectPath;
  }
}
