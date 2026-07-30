import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:memory_ai/features/memories/data/media_face_detection_model.dart';

/// Schneidet Gesichtsausschnitte aus Bildbytes anhand relativer Boxes.
abstract final class FaceCropHelper {
  static Future<Uint8List?> loadImageBytes(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      return response.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  static Uint8List? cropRelative({
    required Uint8List imageBytes,
    required FaceBoundingBox box,
    int maxSide = 160,
  }) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return null;

    final left = (box.x * decoded.width).floor().clamp(0, decoded.width - 1);
    final top = (box.y * decoded.height).floor().clamp(0, decoded.height - 1);
    final width = (box.width * decoded.width).ceil().clamp(
      1,
      decoded.width - left,
    );
    final height = (box.height * decoded.height).ceil().clamp(
      1,
      decoded.height - top,
    );

    final cropped = img.copyCrop(
      decoded,
      x: left,
      y: top,
      width: width,
      height: height,
    );
    final resized = img.copyResize(
      cropped,
      width: cropped.width >= cropped.height ? maxSide : null,
      height: cropped.height > cropped.width ? maxSide : null,
    );
    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }
}
