import 'package:memory_ai/core/errors/app_exception.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/features/memories/data/media_face_detection_model.dart';
import 'package:memory_ai/features/profile/data/face_recognition_data_store.dart';

/// Schreib-/Lösch-Schnittstelle (für Tests mockbar).
abstract class MediaFaceDetectionStore implements FaceRecognitionDataStore {
  Future<void> insertMany(List<MediaFaceDetectionModel> items);
}

/// Persistenz für `public.media_face_detections`.
class MediaFaceDetectionRepository implements MediaFaceDetectionStore {
  MediaFaceDetectionRepository();

  static final _client = SupabaseService.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AppException(message: 'Du bist nicht angemeldet.');
    }
    return id;
  }

  Future<List<MediaFaceDetectionModel>> listForMedia(String mediaId) async {
    try {
      final rows = await _client
          .from('media_face_detections')
          .select()
          .eq('media_id', mediaId)
          .eq('owner_id', _userId)
          .order('detected_at');

      return (rows as List)
          .map(
            (row) => MediaFaceDetectionModel.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  @override
  Future<void> insertMany(List<MediaFaceDetectionModel> items) async {
    if (items.isEmpty) return;
    try {
      await _client
          .from('media_face_detections')
          .insert(items.map((e) => e.toInsertJson()).toList());
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> linkPerson({
    required String detectionId,
    required String personId,
  }) async {
    try {
      await _client
          .from('media_face_detections')
          .update({'linked_person_id': personId})
          .eq('id', detectionId)
          .eq('owner_id', _userId);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Speichert Embedding nur owner-seitig (kein Public-/Signed-URL-Zugriff).
  Future<void> updateEmbedding({
    required String detectionId,
    required List<double> embedding,
  }) async {
    try {
      await _client
          .from('media_face_detections')
          .update({'embedding': embedding})
          .eq('id', detectionId)
          .eq('owner_id', _userId);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  @override
  Future<void> deleteAllForUser(String userId) async {
    try {
      final current = _client.auth.currentUser?.id;
      if (current == null || current != userId) {
        throw const AppException(
          message:
              'Gesichtsdaten können nur für das eigene Konto gelöscht werden.',
        );
      }
      await _client
          .from('media_face_detections')
          .delete()
          .eq('owner_id', userId);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }
}
