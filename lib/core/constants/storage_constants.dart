/// Supabase-Storage-Bucket-Namen und Upload-Limits.
class StorageConstants {
  StorageConstants._();

  static const String avatars = 'avatars';
  static const String familyImages = 'family-images';
  static const String familyVideos = 'family-videos';
  static const String familyTreeImages = 'family-tree-images';
  static const String chatMedia = 'chat-media';

  // Travel pivot buckets
  static const String mediaPhotos = 'media-photos';
  static const String mediaVideos = 'media-videos';
  static const String mediaThumbnails = 'media-thumbnails';
  static const String generatedVideos = 'generated-videos';
  static const String peopleAvatars = 'people-avatars';

  /// Pfad: `{ownerId}/{year}/{month}/{mediaItemId}.{ext}`
  static String mediaPhotoPath({
    required String ownerId,
    required String mediaItemId,
    required String extension,
    required DateTime takenAt,
  }) {
    final ext = extension.startsWith('.') ? extension.substring(1) : extension;
    final month = takenAt.month.toString().padLeft(2, '0');
    return '$ownerId/${takenAt.year}/$month/$mediaItemId.$ext';
  }

  /// Pfad: `{ownerId}/{year}/{month}/{mediaItemId}.{ext}` (Videos).
  static String mediaVideoPath({
    required String ownerId,
    required String mediaItemId,
    required String extension,
    required DateTime takenAt,
  }) {
    final ext = extension.startsWith('.') ? extension.substring(1) : extension;
    final month = takenAt.month.toString().padLeft(2, '0');
    return '$ownerId/${takenAt.year}/$month/$mediaItemId.$ext';
  }

  /// Pfad: `{ownerId}/{year}/{month}/{mediaItemId}_thumb.jpg`
  static String mediaThumbnailPath({
    required String ownerId,
    required String mediaItemId,
    required DateTime takenAt,
  }) {
    final month = takenAt.month.toString().padLeft(2, '0');
    return '$ownerId/${takenAt.year}/$month/${mediaItemId}_thumb.jpg';
  }

  static const int maxMediaVideoBytes = 200 * 1024 * 1024;

  static const List<String> allowedVideoMimeTypes = [
    'video/mp4',
    'video/quicktime',
    'video/x-m4v',
    'video/3gpp',
    'video/3gpp2',
  ];

  /// Pfad: `{ownerId}/{tripId}/{fileId}.{ext}`
  static String generatedVideoPath({
    required String ownerId,
    required String tripId,
    required String fileId,
    required String extension,
  }) {
    final ext = extension.startsWith('.') ? extension.substring(1) : extension;
    return '$ownerId/$tripId/$fileId.$ext';
  }

  /// Pfad: `{ownerId}/{personId}.{ext}`
  static String peopleAvatarPath({
    required String ownerId,
    required String personId,
    required String extension,
  }) {
    final ext = extension.startsWith('.') ? extension.substring(1) : extension;
    return '$ownerId/$personId.$ext';
  }

  /// Hartes Storage-Limit (Server + Client-Validierung).
  static const int maxFamilyImageBytes = 20 * 1024 * 1024;

  /// Zielgröße nach clientseitiger Kompression.
  static const int targetFamilyImageBytes = 2 * 1024 * 1024;

  static const List<String> allowedFamilyImageMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
    'image/heif',
  ];

  /// Pfad: `{familyId}/{userId}/{fileId}.{extension}`
  static String familyImagePath({
    required String familyId,
    required String userId,
    required String fileId,
    required String extension,
  }) {
    final ext = extension.startsWith('.') ? extension.substring(1) : extension;
    return '$familyId/$userId/$fileId.$ext';
  }
}
