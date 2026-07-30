import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Erzeugt JPEG-Thumbnails für die Galerie-Grid-Ansicht.
class ThumbnailService {
  ThumbnailService._();

  static const int maxThumbWidth = 400;

  /// Erstellt ein JPEG-Thumbnail (max. ~400px Breite).
  static Uint8List? createThumbnail(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final oriented = img.bakeOrientation(decoded);
      final thumb = img.copyResize(
        oriented,
        width: oriented.width > maxThumbWidth ? maxThumbWidth : oriented.width,
      );
      return Uint8List.fromList(img.encodeJpg(thumb, quality: 80));
    } catch (_) {
      return null;
    }
  }

  static int? decodeWidth(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      return decoded?.width;
    } catch (_) {
      return null;
    }
  }

  static int? decodeHeight(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      return decoded?.height;
    } catch (_) {
      return null;
    }
  }
}
