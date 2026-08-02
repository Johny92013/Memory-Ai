import 'dart:typed_data';

import 'package:memory_ai/features/memories/data/face_crop_helper.dart';
import 'package:memory_ai/features/memories/data/media_face_detection_model.dart';
import 'package:memory_ai/features/memories/data/media_face_detection_repository.dart';
import 'package:memory_ai/features/memories/data/people_repository.dart';
import 'package:memory_ai/features/people/data/face_embedding_engine.dart';
import 'package:memory_ai/features/people/data/face_reference_repository.dart';
import 'package:memory_ai/features/people/data/mobile_facenet_embedding_engine.dart';
import 'package:memory_ai/features/profile/data/biometric_consent_repository.dart';
import 'package:memory_ai/features/profile/data/profile_model.dart';
import 'package:memory_ai/core/services/supabase_service.dart';

/// Abgleich erkannte Gesichter → Vorschläge (nie Auto-Confirm).
class FaceMatchingService {
  FaceMatchingService({
    Future<bool> Function(String userId)? faceReferenceConsentCheck,
    Future<bool> Function(String userId)? familyMatchingConsentCheck,
    FaceEmbeddingEngine? engine,
    FaceReferenceRepository? referenceRepo,
    PeopleRepository? peopleRepo,
    MediaFaceDetectionRepository? detectionRepo,
  }) : _faceReferenceConsentCheck =
           faceReferenceConsentCheck ?? hasFaceReferenceConsent,
       _familyMatchingConsentCheck =
           familyMatchingConsentCheck ?? hasFamilyMatchingConsent,
       _engine = engine ?? createFaceEmbeddingEngine(),
       _referenceRepo = referenceRepo ?? FaceReferenceRepository(),
       _peopleRepo = peopleRepo ?? PeopleRepository(),
       _detectionRepo = detectionRepo ?? MediaFaceDetectionRepository();

  final Future<bool> Function(String userId) _faceReferenceConsentCheck;
  final Future<bool> Function(String userId) _familyMatchingConsentCheck;
  final FaceEmbeddingEngine _engine;
  final FaceReferenceRepository _referenceRepo;
  final PeopleRepository _peopleRepo;
  final MediaFaceDetectionRepository _detectionRepo;

  /// Nach Detection: Embeddings erzeugen und Vorschläge anlegen.
  Future<void> matchAfterDetection({
    required String mediaId,
    required String uploaderId,
    required List<int> imageBytes,
    required List<MediaFaceDetectionModel> detections,
  }) async {
    if (detections.isEmpty) return;

    final bytes = Uint8List.fromList(imageBytes);
    final faceEmbeddings = <List<double>>[];

    for (final detection in detections) {
      final crop = FaceCropHelper.cropRelative(
        imageBytes: bytes,
        box: detection.boundingBox,
        maxSide: 160,
      );
      if (crop == null) {
        faceEmbeddings.add(const []);
        continue;
      }
      final embedding = await _engine.embedFaceCrop(crop);
      faceEmbeddings.add(embedding);
      try {
        await _detectionRepo.updateEmbedding(
          detectionId: detection.id,
          embedding: embedding,
        );
      } catch (_) {
        // Embedding-Persistenz darf Matching nicht abbrechen.
      }
    }

    final allowSelf = await _faceReferenceConsentCheck(uploaderId);
    if (allowSelf) {
      await _suggestSelfMatches(
        mediaId: mediaId,
        uploaderId: uploaderId,
        faceEmbeddings: faceEmbeddings,
      );
    }

    final allowFamily = await _familyMatchingConsentCheck(uploaderId);
    if (allowFamily) {
      await _suggestFamilyMatches(
        mediaId: mediaId,
        faceEmbeddings: faceEmbeddings,
      );
    }
  }

  Future<void> _suggestSelfMatches({
    required String mediaId,
    required String uploaderId,
    required List<List<double>> faceEmbeddings,
  }) async {
    final refs = await _referenceRepo.listEmbeddingsForCurrentUser();
    if (refs.isEmpty) return;

    final best = _bestScoreAgainst(faceEmbeddings, refs);
    if (best < FaceEmbeddingMath.suggestionThreshold) return;

    final self = await _peopleRepo.findOrCreateSelf();
    await _peopleRepo.suggestPersonOnMedia(
      mediaId: mediaId,
      personId: self.id,
      source: 'face_recognition',
    );
  }

  Future<void> _suggestFamilyMatches({
    required String mediaId,
    required List<List<double>> faceEmbeddings,
  }) async {
    final familyEmbeddings = await _referenceRepo.listFamilyEmbeddings();
    if (familyEmbeddings.isEmpty) return;

    final names = await _displayNamesFor(familyEmbeddings.keys.toList());

    for (final entry in familyEmbeddings.entries) {
      final score = _bestScoreAgainst(faceEmbeddings, entry.value);
      if (score < FaceEmbeddingMath.suggestionThreshold) continue;

      final name = names[entry.key] ?? 'Familienmitglied';
      final person = await _peopleRepo.findOrCreateNamedPerson(name);
      await _peopleRepo.suggestPersonOnMedia(
        mediaId: mediaId,
        personId: person.id,
        source: 'face_recognition',
      );
    }
  }

  double _bestScoreAgainst(List<List<double>> faces, List<List<double>> refs) {
    var best = 0.0;
    for (final face in faces) {
      if (face.isEmpty) continue;
      for (final ref in refs) {
        final s = FaceEmbeddingMath.cosineSimilarity(face, ref);
        if (s > best) best = s;
      }
    }
    return best;
  }

  Future<Map<String, String>> _displayNamesFor(List<String> userIds) async {
    if (userIds.isEmpty) return {};
    try {
      final rows = await SupabaseService.client
          .from('profiles')
          .select()
          .inFilter('id', userIds);
      final result = <String, String>{};
      for (final row in rows as List) {
        final profile = ProfileModel.fromJson(
          Map<String, dynamic>.from(row as Map),
        );
        result[profile.id] = profile.displayName;
      }
      return result;
    } catch (_) {
      return {};
    }
  }
}
