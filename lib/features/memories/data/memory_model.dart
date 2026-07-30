/// Erinnerungsmodell (Phase 4).
class MemoryModel {
  const MemoryModel({
    required this.id,
    required this.familyId,
    required this.createdBy,
    this.title,
    this.description,
    required this.mediaType,
    this.storagePath,
    this.takenAt,
    this.latitude,
    this.longitude,
    this.locationName,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String familyId;
  final String createdBy;
  final String? title;
  final String? description;
  final String mediaType;
  final String? storagePath;
  final DateTime? takenAt;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory MemoryModel.fromJson(Map<String, dynamic> json) {
    return MemoryModel(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      createdBy: json['created_by'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      mediaType: json['media_type'] as String? ?? 'image',
      storagePath: json['storage_path'] as String?,
      takenAt: _parseDate(json['taken_at']),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationName: json['location_name'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'family_id': familyId,
    'created_by': createdBy,
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    'media_type': mediaType,
    if (storagePath != null) 'storage_path': storagePath,
    if (takenAt != null) 'taken_at': takenAt!.toIso8601String(),
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (locationName != null) 'location_name': locationName,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };
}
