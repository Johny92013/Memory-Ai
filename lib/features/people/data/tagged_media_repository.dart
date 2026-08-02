import 'package:memory_ai/core/errors/app_exception.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/features/people/data/tagged_media_models.dart';

/// Inbox und Freigabe für „Aufnahmen mit mir“ (Verknüpfung, keine Dateikopie).
class TaggedMediaRepository {
  TaggedMediaRepository();

  static final _client = SupabaseService.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AppException(message: 'Du bist nicht angemeldet.');
    }
    return id;
  }

  Future<List<TaggedMediaItem>> listForMe({List<String>? statuses}) async {
    try {
      final rows = await _client.rpc(
        'list_tagged_media_for_me',
        params: {'p_statuses': statuses},
      );
      return (rows as List)
          .map(
            (row) =>
                TaggedMediaItem.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } catch (_) {
      throw const AppException(
        message: 'Die Markierung konnte nicht geladen werden.',
      );
    }
  }

  Future<void> confirm(String tagId) async {
    await _updateStatus(
      tagId,
      MediaPersonStatus.confirmed,
      extra: {'confirmed_at': DateTime.now().toUtc().toIso8601String()},
    );
  }

  Future<void> reject(String tagId) async {
    await _updateStatus(
      tagId,
      MediaPersonStatus.rejected,
      extra: {'rejected_at': DateTime.now().toUtc().toIso8601String()},
    );
  }

  /// Übernimmt in die Galerie ohne Storage-Duplikat.
  Future<void> acceptToGallery(String tagId) async {
    await _updateStatus(
      tagId,
      MediaPersonStatus.acceptedToGallery,
      extra: {
        'confirmed_at': DateTime.now().toUtc().toIso8601String(),
        'added_to_gallery_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  Future<void> linkOnly(String tagId) async {
    await _updateStatus(
      tagId,
      MediaPersonStatus.linkedOnly,
      extra: {'confirmed_at': DateTime.now().toUtc().toIso8601String()},
    );
  }

  Future<void> _updateStatus(
    String tagId,
    String status, {
    Map<String, dynamic> extra = const {},
  }) async {
    try {
      final payload = <String, dynamic>{'status': status, ...extra};
      final updated = await _client
          .from('media_people')
          .update(payload)
          .eq('id', tagId)
          .eq('tagged_profile_id', _userId)
          .select('id');
      if ((updated as List).isEmpty) {
        throw const AppException(
          message: 'Die Personenzuordnung konnte nicht bestätigt werden.',
        );
      }
    } catch (error) {
      if (error is AppException) rethrow;
      throw ErrorMapper.map(error);
    }
  }

  Future<List<String>> listAcceptedGalleryMediaIds() async {
    try {
      final rows = await _client
          .from('media_people')
          .select('media_item_id')
          .eq('tagged_profile_id', _userId)
          .eq('status', MediaPersonStatus.acceptedToGallery);
      return (rows as List)
          .map((row) => (row as Map)['media_item_id'] as String?)
          .whereType<String>()
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }
}

/// In-App-Benachrichtigungen (kein Push).
class InAppNotificationRepository {
  InAppNotificationRepository();

  static final _client = SupabaseService.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AppException(message: 'Du bist nicht angemeldet.');
    }
    return id;
  }

  Future<List<InAppNotification>> listRecent({int limit = 30}) async {
    try {
      final rows = await _client
          .from('in_app_notifications')
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (rows as List)
          .map(
            (row) => InAppNotification.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<int> countUnread() async {
    try {
      final rows = await _client
          .from('in_app_notifications')
          .select('id')
          .eq('user_id', _userId)
          .isFilter('read_at', null);
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _client
          .from('in_app_notifications')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id)
          .eq('user_id', _userId);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _client
          .from('in_app_notifications')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('user_id', _userId)
          .isFilter('read_at', null);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> notifyPersonTagged({
    required String taggedProfileId,
    required String title,
    required String body,
    Map<String, dynamic> payload = const {},
  }) async {
    try {
      await _client.rpc(
        'notify_person_tagged',
        params: {
          'p_tagged_profile_id': taggedProfileId,
          'p_title': title,
          'p_body': body,
          'p_payload': payload,
        },
      );
    } catch (_) {
      // Benachrichtigung ist best-effort – Tag darf trotzdem speichern.
    }
  }
}
