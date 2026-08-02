import 'package:memory_ai/core/errors/app_exception.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/features/chat/data/chat_message_model.dart';
import 'package:memory_ai/features/chat/data/chat_room_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Minimaler Familien-Textchat (Realtime über Supabase).
class ChatRepository {
  static final _client = SupabaseService.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AppException(message: 'Du bist nicht angemeldet.');
    }
    return id;
  }

  Future<List<ChatRoomModel>> listRooms(String familyId) async {
    try {
      final rows = await _client
          .from('chat_rooms')
          .select()
          .eq('family_id', familyId)
          .order('updated_at', ascending: false);
      return (rows as List)
          .map(
            (r) => ChatRoomModel.fromJson(Map<String, dynamic>.from(r as Map)),
          )
          .toList();
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  /// Stellt sicher, dass ein Familien-Gruppenraum existiert.
  Future<ChatRoomModel> ensureFamilyRoom({
    required String familyId,
    String name = 'Familienchat',
  }) async {
    try {
      final existing = await _client
          .from('chat_rooms')
          .select()
          .eq('family_id', familyId)
          .eq('is_group', true)
          .order('created_at')
          .limit(1)
          .maybeSingle();
      if (existing != null) {
        return ChatRoomModel.fromJson(Map<String, dynamic>.from(existing));
      }

      final uid = _userId;
      final room = await _client
          .from('chat_rooms')
          .insert({
            'family_id': familyId,
            'name': name,
            'is_group': true,
            'created_by': uid,
          })
          .select()
          .single();

      await _client.from('chat_room_members').upsert({
        'room_id': room['id'],
        'user_id': uid,
      }, onConflict: 'room_id,user_id');

      return ChatRoomModel.fromJson(Map<String, dynamic>.from(room));
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Future<void> joinRoom(String roomId) async {
    try {
      await _client.from('chat_room_members').upsert({
        'room_id': roomId,
        'user_id': _userId,
      }, onConflict: 'room_id,user_id');
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Future<List<ChatMessageModel>> listMessages(
    String roomId, {
    int limit = 100,
  }) async {
    try {
      final rows = await _client
          .from('chat_messages')
          .select()
          .eq('room_id', roomId)
          .order('created_at', ascending: true)
          .limit(limit);
      return (rows as List)
          .map(
            (r) =>
                ChatMessageModel.fromJson(Map<String, dynamic>.from(r as Map)),
          )
          .toList();
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Future<ChatMessageModel> sendMessage({
    required String roomId,
    required String content,
  }) async {
    final text = content.trim();
    if (text.isEmpty) {
      throw const AppException(message: 'Nachricht darf nicht leer sein.');
    }
    try {
      await joinRoom(roomId);
      final row = await _client
          .from('chat_messages')
          .insert({'room_id': roomId, 'sender_id': _userId, 'body': text})
          .select()
          .single();
      await _client
          .from('chat_rooms')
          .update({'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', roomId);
      return ChatMessageModel.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  /// Realtime-Stream neuer Nachrichten im Raum.
  RealtimeChannel subscribeMessages(
    String roomId, {
    required void Function(ChatMessageModel message) onInsert,
  }) {
    final channel = _client.channel('chat_messages_$roomId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            onInsert(ChatMessageModel.fromJson(Map<String, dynamic>.from(row)));
          },
        )
        .subscribe();
    return channel;
  }
}
