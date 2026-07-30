/// Medien-Element (`public.media_items`).
class MediaItemModel {
  const MediaItemModel({
    required this.id,
    required this.ownerId,
    this.tripId,
    this.familyId,
    required this.mediaType,
    this.storagePath,
    this.thumbnailPath,
    this.mimeType,
    this.fileSizeBytes,
    this.takenAt,
    this.latitude,
    this.longitude,
    this.altitude,
    this.locationSource = 'unknown',
    this.dateSource = 'unknown',
    this.locationName,
    this.countryName,
    this.city,
    this.countryCode,
    this.regionName,
    this.continent,
    this.metadataStatus = 'automatic',
    this.title,
    this.description,
    this.width,
    this.height,
    this.durationSeconds,
    this.exifData,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String? tripId;
  final String? familyId;
  final String mediaType;
  final String? storagePath;
  final String? thumbnailPath;
  final String? mimeType;
  final int? fileSizeBytes;
  final DateTime? takenAt;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final String locationSource;
  final String dateSource;
  final String? locationName;
  final String? countryName;
  final String? city;
  final String? countryCode;
  final String? regionName;
  final String? continent;
  final String metadataStatus;
  final String? title;
  final String? description;
  final int? width;
  final int? height;
  final int? durationSeconds;
  final Map<String, dynamic>? exifData;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasThumbnail => thumbnailPath != null && thumbnailPath!.isNotEmpty;

  bool get hasGps => latitude != null && longitude != null;

  factory MediaItemModel.fromJson(Map<String, dynamic> json) {
    return MediaItemModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      tripId: json['trip_id'] as String?,
      familyId: json['family_id'] as String?,
      mediaType: json['media_type'] as String? ?? 'image',
      storagePath: json['storage_path'] as String?,
      thumbnailPath: json['thumbnail_path'] as String?,
      mimeType: json['mime_type'] as String?,
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt(),
      takenAt: _parseDateTime(json['taken_at']),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      locationSource: json['location_source'] as String? ?? 'unknown',
      dateSource: json['date_source'] as String? ?? 'unknown',
      locationName: json['location_name'] as String?,
      countryName: json['country_name'] as String?,
      city: json['city'] as String?,
      countryCode: json['country_code'] as String?,
      regionName: json['region_name'] as String?,
      continent: json['continent'] as String?,
      metadataStatus: json['metadata_status'] as String? ?? 'automatic',
      title: json['title'] as String?,
      description: json['description'] as String?,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      exifData: json['exif_data'] != null
          ? Map<String, dynamic>.from(json['exif_data'] as Map)
          : null,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'owner_id': ownerId,
      if (tripId != null) 'trip_id': tripId,
      if (familyId != null) 'family_id': familyId,
      'media_type': mediaType,
      if (storagePath != null) 'storage_path': storagePath,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (mimeType != null) 'mime_type': mimeType,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (takenAt != null) 'taken_at': takenAt!.toUtc().toIso8601String(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (altitude != null) 'altitude': altitude,
      'location_source': locationSource,
      'date_source': dateSource,
      if (locationName != null) 'location_name': locationName,
      if (countryName != null) 'country_name': countryName,
      if (city != null) 'city': city,
      if (countryCode != null) 'country_code': countryCode,
      if (regionName != null) 'region_name': regionName,
      if (continent != null) 'continent': continent,
      'metadata_status': metadataStatus,
      if (title != null && title!.trim().isNotEmpty) 'title': title!.trim(),
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (exifData != null) 'exif_data': exifData,
    };
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
