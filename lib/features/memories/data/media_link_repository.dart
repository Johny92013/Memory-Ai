import 'package:memory_ai/core/errors/app_exception.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/features/memories/data/media_link_model.dart';

/// Persistenz für `public.media_links` (keine Dateikopien).
class MediaLinkRepository {
  MediaLinkRepository();

  static final _client = SupabaseService.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AppException(message: 'Du bist nicht angemeldet.');
    }
    return id;
  }

  Future<List<MediaLinkModel>> listForMedia(
    String mediaId, {
    String? status,
  }) async {
    try {
      var query = _client
          .from('media_links')
          .select()
          .or('source_media_id.eq.$mediaId,related_media_id.eq.$mediaId');
      if (status != null) {
        query = query.eq('status', status);
      }
      final rows = await query.order('created_at', ascending: false);
      return (rows as List)
          .map(
            (row) =>
                MediaLinkModel.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<MediaLinkModel> upsertSuggestion(
    RelatedMediaCandidate candidate,
  ) async {
    try {
      final row = await _client
          .from('media_links')
          .upsert({
            'source_media_id': candidate.sourceMediaId,
            'related_media_id': candidate.relatedMediaId,
            'relation_type': candidate.relationType,
            'confidence': candidate.confidence,
            'status': 'suggested',
            'created_by': _userId,
          }, onConflict: 'source_media_id,related_media_id,relation_type')
          .select()
          .single();
      return MediaLinkModel.fromJson(Map<String, dynamic>.from(row));
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> updateStatus({
    required String linkId,
    required String status,
  }) async {
    if (status != 'confirmed' &&
        status != 'rejected' &&
        status != 'suggested') {
      throw const AppException(message: 'Ungültiger Verknüpfungsstatus.');
    }
    try {
      await _client
          .from('media_links')
          .update({'status': status})
          .eq('id', linkId);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<MediaLinkModel> createManualLink({
    required String sourceMediaId,
    required String relatedMediaId,
    String relationType = 'manual',
  }) async {
    try {
      final row = await _client
          .from('media_links')
          .insert({
            'source_media_id': sourceMediaId,
            'related_media_id': relatedMediaId,
            'relation_type': relationType,
            'confidence': 1.0,
            'status': 'confirmed',
            'created_by': _userId,
          })
          .select()
          .single();
      return MediaLinkModel.fromJson(Map<String, dynamic>.from(row));
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }
}
