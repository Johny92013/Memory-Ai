import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/features/family_tree/data/family_relationship_model.dart';
import 'package:memory_ai/features/family_tree/data/family_tree_person_model.dart';

/// Datenzugriff auf Stammbaum-Personen und Beziehungen.
class FamilyTreeRepository {
  FamilyTreeRepository();

  final _client = SupabaseService.client;

  Future<List<FamilyTreePersonModel>> listPeople(String familyId) async {
    try {
      final rows = await _client
          .from('family_tree_people')
          .select()
          .eq('family_id', familyId);
      return (rows as List)
          .map(
            (row) => FamilyTreePersonModel.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<FamilyRelationshipModel>> listRelationships(
    String familyId,
  ) async {
    try {
      final rows = await _client
          .from('family_relationships')
          .select()
          .eq('family_id', familyId);
      return (rows as List)
          .map(
            (row) => FamilyRelationshipModel.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<FamilyTreePersonModel> addPerson(Map<String, dynamic> values) async {
    try {
      final row = await _client
          .from('family_tree_people')
          .insert(values)
          .select()
          .single();
      return FamilyTreePersonModel.fromJson(Map<String, dynamic>.from(row));
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<FamilyTreePersonModel> updatePerson(
    String id,
    Map<String, dynamic> values,
  ) async {
    try {
      final row = await _client
          .from('family_tree_people')
          .update(values)
          .eq('id', id)
          .select()
          .single();
      return FamilyTreePersonModel.fromJson(Map<String, dynamic>.from(row));
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> deletePerson(String id) async {
    try {
      await _client.from('family_tree_people').delete().eq('id', id);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> linkProfile({
    required String personId,
    required String linkedProfileId,
  }) async {
    try {
      await _client
          .from('family_tree_people')
          .update({'linked_profile_id': linkedProfileId})
          .eq('id', personId);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Spiegelt den Beziehungstyp (entspricht `mirror_relationship_type` in SQL).
  static String? mirrorRelationship(String type) {
    switch (type) {
      case 'parent':
        return 'child';
      case 'child':
        return 'parent';
      case 'spouse':
      case 'sibling':
      case 'partner':
      case 'other':
        return type;
      default:
        return null;
    }
  }

  /// Legt eine Beziehung an – DB-Trigger spiegelt parent/child automatisch.
  Future<void> assignRelationship({
    required String familyId,
    required String personAId,
    required String personBId,
    required String type,
  }) async {
    if (mirrorRelationship(type) == null) {
      throw ArgumentError.value(type, 'type', 'Unbekannte Beziehung');
    }
    try {
      await _client.from('family_relationships').insert({
        'family_id': familyId,
        'person_a_id': personAId,
        'person_b_id': personBId,
        'relationship_type': type,
      });
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Berechnet Generationen anhand von Eltern-Kanten (person_a ist Elternteil).
  static Map<String, int> generationLayout(
    List<FamilyTreePersonModel> people,
    List<FamilyRelationshipModel> relationships,
  ) {
    final result = {for (final person in people) person.id: 0};
    var changed = true;
    var passes = 0;

    while (changed && passes++ < people.length) {
      changed = false;
      for (final edge in relationships.where((r) => r.type == 'parent')) {
        final parentGen = result[edge.personAId] ?? 0;
        final childGen = result[edge.personBId] ?? 0;
        if (childGen <= parentGen) {
          result[edge.personBId] = parentGen + 1;
          changed = true;
        }
      }
    }

    return result;
  }
}
