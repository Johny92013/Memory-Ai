import 'package:memory_ai/core/errors/app_exception.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/features/memories/data/album_model.dart';
import 'package:memory_ai/features/memories/data/album_repository.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/memories/data/media_repository.dart';
import 'package:memory_ai/features/memories/data/memory_model.dart';

/// Legacy-Fassade: liest/schreibt nur noch über `media_items`.
/// Die Tabelle `memories` wurde zu `memories_deprecated` umbenannt.
class MemoriesRepository {
  MemoriesRepository({MediaRepository? mediaRepository})
    : _mediaRepo = mediaRepository ?? MediaRepository();

  final MediaRepository _mediaRepo;
  static final _client = SupabaseService.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AppException(message: 'Du bist nicht angemeldet.');
    }
    return id;
  }

  Future<List<MemoryModel>> listMemories(String familyId) async {
    try {
      final rows = await _client
          .from('media_items')
          .select()
          .eq('family_id', familyId)
          .order('taken_at', ascending: false)
          .order('created_at', ascending: false);

      return (rows as List)
          .map((row) => _fromMediaJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Veraltet: Upload läuft über [MediaRepository] / UploadPhotosScreen.
  @Deprecated('Nutze MediaRepository.uploadPhoto / /memories/upload')
  Future<MemoryModel> uploadFamilyPhoto({
    required String familyId,
    required dynamic file,
    String? title,
    String? description,
    void Function(double progress, String label)? onProgress,
  }) async {
    throw const AppException(
      message:
          'Der Legacy-Upload ist deaktiviert. Bitte nutze „Erinnerung hinzufügen“ '
          '(media_items).',
    );
  }

  Future<void> deleteMemory(String memoryId) async {
    try {
      final row = await _client
          .from('media_items')
          .select('owner_id, storage_path, thumbnail_path')
          .eq('id', memoryId)
          .maybeSingle();

      if (row == null) {
        throw const AppException(message: 'Erinnerung nicht gefunden.');
      }

      final map = Map<String, dynamic>.from(row);
      if (map['owner_id'] as String != _userId) {
        throw const AppException(
          message: 'Du kannst nur eigene Erinnerungen löschen.',
        );
      }

      await _client.from('media_items').delete().eq('id', memoryId);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<AlbumModel>> listAlbums(String familyId) {
    return AlbumRepository().listAlbums(familyId: familyId);
  }

  Future<List<MediaItemModel>> listMedia(String familyId) {
    return _mediaRepo.listAccessibleMedia(familyId: familyId);
  }

  Future<MemoryModel?> getMemory(String id) async {
    try {
      final row = await _client
          .from('media_items')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (row == null) return null;
      return _fromMediaJson(Map<String, dynamic>.from(row));
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<AlbumModel?> getAlbum(String id) {
    return AlbumRepository().getAlbum(id);
  }

  Future<MediaItemModel?> getMediaItem(String id) {
    return _mediaRepo.getAccessibleMediaItem(id);
  }

  MemoryModel _fromMediaJson(Map<String, dynamic> json) {
    return MemoryModel(
      id: json['id'] as String,
      familyId: json['family_id'] as String? ?? '',
      createdBy: json['owner_id'] as String? ?? '',
      title: json['title'] as String?,
      description: json['description'] as String?,
      mediaType: json['media_type'] as String? ?? 'image',
      storagePath: json['storage_path'] as String?,
      takenAt: json['taken_at'] != null
          ? DateTime.tryParse(json['taken_at'].toString())
          : null,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationName: json['location_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}
