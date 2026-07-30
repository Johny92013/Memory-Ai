import 'package:memory_ai/features/memories/data/face_detector_engine.dart';

/// Stub für Plattformen ohne ML Kit (Web/Desktop-Tests).
class MlKitFaceDetectorEngine implements FaceDetectorEngine {
  MlKitFaceDetectorEngine();

  @override
  Future<List<DetectedFaceBox>> detectFaces({
    required List<int> imageBytes,
    required int imageWidth,
    required int imageHeight,
  }) async {
    return const [];
  }

  @override
  Future<void> dispose() async {}
}
