import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/supabase_service.dart';

/// Admin-Datenzugriff (read-only, RLS via app_metadata.app_role).
class AdminRepository {
  AdminRepository();

  static final _client = SupabaseService.client;

  Future<int> countProfiles() async {
    try {
      final rows = await _client.from('profiles').select('id');
      return (rows as List).length;
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<int> countFamilies() async {
    try {
      final rows = await _client.from('families').select('id');
      return (rows as List).length;
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<int> countMemories() async {
    try {
      final rows = await _client.from('media_items').select('id');
      return (rows as List).length;
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<Map<String, dynamic>>> listProfiles() async {
    try {
      final rows = await _client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<Map<String, dynamic>>> listFamilies() async {
    try {
      final rows = await _client
          .from('families')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<Map<String, dynamic>>> listFamilyMembers(String familyId) async {
    try {
      final rows = await _client
          .from('family_members')
          .select()
          .eq('family_id', familyId);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<int> countMembersForFamily(String familyId) async {
    final members = await listFamilyMembers(familyId);
    return members.length;
  }
}
