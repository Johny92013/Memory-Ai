import 'package:memory_ai/features/chat/data/chat_message_model.dart';
import 'package:memory_ai/features/chat/data/chat_room_model.dart';

/// Stub-Repository für Chat (Phase 6).
class ChatRepository {
  Future<List<ChatRoomModel>> listRooms(String familyId) async => [];

  Future<List<ChatMessageModel>> listMessages(String roomId) async => [];

  Future<void> sendMessage({
    required String roomId,
    required String content,
  }) async {}
}
