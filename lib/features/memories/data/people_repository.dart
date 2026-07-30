import 'package:memory_ai/core/errors/app_exception.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/features/memories/data/person_model.dart';

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

  Future<void> assignPersonToMedia({
    required String mediaId,
    required String personId,
    String source = 'manual',
    String status = 'confirmed',
  }) async {
    try {
      await _client.from('media_people').upsert({
        'media_item_id': mediaId,
        'person_id': personId,
        'source': source,
        'status': status,
      }, onConflict: 'media_item_id,person_id');
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
  }) async {
    for (final mediaId in mediaIds) {
      for (final personId in personIds) {
        await assignPersonToMedia(
          mediaId: mediaId,
          personId: personId,
          source: source,
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
