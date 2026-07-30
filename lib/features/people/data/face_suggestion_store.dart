import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/supabase_service.dart';

/// Löscht nur Vorschläge (suggested) bei Consent-Widerruf – keine Bestätigungen.
class FaceSuggestionStore {
  FaceSuggestionStore();

  static final _client = SupabaseService.client;

  /// Selbst-Vorschläge des Owners (Person „Ich“ / eigener Name).
  Future<void> deleteSelfSuggestionsForOwner(String ownerId) async {
    try {
      final people = await _client
          .from('people')
          .select('id, name')
          .eq('owner_id', ownerId);
      final selfIds = <String>[];
      for (final row in people as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final name = (map['name'] as String? ?? '').toLowerCase();
        if (name == 'ich' || name == 'du' || name == 'möglicherweise du') {
          selfIds.add(map['id'] as String);
        }
      }
      // Zusätzlich: alle face_recognition suggested auf eigenen Medien.
      final mediaRows = await _client
          .from('media_items')
          .select('id')
          .eq('owner_id', ownerId);
      final mediaIds = (mediaRows as List)
          .map((r) => (r as Map)['id'] as String)
          .toList();
      if (mediaIds.isEmpty) return;

      await _client
          .from('media_people')
          .delete()
          .inFilter('media_item_id', mediaIds)
          .eq('source', 'face_recognition')
          .eq('status', 'suggested')
          .inFilter(
            'person_id',
            selfIds.isEmpty
                ? ['00000000-0000-0000-0000-000000000000']
                : selfIds,
          );
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Offene Familien-Vorschläge auf eigenen Medien.
  Future<void> deleteFamilySuggestionsForOwner(String ownerId) async {
    try {
      final mediaRows = await _client
          .from('media_items')
          .select('id')
          .eq('owner_id', ownerId);
      final mediaIds = (mediaRows as List)
          .map((r) => (r as Map)['id'] as String)
          .toList();
      if (mediaIds.isEmpty) return;

      // Alle suggested face_recognition außer klaren Selbst-Personen:
      // pragmatisch: alle offenen face_recognition-Vorschläge löschen
      // (Bestätigungen bleiben).
      await _client
          .from('media_people')
          .delete()
          .inFilter('media_item_id', mediaIds)
          .eq('source', 'face_recognition')
          .eq('status', 'suggested');
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }
}
