import 'package:memory_ai/features/family/data/family_member_model.dart';

/// Einladung in eine Familie (`public.family_invitations`).
class FamilyInvitationModel {
  const FamilyInvitationModel({
    required this.id,
    required this.familyId,
    required this.invitedBy,
    required this.inviteCode,
    required this.role,
    required this.status,
    required this.createdAt,
    this.email,
    this.expiresAt,
    this.updatedAt,
  });

  final String id;
  final String familyId;
  final String invitedBy;
  final String inviteCode;
  final FamilyRole role;
  final String status;
  final DateTime createdAt;
  final String? email;
  final DateTime? expiresAt;
  final DateTime? updatedAt;

  bool get isPending => status == 'pending';

  factory FamilyInvitationModel.fromJson(Map<String, dynamic> json) {
    return FamilyInvitationModel(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      invitedBy: json['invited_by'] as String,
      inviteCode: json['invite_code'] as String,
      role: FamilyRole.fromString(json['role'] as String?),
      status: (json['status'] as String?) ?? 'pending',
      email: json['email'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}
