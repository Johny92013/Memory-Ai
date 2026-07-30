/// Chat-Raum-Modell (Phase 6).
class ChatRoomModel {
  const ChatRoomModel({
    required this.id,
    required this.familyId,
    required this.name,
    this.lastMessage,
    this.updatedAt,
  });

  final String id;
  final String familyId;
  final String name;
  final String? lastMessage;
  final DateTime? updatedAt;

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      name: json['name'] as String? ?? '',
      lastMessage: json['last_message'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'family_id': familyId,
    'name': name,
    if (lastMessage != null) 'last_message': lastMessage,
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };
}
