import 'package:memory_ai/core/constants/storage_constants.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Erstellt und cached signierte URLs für private Storage-Dateien.
class SignedUrlService {
  SignedUrlService({SupabaseClient? client})
    : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  static final SignedUrlService _instance = SignedUrlService();

  static const Duration _defaultExpiry = Duration(hours: 1);

  final Map<String, _CachedSignedUrl> _cache = {};

  /// Liefert eine signierte URL für den angegebenen Storage-Pfad.
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    Duration expiresIn = _defaultExpiry,
  }) async {
    final cacheKey = '$bucket/$path';
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.url;
    }

    final signedUrl = await _client.storage
        .from(bucket)
        .createSignedUrl(path, expiresIn.inSeconds);

    _cache[cacheKey] = _CachedSignedUrl(
      url: signedUrl,
      expiresAt: DateTime.now().add(expiresIn),
    );

    return signedUrl;
  }

  /// Signierte URL für einen Avatar-Pfad.
  static Future<String?> avatarUrl(String? path) async {
    if (path == null || path.trim().isEmpty) {
      return null;
    }
    return _instance.createSignedUrl(
      bucket: StorageConstants.avatars,
      path: path,
    );
  }

  /// Signierte URL für ein Familienfoto.
  static Future<String?> familyImageUrl(String? path) async {
    if (path == null || path.trim().isEmpty) {
      return null;
    }
    return _instance.createSignedUrl(
      bucket: StorageConstants.familyImages,
      path: path,
    );
  }

  /// Signierte URL für ein Medienfoto (Original).
  static Future<String?> mediaPhotoUrl(String? path) async {
    if (path == null || path.trim().isEmpty) return null;
    return _instance.createSignedUrl(
      bucket: StorageConstants.mediaPhotos,
      path: path,
    );
  }

  /// Signierte URL für ein Medien-Thumbnail.
  static Future<String?> mediaThumbnailUrl(String? path) async {
    if (path == null || path.trim().isEmpty) return null;
    return _instance.createSignedUrl(
      bucket: StorageConstants.mediaThumbnails,
      path: path,
    );
  }

  /// Thumbnail bevorzugen, sonst Original.
  static Future<String?> mediaGridUrl(MediaItemModel item) async {
    if (item.hasThumbnail) {
      return mediaThumbnailUrl(item.thumbnailPath);
    }
    return mediaPhotoUrl(item.storagePath);
  }

  /// Entfernt einen Eintrag aus dem Cache.
  void invalidate({required String bucket, required String path}) {
    _cache.remove('$bucket/$path');
  }

  /// Leert den gesamten URL-Cache.
  void clearCache() {
    _cache.clear();
  }
}

class _CachedSignedUrl {
  _CachedSignedUrl({required this.url, required this.expiresAt});

  final String url;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
