import 'package:memory_ai/core/errors/app_exception.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/features/memories/data/person_model.dart';
import 'package:memory_ai/features/people/data/tagged_media_models.dart';
import 'package:memory_ai/features/people/data/tagged_media_repository.dart';

/// Personen und Zuordnung zu Medien (`people` / `media_people`).
class PeopleRepository {
  PeopleRepository();

  static final _client = SupabaseService.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AppException(message: 'Du bist nicht angemeldet.');
    }
    return id;
  }

  Future<List<PersonModel>> listMyPeople() async {
    try {
      final rows = await _client
          .from('people')
          .select()
          .eq('owner_id', _userId)
          .order('name');
      return (rows as List)
          .map(
            (row) =>
                PersonModel.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<PersonModel> createPerson(String name) async {
    try {
      final trimmed = name.trim();
      if (trimmed.isEmpty) {
        throw const AppException(message: 'Bitte einen Namen eingeben.');
      }
      final row = await _client
          .from('people')
          .insert({
            'owner_id': _userId,
            'name': trimmed,
            'detection_source': 'manual',
          })
          .select()
          .single();
      return PersonModel.fromJson(Map<String, dynamic>.from(row));
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Findet oder legt „Ich“/„du“ als Person an.
  Future<PersonModel> findOrCreateSelf({String? displayName}) async {
    final name = (displayName == null || displayName.trim().isEmpty)
        ? 'du'
        : displayName.trim();
    final existing = await listMyPeople();
    for (final p in existing) {
      final n = p.name.toLowerCase();
      if (n == name.toLowerCase() || n == 'ich' || n == 'du') {
        return p;
      }
    }
    return createPerson(name);
  }

  /// Legt/findet Person nach Anzeigename (z. B. Familienmitglied).
  Future<PersonModel> findOrCreateNamedPerson(String name) async {
    final trimmed = name.trim();
    final existing = await listMyPeople();
    for (final p in existing) {
      if (p.name.toLowerCase() == trimmed.toLowerCase()) return p;
    }
    return createPerson(trimmed);
  }

  /// Ordnet eine Person einem Medium zu.
  ///
  /// Wenn [taggedProfileId] gesetzt ist und nicht der aktuelle Nutzer, wird
  /// `pending_confirmation` gesetzt und eine In-App-Benachrichtigung erzeugt.
  /// Es wird keine Storage-Datei kopiert.
  Future<void> assignPersonToMedia({
    required String mediaId,
    required String personId,
    String source = 'manual',
    String status = 'confirmed',
    String? taggedProfileId,
    bool notifyTaggedUser = true,
  }) async {
    try {
      final me = _userId;
      final tagged = taggedProfileId != null && taggedProfileId.isNotEmpty
          ? taggedProfileId
          : null;
      final needsConfirmation = tagged != null && tagged != me;
      final resolvedStatus = needsConfirmation
          ? MediaPersonStatus.pendingConfirmation
          : status;
      final resolvedSource = needsConfirmation && source == 'manual'
          ? 'family_tag'
          : source;

      await _client.from('media_people').upsert({
        'media_item_id': mediaId,
        'person_id': personId,
        'source': resolvedSource,
        'status': resolvedStatus,
        'tagged_profile_id': tagged,
        'tagged_by': me,
        if (needsConfirmation) 'confirmed_at': null,
        if (needsConfirmation) 'rejected_at': null,
        if (needsConfirmation) 'added_to_gallery_at': null,
      }, onConflict: 'media_item_id,person_id');

      if (needsConfirmation && notifyTaggedUser) {
        await InAppNotificationRepository().notifyPersonTagged(
          taggedProfileId: tagged,
          title: 'Neue Markierung',
          body: 'Du wurdest auf einer Erinnerung markiert.',
          payload: {'media_id': mediaId, 'route': '/profile/tagged-media'},
        );
      }
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Vorschlag anlegen – überspringt abgelehnte Einträge (kein Re-Suggest).
  Future<void> suggestPersonOnMedia({
    required String mediaId,
    required String personId,
    String source = 'face_recognition',
  }) async {
    try {
      final existing = await _client
          .from('media_people')
          .select('status')
          .eq('media_item_id', mediaId)
          .eq('person_id', personId)
          .maybeSingle();
      if (existing != null) {
        final status = existing['status'] as String?;
        if (status == 'rejected' || status == 'confirmed') return;
      }
      await assignPersonToMedia(
        mediaId: mediaId,
        personId: personId,
        source: source,
        status: 'suggested',
      );
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> setMediaPersonStatus({
    required String mediaId,
    required String personId,
    required String status,
  }) async {
    try {
      await _client
          .from('media_people')
          .update({'status': status})
          .eq('media_item_id', mediaId)
          .eq('person_id', personId);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> unassignPersonFromMedia({
    required String mediaId,
    required String personId,
  }) async {
    try {
      await _client
          .from('media_people')
          .delete()
          .eq('media_item_id', mediaId)
          .eq('person_id', personId);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Ordnet dieselben Personen mehreren Medien zu (keine Dateikopie).
  Future<void> assignPeopleToManyMedia({
    required List<String> mediaIds,
    required List<String> personIds,
    String source = 'manual',
    Map<String, String?> profileIdsByPersonId = const {},
  }) async {
    for (final mediaId in mediaIds) {
      for (final personId in personIds) {
        await assignPersonToMedia(
          mediaId: mediaId,
          personId: personId,
          source: source,
          taggedProfileId: profileIdsByPersonId[personId],
        );
      }
    }
  }

  Future<List<PersonModel>> listPeopleForMedia(
    String mediaId, {
    String? status = 'confirmed',
  }) async {
    try {
      var query = _client
          .from('media_people')
          .select('person_id, status, source, people(*)')
          .eq('media_item_id', mediaId);
      if (status != null) {
        query = query.eq('status', status);
      }
      final rows = await query;
      final result = <PersonModel>[];
      for (final row in rows as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final person = map['people'];
        if (person is Map) {
          result.add(PersonModel.fromJson(Map<String, dynamic>.from(person)));
        }
      }
      return result;
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Batch: media_item_id → Person-IDs (für Kartenfilter).
  Future<Map<String, Set<String>>> listPersonIdsByMediaIds(
    List<String> mediaIds,
  ) async {
    if (mediaIds.isEmpty) return {};
    try {
      final result = <String, Set<String>>{};
      const chunk = 200;
      for (var i = 0; i < mediaIds.length; i += chunk) {
        final slice = mediaIds.sublist(
          i,
          i + chunk > mediaIds.length ? mediaIds.length : i + chunk,
        );
        final rows = await _client
            .from('media_people')
            .select('media_item_id, person_id')
            .eq('status', 'confirmed')
            .inFilter('media_item_id', slice);
        for (final row in rows as List) {
          final map = Map<String, dynamic>.from(row as Map);
          final mid = map['media_item_id'] as String?;
          final pid = map['person_id'] as String?;
          if (mid == null || pid == null) continue;
          result.putIfAbsent(mid, () => {}).add(pid);
        }
      }
      return result;
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }
}
