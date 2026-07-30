/// Ergebnis einer lokalen Detection (noch ohne DB-ID).
class DetectedFaceBox {
  const DetectedFaceBox({required this.boundingBox, this.confidence});

  final ({double x, double y, double width, double height}) boundingBox;
  final double? confidence;
}

/// Abstraktion über ML Kit – testbar ohne natives Plugin.
abstract class FaceDetectorEngine {
  Future<List<DetectedFaceBox>> detectFaces({
    required List<int> imageBytes,
    required int imageWidth,
    required int imageHeight,
  });

  Future<void> dispose();
}
