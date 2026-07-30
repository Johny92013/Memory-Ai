/// Mitglied einer Reise (`public.trip_members`).
class TripMemberModel {
  const TripMemberModel({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.role,
    this.invitationStatus = 'accepted',
    this.invitedBy,
    this.joinedAt,
    this.displayName,
    this.email,
  });

  final String id;
  final String tripId;
  final String userId;
  final String role;
  final String invitationStatus;
  final String? invitedBy;
  final DateTime? joinedAt;
  final String? displayName;
  final String? email;

  factory TripMemberModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return TripMemberModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'viewer',
      invitationStatus: json['invitation_status'] as String? ?? 'pending',
      invitedBy: json['invited_by'] as String?,
      joinedAt: DateTime.tryParse(json['joined_at']?.toString() ?? ''),
      displayName: profile?['display_name'] as String?,
      email: profile?['email'] as String?,
    );
  }
}
