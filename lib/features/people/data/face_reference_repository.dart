import 'package:memory_ai/core/errors/app_exception.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/supabase_service.dart';

/// Speichert nur Merkmalsvektoren – keine Rohbild-Duplikate.
class FaceReferenceRepository {
  FaceReferenceRepository();

  static final _client = SupabaseService.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AppException(message: 'Du bist nicht angemeldet.');
    }
    return id;
  }

  Future<int> countForCurrentUser() async {
    try {
      final rows = await _client
          .from('face_reference_embeddings')
          .select('id')
          .eq('user_id', _userId);
      return (rows as List).length;
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<List<double>>> listEmbeddingsForCurrentUser() async {
    try {
      final rows = await _client
          .from('face_reference_embeddings')
          .select('embedding')
          .eq('user_id', _userId)
          .order('created_at');
      return (rows as List)
          .map((row) => _parseEmbedding((row as Map)['embedding']))
          .whereType<List<double>>()
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> replaceAll(List<List<double>> embeddings) async {
    if (embeddings.length > 5) {
      throw const AppException(
        message: 'Maximal 5 Referenzfotos sind erlaubt.',
      );
    }
    try {
      final userId = _userId;
      await _client
          .from('face_reference_embeddings')
          .delete()
          .eq('user_id', userId);
      if (embeddings.isEmpty) return;
      await _client
          .from('face_reference_embeddings')
          .insert(
            embeddings.map((e) => {'user_id': userId, 'embedding': e}).toList(),
          );
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> deleteAllForUser(String userId) async {
    try {
      final current = _client.auth.currentUser?.id;
      if (current == null || current != userId) {
        throw const AppException(
          message:
              'Referenzdaten können nur für das eigene Konto gelöscht werden.',
        );
      }
      await _client
          .from('face_reference_embeddings')
          .delete()
          .eq('user_id', userId);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Familien-Referenzen nur über Security-Definer-RPC (Gegenkonsens).
  Future<Map<String, List<List<double>>>> listFamilyEmbeddings() async {
    try {
      final rows = await _client.rpc('get_family_face_reference_embeddings');
      final result = <String, List<List<double>>>{};
      for (final row in rows as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final memberId = map['member_user_id'] as String?;
        final embedding = _parseEmbedding(map['embedding']);
        if (memberId == null || embedding == null) continue;
        result.putIfAbsent(memberId, () => []).add(embedding);
      }
      return result;
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  static List<double>? _parseEmbedding(Object? raw) {
    if (raw is! List) return null;
    return raw.map((e) => (e as num).toDouble()).toList();
  }
}
