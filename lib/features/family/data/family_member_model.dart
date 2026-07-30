import 'package:memory_ai/features/profile/data/profile_model.dart';

/// Rollen in einer Familie.
enum FamilyRole {
  owner,
  admin,
  parent,
  child,
  grandparent,
  member;

  /// Unbekannte Werte werden auf [member] gemappt.
  static FamilyRole fromString(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    return FamilyRole.values.firstWhere(
      (role) => role.name == normalized,
      orElse: () => FamilyRole.member,
    );
  }

  String get labelDe {
    switch (this) {
      case FamilyRole.owner:
        return 'Inhaber';
      case FamilyRole.admin:
        return 'Admin';
      case FamilyRole.parent:
        return 'Eltern';
      case FamilyRole.child:
        return 'Kind';
      case FamilyRole.grandparent:
        return 'Großeltern';
      case FamilyRole.member:
        return 'Mitglied';
    }
  }

  /// DB kann `admin` für den Ersteller nutzen – UI behandelt beides gleich.
  bool get isAdminOrOwner =>
      this == FamilyRole.owner || this == FamilyRole.admin;

  /// Rollen, die beim Beitritt wählbar sind (keine Privilegienrollen).
  static List<FamilyRole> get joinChoices => [
    FamilyRole.parent,
    FamilyRole.child,
    FamilyRole.grandparent,
    FamilyRole.member,
  ];
}

/// Mitgliedschaft in einer Familie inkl. optionalem Profil.
class FamilyMemberModel {
  const FamilyMemberModel({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.profile,
  });

  final String id;
  final String familyId;
  final String userId;
  final FamilyRole role;
  final DateTime joinedAt;
  final ProfileModel? profile;

  String get displayName =>
      profile?.displayName ?? profile?.email ?? 'Mitglied';

  String? get email => profile?.email;
  String? get avatarPath => profile?.avatarPath;
  String? get firstName => profile?.firstName;
  String? get lastName => profile?.lastName;

  bool get isAdminOrOwner => role.isAdminOrOwner;

  factory FamilyMemberModel.fromJson(
    Map<String, dynamic> json, {
    ProfileModel? profile,
    Map<String, dynamic>? profileJson,
  }) {
    ProfileModel? resolved = profile;
    if (resolved == null && profileJson != null) {
      resolved = ProfileModel.fromJson(profileJson);
    }

    // Nested join: profiles { ... }
    final nested = json['profiles'];
    if (resolved == null && nested is Map) {
      resolved = ProfileModel.fromJson(Map<String, dynamic>.from(nested));
    }

    return FamilyMemberModel(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      userId: json['user_id'] as String,
      role: FamilyRole.fromString(json['role'] as String?),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      profile: resolved,
    );
  }
}
