import 'dart:typed_data';

import 'package:memory_ai/features/people/data/face_embedding_engine.dart';

/// Platzhalter für MobileFaceNet (TFLite).
///
/// Sobald `assets/models/mobilefacenet.tflite` vorliegt und `tflite_flutter`
/// für die Zielplattform eingebunden ist, hier Interpreter laden.
class MobileFaceNetEmbeddingEngine implements FaceEmbeddingEngine {
  MobileFaceNetEmbeddingEngine();

  static const assetPath = 'assets/models/mobilefacenet.tflite';
  static const modelVersion = 'mobilefacenet_v1';

  bool _ready = false;

  Future<void> ensureLoaded() async {
    // TODO(phase6): tflite_flutter Interpreter.fromAsset(assetPath)
    _ready = false;
  }

  @override
  Future<List<double>> embedFaceCrop(Uint8List jpegOrPngBytes) async {
    await ensureLoaded();
    if (!_ready) {
      throw StateError(
        'MobileFaceNet-Modell fehlt ($assetPath). '
        'Siehe assets/models/README.md',
      );
    }
    return FaceEmbeddingMath.l2Normalize(List.filled(192, 0));
  }

  @override
  Future<void> dispose() async {}
}

/// Factory: MobileFaceNet wenn bereit, sonst lokale Projektion.
FaceEmbeddingEngine createFaceEmbeddingEngine() {
  return LocalProjectionEmbeddingEngine(dimensions: 128, seed: 42);
}
