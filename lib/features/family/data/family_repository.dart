import 'package:memory_ai/core/errors/app_exception.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/features/family/data/family_invitation_model.dart';
import 'package:memory_ai/features/family/data/family_member_model.dart';
import 'package:memory_ai/features/family/data/family_model.dart';
import 'package:memory_ai/features/profile/data/profile_model.dart';

/// Datenzugriff auf Familien und Mitglieder.
class FamilyRepository {
  FamilyRepository();

  static final _client = SupabaseService.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AppException(message: 'Du bist nicht angemeldet.');
    }
    return id;
  }

  Future<List<FamilyModel>> listMyFamilies() async {
    try {
      final memberships = await _client
          .from('family_members')
          .select('family_id')
          .eq('user_id', _userId);

      final familyIds = (memberships as List)
          .map((row) => (row as Map)['family_id'] as String)
          .toList();

      if (familyIds.isEmpty) return [];

      final rows = await _client
          .from('families')
          .select()
          .inFilter('id', familyIds)
          .order('created_at');

      return (rows as List)
          .map(
            (row) =>
                FamilyModel.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Ruft `create_family` auf und parst `invite_code` aus der Antwort.
  Future<FamilyModel> createFamily(String name) async {
    try {
      final raw = await _client.rpc(
        'create_family',
        params: {'p_name': name.trim()},
      );
      final map = _rpcRowToMap(raw);
      final inviteCode = map['invite_code'] as String?;
      if (inviteCode == null || inviteCode.isEmpty) {
        throw const AppException(
          message: 'Familie erstellt, aber kein Einladungscode erhalten.',
        );
      }
      return FamilyModel.fromJson(map);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<FamilyModel> joinFamily({
    required String inviteCode,
    FamilyRole role = FamilyRole.member,
  }) async {
    try {
      final raw = await _client.rpc(
        'join_family',
        params: {
          'p_invite_code': inviteCode.trim().toUpperCase(),
          'p_role': role.name,
        },
      );
      return FamilyModel.fromJson(_rpcRowToMap(raw));
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<FamilyMemberModel>> listMembers(String familyId) async {
    try {
      // Versuch mit Join; Fallback auf separate Profile-Abfrage.
      try {
        final joined = await _client
            .from('family_members')
            .select(
              '*, profiles(id, email, first_name, last_name, username, avatar_path, profile_completed, birth_date, gender, created_at, updated_at)',
            )
            .eq('family_id', familyId)
            .order('joined_at');

        return (joined as List)
            .map(
              (row) => FamilyMemberModel.fromJson(
                Map<String, dynamic>.from(row as Map),
              ),
            )
            .toList();
      } catch (_) {
        final rows = await _client
            .from('family_members')
            .select()
            .eq('family_id', familyId)
            .order('joined_at');

        final memberRows = (rows as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();

        if (memberRows.isEmpty) return [];

        final userIds = memberRows
            .map((row) => row['user_id'] as String)
            .toSet()
            .toList();

        final profileRows = await _client
            .from('profiles')
            .select()
            .inFilter('id', userIds);

        final profilesById = <String, ProfileModel>{
          for (final row in profileRows as List)
            (row as Map)['id'] as String: ProfileModel.fromJson(
              Map<String, dynamic>.from(row),
            ),
        };

        return memberRows
            .map(
              (row) => FamilyMemberModel.fromJson(
                row,
                profile: profilesById[row['user_id'] as String],
              ),
            )
            .toList();
      }
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<FamilyMemberModel?> getMyMembership(String familyId) async {
    try {
      final row = await _client
          .from('family_members')
          .select()
          .eq('family_id', familyId)
          .eq('user_id', _userId)
          .maybeSingle();
      if (row == null) return null;
      return FamilyMemberModel.fromJson(Map<String, dynamic>.from(row));
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> leaveFamily(String familyId) async {
    try {
      await _client
          .from('family_members')
          .delete()
          .eq('family_id', familyId)
          .eq('user_id', _userId);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> removeMember({
    required String familyId,
    required String userId,
  }) async {
    try {
      await _client
          .from('family_members')
          .delete()
          .eq('family_id', familyId)
          .eq('user_id', userId);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<FamilyModel?> getFamily(String familyId) async {
    try {
      final row = await _client
          .from('families')
          .select()
          .eq('id', familyId)
          .maybeSingle();
      if (row == null) return null;
      return FamilyModel.fromJson(Map<String, dynamic>.from(row));
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<FamilyInvitationModel>> listInvitations(String familyId) async {
    try {
      final rows = await _client
          .from('family_invitations')
          .select()
          .eq('family_id', familyId)
          .order('created_at', ascending: false);

      return (rows as List)
          .map(
            (row) => FamilyInvitationModel.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// RPC-Antwort kann Map oder einzeilige Liste sein.
  Map<String, dynamic> _rpcRowToMap(dynamic raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return Map<String, dynamic>.from(raw.first as Map);
    }
    throw const AppException(message: 'Unerwartete Antwort vom Server.');
  }
}
