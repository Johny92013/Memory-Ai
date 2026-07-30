import 'package:image_picker/image_picker.dart';
import 'package:memory_ai/core/constants/storage_constants.dart';
import 'package:memory_ai/core/errors/app_exception.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/image_service.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/features/memories/data/album_model.dart';
import 'package:memory_ai/features/memories/data/image_compression_service.dart';
import 'package:memory_ai/features/memories/data/image_exif_reader.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/memories/data/memory_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Fortschritt eines Foto-Uploads (0.0 – 1.0) inkl. Status-Text.
typedef UploadProgressCallback = void Function(double progress, String label);

/// Datenzugriff auf Erinnerungen und Familienfotos.
class MemoriesRepository {
  MemoriesRepository();

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
          .from('memories')
          .select()
          .eq('family_id', familyId)
          .order('taken_at', ascending: false)
          .order('created_at', ascending: false);

      return (rows as List)
          .map(
            (row) =>
                MemoryModel.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Lädt ein Familienfoto hoch: EXIF → Kompression → Storage → memories.
  Future<MemoryModel> uploadFamilyPhoto({
    required String familyId,
    required XFile file,
    String? title,
    String? description,
    UploadProgressCallback? onProgress,
  }) async {
    void report(double value, String label) => onProgress?.call(value, label);

    try {
      final userId = _userId;
      report(0.05, 'Foto wird gelesen …');
      final originalBytes = await file.readAsBytes();
      final sourceMime = ImageService.detectMimeType(file, originalBytes);
      ImageService.validateImageBytes(originalBytes, sourceMime);

      report(0.15, 'Metadaten werden gelesen …');
      final exif = await ImageExifReader.read(originalBytes);
      final takenAt = exif.takenAt ?? DateTime.now();

      report(0.3, 'Foto wird optimiert …');
      final compressed = ImageCompressionService.compressForUpload(
        bytes: originalBytes,
        sourceMimeType: sourceMime,
      );
      ImageService.validateImageBytes(compressed.bytes, compressed.mimeType);

      final fileId = const Uuid().v4();
      final storagePath = StorageConstants.familyImagePath(
        familyId: familyId,
        userId: userId,
        fileId: fileId,
        extension: compressed.extension,
      );

      report(0.55, 'Foto wird hochgeladen …');
      await _client.storage
          .from(StorageConstants.familyImages)
          .uploadBinary(
            storagePath,
            compressed.bytes,
            fileOptions: FileOptions(
              contentType: compressed.mimeType,
              upsert: false,
            ),
          );

      report(0.85, 'Erinnerung wird gespeichert …');
      final row = await _client
          .from('memories')
          .insert({
            'family_id': familyId,
            'created_by': userId,
            'media_type': 'image',
            'storage_path': storagePath,
            'taken_at': takenAt.toUtc().toIso8601String(),
            if (exif.latitude != null) 'latitude': exif.latitude,
            if (exif.longitude != null) 'longitude': exif.longitude,
            if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
            if (description != null && description.trim().isNotEmpty)
              'description': description.trim(),
          })
          .select()
          .single();

      report(1.0, 'Fertig');
      return MemoryModel.fromJson(Map<String, dynamic>.from(row));
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> deleteMemory(String memoryId) async {
    try {
      final row = await _client
          .from('memories')
          .select('created_by, storage_path')
          .eq('id', memoryId)
          .maybeSingle();

      if (row == null) {
        throw const AppException(message: 'Erinnerung nicht gefunden.');
      }

      final map = Map<String, dynamic>.from(row);
      if (map['created_by'] as String != _userId) {
        throw const AppException(
          message: 'Du kannst nur eigene Erinnerungen löschen.',
        );
      }

      final storagePath = map['storage_path'] as String?;
      if (storagePath != null && storagePath.isNotEmpty) {
        await _client.storage.from(StorageConstants.familyImages).remove([
          storagePath,
        ]);
      }

      await _client.from('memories').delete().eq('id', memoryId);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<AlbumModel>> listAlbums(String familyId) async => [];

  Future<List<MediaItemModel>> listMedia(String familyId) async => [];

  Future<MemoryModel?> getMemory(String id) async {
    try {
      final row = await _client
          .from('memories')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (row == null) return null;
      return MemoryModel.fromJson(Map<String, dynamic>.from(row));
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<AlbumModel?> getAlbum(String id) async => null;

  Future<MediaItemModel?> getMediaItem(String id) async => null;
}
