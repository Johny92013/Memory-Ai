import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:memory_ai/features/memories/data/face_detector_engine.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// ML-Kit-Implementierung (lokal, Android/iOS).
class MlKitFaceDetectorEngine implements FaceDetectorEngine {
  MlKitFaceDetectorEngine({FaceDetector? detector})
    : _detector =
          detector ??
          FaceDetector(
            options: FaceDetectorOptions(
              performanceMode: FaceDetectorMode.fast,
              enableContours: false,
              enableLandmarks: false,
              enableClassification: false,
              enableTracking: false,
            ),
          );

  final FaceDetector _detector;

  @override
  Future<List<DetectedFaceBox>> detectFaces({
    required List<int> imageBytes,
    required int imageWidth,
    required int imageHeight,
  }) async {
    if (imageWidth <= 0 || imageHeight <= 0 || imageBytes.isEmpty) {
      return const [];
    }

    final dir = await getTemporaryDirectory();
    final file = File(
      p.join(
        dir.path,
        'face_detect_${DateTime.now().microsecondsSinceEpoch}.jpg',
      ),
    );
    try {
      await file.writeAsBytes(Uint8List.fromList(imageBytes), flush: true);
      final input = InputImage.fromFilePath(file.path);
      final faces = await _detector.processImage(input);

      final w = imageWidth.toDouble();
      final h = imageHeight.toDouble();

      return faces.map((face) {
        final box = face.boundingBox;
        final relX = (box.left / w).clamp(0.0, 1.0);
        final relY = (box.top / h).clamp(0.0, 1.0);
        final relW = (box.width / w).clamp(0.0, 1.0 - relX);
        final relH = (box.height / h).clamp(0.0, 1.0 - relY);
        return DetectedFaceBox(
          boundingBox: (x: relX, y: relY, width: relW, height: relH),
          confidence: null,
        );
      }).toList();
    } finally {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  @override
  Future<void> dispose() => _detector.close();
}
