import 'package:memory_ai/core/errors/app_exception.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/features/profile/data/profile_model.dart';

/// Datenzugriff auf `public.profiles`.
class ProfileRepository {
  ProfileRepository();

  static final _client = SupabaseService.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AppException(message: 'Du bist nicht angemeldet.');
    }
    return id;
  }

  Future<ProfileModel?> getMyProfile() async {
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', _userId)
          .maybeSingle();
      if (row == null) return null;
      return ProfileModel.fromJson(Map<String, dynamic>.from(row));
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Stellt sicher, dass eine Profilzeile existiert (z. B. nach Registrierung).
  Future<ProfileModel> ensureExists() async {
    try {
      final existing = await getMyProfile();
      if (existing != null) return existing;

      final user = _client.auth.currentUser!;
      final meta = user.userMetadata ?? {};
      final firstName =
          (meta['first_name'] as String?)?.trim() ??
          (meta['display_name'] as String?)?.trim();
      final lastName = (meta['last_name'] as String?)?.trim();

      final row = await _client
          .from('profiles')
          .upsert({
            'id': user.id,
            'email': user.email,
            if (firstName != null && firstName.isNotEmpty)
              'first_name': firstName,
            if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
            'profile_completed': false,
          })
          .select()
          .single();

      return ProfileModel.fromJson(Map<String, dynamic>.from(row));
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Profil vervollständigen (Onboarding).
  Future<ProfileModel> completeProfile({
    required String firstName,
    required String lastName,
    required String username,
    String? avatarPath,
    DateTime? birthDate,
    String? gender,
  }) async {
    return upsertProfile(
      firstName: firstName,
      lastName: lastName,
      username: username,
      avatarPath: avatarPath,
      birthDate: birthDate,
      gender: gender,
      profileCompleted: true,
    );
  }

  Future<ProfileModel> upsertProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? avatarPath,
    DateTime? birthDate,
    String? gender,
    bool? profileCompleted,
  }) async {
    try {
      final user = _client.auth.currentUser!;
      final payload = <String, dynamic>{
        'id': user.id,
        'email': user.email,
        if (firstName != null) 'first_name': firstName.trim(),
        if (lastName != null) 'last_name': lastName.trim(),
        if (username != null) 'username': username.trim(),
        'avatar_path': ?avatarPath,
        if (birthDate != null)
          'birth_date': birthDate.toIso8601String().split('T').first,
        'gender': ?gender,
        'profile_completed': ?profileCompleted,
      };

      final row = await _client
          .from('profiles')
          .upsert(payload)
          .select()
          .single();

      return ProfileModel.fromJson(Map<String, dynamic>.from(row));
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<ProfileModel> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? avatarPath,
    DateTime? birthDate,
    String? gender,
    bool clearBirthDate = false,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (firstName != null) 'first_name': firstName.trim(),
        if (lastName != null) 'last_name': lastName.trim(),
        if (username != null) 'username': username.trim(),
        'avatar_path': ?avatarPath,
        'gender': ?gender,
        if (clearBirthDate)
          'birth_date': null
        else if (birthDate != null)
          'birth_date': birthDate.toIso8601String().split('T').first,
      };

      if (payload.isEmpty) {
        final current = await getMyProfile();
        if (current == null) {
          throw const AppException(message: 'Profil wurde nicht gefunden.');
        }
        return current;
      }

      final row = await _client
          .from('profiles')
          .update(payload)
          .eq('id', _userId)
          .select()
          .single();

      return ProfileModel.fromJson(Map<String, dynamic>.from(row));
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }
}
