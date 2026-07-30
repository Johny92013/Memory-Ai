/// Chat-Nachricht (Phase 6).
class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    this.createdAt,
  });

  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final DateTime? createdAt;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'room_id': roomId,
    'sender_id': senderId,
    'content': content,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };
}
