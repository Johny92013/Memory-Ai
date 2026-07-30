import 'package:memory_ai/features/memories/data/face_detector_engine.dart';
import 'package:memory_ai/features/memories/data/media_face_detection_model.dart';
import 'package:memory_ai/features/memories/data/media_face_detection_repository.dart';
import 'package:memory_ai/features/memories/data/ml_kit_face_detector_engine.dart';
import 'package:memory_ai/features/people/data/face_matching_service.dart';
import 'package:memory_ai/features/profile/data/biometric_consent_repository.dart';
import 'package:uuid/uuid.dart';

/// Orchestriert Consent-Guard + lokale Detection + Speicherung.
class MediaFaceDetectionService {
  MediaFaceDetectionService({
    Future<bool> Function(String userId)? consentCheck,
    FaceDetectorEngine? engine,
    MediaFaceDetectionStore? repository,
    FaceMatchingService? matchingService,
  }) : _consentCheck = consentCheck ?? hasFaceRecognitionConsent,
       _engine = engine,
       _repository = repository ?? MediaFaceDetectionRepository(),
       _matchingService = matchingService ?? FaceMatchingService(),
       _ownsEngine = engine == null;

  final Future<bool> Function(String userId) _consentCheck;
  FaceDetectorEngine? _engine;
  final MediaFaceDetectionStore _repository;
  final FaceMatchingService _matchingService;
  final bool _ownsEngine;

  /// Nach Upload: bei Einwilligung asynchron Detection ausführen.
  /// Ohne Einwilligung: stiller Skip (kein Fehler, kein Hinweis).
  Future<List<MediaFaceDetectionModel>> processAfterUpload({
    required String mediaId,
    required String ownerId,
    required List<int> imageBytes,
    required int imageWidth,
    required int imageHeight,
  }) async {
    final allowed = await _consentCheck(ownerId);
    if (!allowed) return const [];

    FaceDetectorEngine? engine;
    try {
      engine = _engine ??= MlKitFaceDetectorEngine();
      final detected = await engine.detectFaces(
        imageBytes: imageBytes,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
      );

      if (detected.isEmpty) return const [];

      final models = detected
          .map(
            (d) => MediaFaceDetectionModel(
              id: const Uuid().v4(),
              mediaId: mediaId,
              ownerId: ownerId,
              boundingBox: FaceBoundingBox(
                x: d.boundingBox.x,
                y: d.boundingBox.y,
                width: d.boundingBox.width,
                height: d.boundingBox.height,
              ),
              confidence: d.confidence,
              source: 'ml_kit',
            ),
          )
          .toList();

      await _repository.insertMany(models);

      try {
        await _matchingService.matchAfterDetection(
          mediaId: mediaId,
          uploaderId: ownerId,
          imageBytes: imageBytes,
          detections: models,
        );
      } catch (_) {
        // Matching darf Detection/Upload nie stören.
      }

      return models;
    } catch (_) {
      // Detection darf den Upload nie stören.
      return const [];
    } finally {
      if (_ownsEngine && engine != null) {
        try {
          await engine.dispose();
        } catch (_) {}
        _engine = null;
      }
    }
  }
}
