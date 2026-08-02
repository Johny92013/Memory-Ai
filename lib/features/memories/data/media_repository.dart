import 'dart:async';

import 'package:image_picker/image_picker.dart';
import 'package:memory_ai/core/constants/storage_constants.dart';
import 'package:memory_ai/core/errors/app_exception.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/image_service.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/features/map/data/coordinate_key.dart';
import 'package:memory_ai/features/map/data/location_place_model.dart';
import 'package:memory_ai/features/map/data/media_location_enrichment_service.dart';
import 'package:memory_ai/features/memories/data/exif_metadata_service.dart';
import 'package:memory_ai/features/memories/data/image_compression_service.dart';
import 'package:memory_ai/features/memories/data/media_face_detection_service.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/memories/data/memory_upload_validator.dart';
import 'package:memory_ai/features/memories/data/metadata_status_helper.dart';
import 'package:memory_ai/features/memories/data/thumbnail_service.dart';
import 'package:memory_ai/features/memories/data/upload_queue_model.dart';
import 'package:memory_ai/features/upload/services/video_metadata_extractor.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

typedef MediaUploadProgress = void Function(double progress, String label);

/// Upload und Liste für `public.media_items`.
class MediaRepository {
  MediaRepository();

  static final _client = SupabaseService.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AppException(message: 'Du bist nicht angemeldet.');
    }
    return id;
  }

  /// Galerie: eigene Medien und/oder akzeptierte Markierungen (keine Dateikopie).
  Future<List<MediaItemModel>> listGalleryMedia({
    required String filter,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      if (filter == 'own') {
        return listMyMedia(limit: limit, offset: offset);
      }

      if (filter == 'withMe' || filter == 'shared') {
        final status = filter == 'withMe'
            ? 'accepted_to_gallery'
            : 'linked_only';
        final tagRows = await _client
            .from('media_people')
            .select('media_item_id')
            .eq('tagged_profile_id', _userId)
            .eq('status', status);
        final ids = (tagRows as List)
            .map((r) => (r as Map)['media_item_id'] as String?)
            .whereType<String>()
            .toList();
        if (ids.isEmpty) return [];
        final rows = await _client
            .from('media_items')
            .select()
            .inFilter('id', ids)
            .order('taken_at', ascending: false)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);
        return (rows as List)
            .map(
              (row) => MediaItemModel.fromJson(
                Map<String, dynamic>.from(row as Map),
              ),
            )
            .toList();
      }

      // all: eigene + accepted_to_gallery
      final own = await listMyMedia(limit: limit, offset: offset);
      if (offset > 0) return own;
      final linked = await listGalleryMedia(
        filter: 'withMe',
        limit: limit,
        offset: 0,
      );
      final byId = <String, MediaItemModel>{
        for (final m in own) m.id: m,
        for (final m in linked) m.id: m,
      };
      final merged = byId.values.toList()
        ..sort((a, b) {
          final at =
              a.takenAt ??
              a.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bt =
              b.takenAt ??
              b.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bt.compareTo(at);
        });
      return merged.take(limit).toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<MediaItemModel>> listMyMedia({
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final rows = await _client
          .from('media_items')
          .select()
          .eq('owner_id', _userId)
          .eq('media_type', 'image')
          .order('taken_at', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (rows as List)
          .map(
            (row) =>
                MediaItemModel.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<MediaItemModel?> getMediaItem(String mediaId) async {
    try {
      final row = await _client
          .from('media_items')
          .select()
          .eq('id', mediaId)
          .eq('owner_id', _userId)
          .maybeSingle();
      if (row == null) return null;
      return MediaItemModel.fromJson(Map<String, dynamic>.from(row));
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Lädt ein Medium, sofern RLS Zugriff erlaubt (eigene / Trip / Familie).
  Future<MediaItemModel?> getAccessibleMediaItem(String mediaId) async {
    try {
      final row = await _client
          .from('media_items')
          .select()
          .eq('id', mediaId)
          .maybeSingle();
      if (row == null) return null;
      return MediaItemModel.fromJson(Map<String, dynamic>.from(row));
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// scope: own | family | all (RLS filtert ohnehin).
  Future<List<MediaItemModel>> listAccessibleMedia({
    String scope = 'own',
    String? familyId,
    int limit = 200,
  }) async {
    try {
      var query = _client.from('media_items').select();
      if (scope == 'own') {
        query = query.eq('owner_id', _userId);
      } else if (scope == 'family' && familyId != null) {
        query = query.eq('family_id', familyId);
      }
      final rows = await query
          .order('taken_at', ascending: false)
          .order('created_at', ascending: false)
          .limit(limit);
      return (rows as List)
          .map(
            (row) =>
                MediaItemModel.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Aktualisiert Aufnahmedatum / Standort / Status nach dem Upload.
  Future<MediaItemModel> updateCaptureMetadata({
    required String mediaId,
    DateTime? takenAt,
    String? dateSource,
    double? latitude,
    double? longitude,
    double? altitude,
    String? locationSource,
    String? locationName,
    String? countryName,
    String? city,
    String? countryCode,
    String? regionName,
    String? continent,
    String? metadataStatus,
    bool clearLocation = false,
  }) async {
    try {
      final patch = <String, dynamic>{};
      if (takenAt != null) {
        patch['taken_at'] = takenAt.toUtc().toIso8601String();
        patch['date_source'] = dateSource ?? 'manual';
      }
      if (clearLocation) {
        patch['latitude'] = null;
        patch['longitude'] = null;
        patch['altitude'] = null;
        patch['location_source'] = 'unknown';
        patch['location_name'] = null;
        patch['country_name'] = null;
        patch['country_code'] = null;
        patch['region_name'] = null;
        patch['city'] = null;
        patch['continent'] = null;
      } else {
        if (latitude != null) patch['latitude'] = latitude;
        if (longitude != null) patch['longitude'] = longitude;
        if (altitude != null) patch['altitude'] = altitude;
        if (locationSource != null) patch['location_source'] = locationSource;
        if (locationName != null) patch['location_name'] = locationName;
        if (countryName != null) patch['country_name'] = countryName;
        if (city != null) patch['city'] = city;
        if (countryCode != null) patch['country_code'] = countryCode;
        if (regionName != null) patch['region_name'] = regionName;
        if (continent != null) patch['continent'] = continent;
      }
      if (metadataStatus != null) patch['metadata_status'] = metadataStatus;

      final row = await _client
          .from('media_items')
          .update(patch)
          .eq('id', mediaId)
          .eq('owner_id', _userId)
          .select()
          .single();
      return MediaItemModel.fromJson(Map<String, dynamic>.from(row));
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<MediaItemModel>> listMyMediaWithGps({int limit = 500}) async {
    try {
      final rows = await _client
          .from('media_items')
          .select()
          .eq('owner_id', _userId)
          .not('latitude', 'is', null)
          .not('longitude', 'is', null)
          .order('taken_at', ascending: false)
          .order('created_at', ascending: false)
          .limit(limit);

      return (rows as List)
          .map(
            (row) =>
                MediaItemModel.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<MediaItemModel>> listMyMediaWithoutGps({int limit = 100}) async {
    try {
      final rows = await _client
          .from('media_items')
          .select()
          .eq('owner_id', _userId)
          .eq('media_type', 'image')
          .isFilter('latitude', null)
          .order('taken_at', ascending: false)
          .order('created_at', ascending: false)
          .limit(limit);

      return (rows as List)
          .map(
            (row) =>
                MediaItemModel.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<MediaItemModel>> listPendingLocationEnrichment({
    int limit = 30,
  }) async {
    try {
      final rows = await _client
          .from('media_items')
          .select()
          .eq('owner_id', _userId)
          .not('latitude', 'is', null)
          .not('longitude', 'is', null)
          .or('country_name.is.null,city.is.null')
          .limit(limit);

      return (rows as List)
          .map(
            (row) =>
                MediaItemModel.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .where((item) {
            final countryEmpty =
                item.countryName == null || item.countryName!.trim().isEmpty;
            final cityEmpty = item.city == null || item.city!.trim().isEmpty;
            return countryEmpty || cityEmpty;
          })
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<MediaItemModel>> listMyMediaFiltered({
    int limit = 200,
    int? year,
    String? mediaType,
    String? countryName,
    String? cityName,
    String? coordinateKey,
  }) async {
    try {
      var query = _client.from('media_items').select().eq('owner_id', _userId);

      if (mediaType != null) {
        query = query.eq('media_type', mediaType);
      }
      if (countryName != null) {
        query = query.eq('country_name', countryName);
      }
      if (cityName != null) {
        query = query.eq('city', cityName);
      }

      final rows = await query
          .order('taken_at', ascending: false)
          .order('created_at', ascending: false)
          .limit(limit);

      var items = (rows as List)
          .map(
            (row) =>
                MediaItemModel.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();

      if (year != null) {
        items = items.where((item) {
          final date = item.takenAt ?? item.createdAt;
          return date?.year == year;
        }).toList();
      }

      if (coordinateKey != null) {
        items = items
            .where(
              (item) =>
                  item.hasGps &&
                  CoordinateKey.fromLatLon(item.latitude!, item.longitude!) ==
                      coordinateKey,
            )
            .toList();
      }

      return items;
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> updateLocationFromPlace({
    required String mediaId,
    required LocationPlace place,
  }) async {
    try {
      await _client
          .from('media_items')
          .update({
            if (place.country != null) 'country_name': place.country,
            if (place.countryCode != null) 'country_code': place.countryCode,
            if (place.region != null) 'region_name': place.region,
            if (place.city != null) 'city': place.city,
            if (place.locationName != null) 'location_name': place.locationName,
            if (place.continent != null) 'continent': place.continent,
          })
          .eq('id', mediaId)
          .eq('owner_id', _userId);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> updateLocationManual({
    required String mediaId,
    required double latitude,
    required double longitude,
    LocationPlace? place,
    String? locationName,
  }) async {
    try {
      await _client
          .from('media_items')
          .update({
            'latitude': latitude,
            'longitude': longitude,
            'location_source': 'manual',
            if (place?.country != null) 'country_name': place!.country,
            if (place?.countryCode != null) 'country_code': place!.countryCode,
            if (place?.region != null) 'region_name': place!.region,
            if (place?.city != null) 'city': place!.city,
            if (place?.continent != null) 'continent': place!.continent,
            'location_name': locationName ?? place?.locationName,
          })
          .eq('id', mediaId)
          .eq('owner_id', _userId);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> clearLocation(String mediaId) async {
    try {
      await _client
          .from('media_items')
          .update({
            'latitude': null,
            'longitude': null,
            'altitude': null,
            'location_source': 'unknown',
            'location_name': null,
            'country_name': null,
            'country_code': null,
            'region_name': null,
            'city': null,
            'continent': null,
          })
          .eq('id', mediaId)
          .eq('owner_id', _userId);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Lädt ein Foto in Storage + DB mit Rollback bei Fehlern.
  Future<MediaItemModel> uploadPhoto({
    required UploadQueueItem item,
    String? tripId,
    String? familyId,
    MediaUploadProgress? onProgress,
  }) async {
    void report(double v, String label) => onProgress?.call(v, label);

    final userId = _userId;
    final mediaId = const Uuid().v4();
    String? uploadedPhotoPath;
    String? uploadedThumbPath;

    try {
      report(0.05, 'Foto wird gelesen …');
      final originalBytes = await item.file.readAsBytes();
      final sourceMime = ImageService.detectMimeType(item.file, originalBytes);
      MemoryUploadValidator.validateImageBytes(originalBytes, sourceMime);

      final takenAt = item.effectiveTakenAt(DateTime.now());
      final width =
          item.exif.imageWidth ?? ThumbnailService.decodeWidth(originalBytes);
      final height =
          item.exif.imageHeight ?? ThumbnailService.decodeHeight(originalBytes);

      report(0.25, 'Foto wird optimiert …');
      final compressed = ImageCompressionService.compressForUpload(
        bytes: originalBytes,
        sourceMimeType: sourceMime,
      );
      MemoryUploadValidator.validateImageBytes(
        compressed.bytes,
        compressed.mimeType,
      );

      final photoPath = StorageConstants.mediaPhotoPath(
        ownerId: userId,
        mediaItemId: mediaId,
        extension: compressed.extension,
        takenAt: takenAt,
      );

      report(0.45, 'Foto wird hochgeladen …');
      await _client.storage
          .from(StorageConstants.mediaPhotos)
          .uploadBinary(
            photoPath,
            compressed.bytes,
            fileOptions: FileOptions(
              contentType: compressed.mimeType,
              upsert: false,
            ),
          );
      uploadedPhotoPath = photoPath;

      final thumbBytes = ThumbnailService.createThumbnail(compressed.bytes);
      String? thumbPath;
      if (thumbBytes != null) {
        thumbPath = StorageConstants.mediaThumbnailPath(
          ownerId: userId,
          mediaItemId: mediaId,
          takenAt: takenAt,
        );
        await _client.storage
            .from(StorageConstants.mediaThumbnails)
            .uploadBinary(
              thumbPath,
              thumbBytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: false,
              ),
            );
        uploadedThumbPath = thumbPath;
      }

      report(0.75, 'Metadaten werden gespeichert …');

      final hasGps = item.hasGps;
      final locationSource = item.locationSourceLabel;
      final dateSource = item.dateSourceLabel;
      final metadataStatus = item.metadataStatusLabel;

      final insert = MediaItemModel(
        id: mediaId,
        ownerId: userId,
        tripId: tripId,
        familyId: familyId,
        mediaType: 'image',
        storagePath: photoPath,
        thumbnailPath: thumbPath,
        mimeType: compressed.mimeType,
        fileSizeBytes: compressed.bytes.length,
        takenAt: takenAt,
        latitude: hasGps ? item.effectiveLatitude : null,
        longitude: hasGps ? item.effectiveLongitude : null,
        altitude: hasGps && !item.hasManualGps ? item.exif.altitude : null,
        locationSource: locationSource,
        dateSource: dateSource,
        locationName: item.manualLocationName,
        metadataStatus: metadataStatus,
        title: item.title,
        description: item.description,
        width: width,
        height: height,
        exifData: item.exif.rawExifJson,
      );

      final row = await _client
          .from('media_items')
          .insert({'id': mediaId, ...insert.toInsertJson()})
          .select()
          .single();

      report(1.0, 'Fertig');
      final model = MediaItemModel.fromJson(Map<String, dynamic>.from(row));

      if (model.hasGps) {
        unawaited(MediaLocationEnrichmentService().enrichMediaItem(model));
      }

      final detectWidth =
          width ?? ThumbnailService.decodeWidth(compressed.bytes) ?? 0;
      final detectHeight =
          height ?? ThumbnailService.decodeHeight(compressed.bytes) ?? 0;
      if (detectWidth > 0 && detectHeight > 0) {
        unawaited(
          MediaFaceDetectionService().processAfterUpload(
            mediaId: mediaId,
            ownerId: userId,
            imageBytes: compressed.bytes,
            imageWidth: detectWidth,
            imageHeight: detectHeight,
          ),
        );
      }

      return model;
    } catch (error) {
      await _rollbackStorage(
        photoPath: uploadedPhotoPath,
        thumbPath: uploadedThumbPath,
      );
      throw _mapUploadError(error);
    }
  }

  /// Lädt ein Video in Storage + DB inkl. Container-Metadaten und Thumbnail.
  Future<MediaItemModel> uploadVideo({
    required XFile file,
    String? tripId,
    String? familyId,
    DateTime? manualTakenAt,
    String? title,
    String? description,
    MediaUploadProgress? onProgress,
    VideoMetadataExtractor? metadataExtractor,
  }) async {
    void report(double v, String label) => onProgress?.call(v, label);

    final userId = _userId;
    final mediaId = const Uuid().v4();
    String? uploadedVideoPath;
    String? uploadedThumbPath;
    final extractor = metadataExtractor ?? VideoMetadataExtractor();

    try {
      report(0.05, 'Video wird gelesen …');
      final bytes = await file.readAsBytes();
      final mime = _detectVideoMime(file, bytes);
      MemoryUploadValidator.validateVideoBytes(bytes, mime);

      DateTime? fileModified;
      try {
        fileModified = await file.lastModified();
      } catch (_) {
        fileModified = null;
      }

      report(0.2, 'Video-Metadaten werden gelesen …');
      final meta = await extractor.extract(
        filePath: file.path.isNotEmpty ? file.path : null,
        bytes: bytes,
        fileLastModified: fileModified,
      );

      final takenAt = manualTakenAt ?? meta.takenAt ?? DateTime.now();
      final hasMeaningfulDate = manualTakenAt != null || meta.takenAt != null;
      final dateSource = manualTakenAt != null
          ? 'manual'
          : (meta.takenAt != null ? meta.dateSource : 'created_at');
      final hasGps = meta.hasGps;
      final locationSource = hasGps ? meta.locationSource : 'unknown';
      final metadataStatus = MetadataStatusHelper.compute(
        hasDate: hasMeaningfulDate,
        hasLocation: hasGps,
        manualOverride: manualTakenAt != null,
      );

      final ext = _videoExtension(mime, file.name);
      final videoPath = StorageConstants.mediaVideoPath(
        ownerId: userId,
        mediaItemId: mediaId,
        extension: ext,
        takenAt: takenAt,
      );

      report(0.5, 'Video wird hochgeladen …');
      await _client.storage
          .from(StorageConstants.mediaVideos)
          .uploadBinary(
            videoPath,
            bytes,
            fileOptions: FileOptions(contentType: mime, upsert: false),
          );
      uploadedVideoPath = videoPath;

      String? thumbPath;
      if (meta.thumbnailJpeg != null && meta.thumbnailJpeg!.isNotEmpty) {
        thumbPath = StorageConstants.mediaThumbnailPath(
          ownerId: userId,
          mediaItemId: mediaId,
          takenAt: takenAt,
        );
        await _client.storage
            .from(StorageConstants.mediaThumbnails)
            .uploadBinary(
              thumbPath,
              meta.thumbnailJpeg!,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: false,
              ),
            );
        uploadedThumbPath = thumbPath;
      }

      report(0.8, 'Metadaten werden gespeichert …');
      final insert = MediaItemModel(
        id: mediaId,
        ownerId: userId,
        tripId: tripId,
        familyId: familyId,
        mediaType: 'video',
        storagePath: videoPath,
        thumbnailPath: thumbPath,
        mimeType: mime,
        fileSizeBytes: bytes.length,
        takenAt: takenAt,
        latitude: hasGps ? meta.latitude : null,
        longitude: hasGps ? meta.longitude : null,
        locationSource: locationSource,
        dateSource: dateSource,
        metadataStatus: metadataStatus,
        title: title,
        description: description,
        width: meta.width,
        height: meta.height,
        durationSeconds: meta.durationSeconds,
      );

      final row = await _client
          .from('media_items')
          .insert({'id': mediaId, ...insert.toInsertJson()})
          .select()
          .single();

      report(1.0, 'Fertig');
      final model = MediaItemModel.fromJson(Map<String, dynamic>.from(row));

      // Koordinaten immer speichern; Geocoding asynchron und nicht blockierend
      if (model.hasGps) {
        unawaited(MediaLocationEnrichmentService().enrichMediaItem(model));
      }

      return model;
    } catch (error) {
      await _rollbackVideoStorage(
        videoPath: uploadedVideoPath,
        thumbPath: uploadedThumbPath,
      );
      throw _mapUploadError(error);
    }
  }

  String _detectVideoMime(XFile file, List<int> bytes) {
    final fromName = file.mimeType?.toLowerCase().trim();
    if (fromName != null &&
        StorageConstants.allowedVideoMimeTypes.contains(fromName)) {
      return fromName;
    }
    final lower = file.name.toLowerCase();
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.m4v')) return 'video/x-m4v';
    if (lower.endsWith('.3gp')) return 'video/3gpp';
    if (bytes.length >= 12) {
      final brand = String.fromCharCodes(bytes.sublist(4, 8));
      if (brand == 'ftyp') return 'video/mp4';
    }
    return 'video/mp4';
  }

  String _videoExtension(String mime, String fileName) {
    final fromName = p.extension(fileName).replaceFirst('.', '');
    if (fromName.isNotEmpty) return fromName.toLowerCase();
    switch (mime) {
      case 'video/quicktime':
        return 'mov';
      case 'video/x-m4v':
        return 'm4v';
      case 'video/3gpp':
      case 'video/3gpp2':
        return '3gp';
      default:
        return 'mp4';
    }
  }

  Future<void> _rollbackStorage({String? photoPath, String? thumbPath}) async {
    try {
      if (photoPath != null) {
        await _client.storage.from(StorageConstants.mediaPhotos).remove([
          photoPath,
        ]);
      }
      if (thumbPath != null) {
        await _client.storage.from(StorageConstants.mediaThumbnails).remove([
          thumbPath,
        ]);
      }
    } catch (_) {
      // Rollback best effort
    }
  }

  Future<void> _rollbackVideoStorage({
    String? videoPath,
    String? thumbPath,
  }) async {
    try {
      if (videoPath != null) {
        await _client.storage.from(StorageConstants.mediaVideos).remove([
          videoPath,
        ]);
      }
      if (thumbPath != null) {
        await _client.storage.from(StorageConstants.mediaThumbnails).remove([
          thumbPath,
        ]);
      }
    } catch (_) {
      // Rollback best effort
    }
  }

  AppException _mapUploadError(Object error) {
    final mapped = ErrorMapper.map(error);
    final text = error.toString().toLowerCase();
    if (text.contains('socket') ||
        text.contains('network') ||
        text.contains('connection') ||
        text.contains('failed host lookup')) {
      return const AppException(
        message: 'Der Upload wurde unterbrochen.',
        code: 'upload_network',
      );
    }
    if (mapped.code == MemoryUploadValidator.imageTooLargeCode) {
      return mapped;
    }
    if (mapped.code == MemoryUploadValidator.invalidImageTypeCode) {
      return mapped;
    }
    if (mapped.code == MemoryUploadValidator.videoTooLargeCode) {
      return mapped;
    }
    if (mapped.code == MemoryUploadValidator.invalidVideoTypeCode) {
      return mapped;
    }
    return AppException(
      message: mapped.message.contains('unerwartet')
          ? 'Einige Dateien konnten nicht hochgeladen werden.'
          : mapped.message,
      code: mapped.code,
    );
  }

  /// Liest EXIF für ein Warteschlangen-Element.
  static Future<PhotoExifMetadata> readExif(XFile file) async {
    final bytes = await file.readAsBytes();
    final lastModified = await file.lastModified();
    return ExifMetadataService.read(bytes, fileLastModified: lastModified);
  }
}
