/// Reise (`public.trips`).
class TripModel {
  const TripModel({
    required this.id,
    required this.ownerId,
    this.familyId,
    required this.title,
    this.description,
    this.status = 'planning',
    this.startDate,
    this.endDate,
    this.coverMediaId,
    this.createdAt,
    this.updatedAt,
    this.photoCount = 0,
    this.locationCount = 0,
    this.countries = const [],
    this.myRole,
  });

  final String id;
  final String ownerId;
  final String? familyId;
  final String title;
  final String? description;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? coverMediaId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int photoCount;
  final int locationCount;
  final List<String> countries;
  final String? myRole;

  bool get isActive => status == 'active' || status == 'planning';
  bool get isPast => status == 'completed' || status == 'archived';

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      familyId: json['family_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'planning',
      startDate: _parseDate(json['start_date']),
      endDate: _parseDate(json['end_date']),
      coverMediaId: json['cover_media_id'] as String?,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      photoCount: (json['photo_count'] as num?)?.toInt() ?? 0,
      locationCount: (json['location_count'] as num?)?.toInt() ?? 0,
      countries: json['countries'] != null
          ? List<String>.from(json['countries'] as List)
          : const [],
      myRole: json['my_role'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() => {
    'owner_id': ownerId,
    if (familyId != null) 'family_id': familyId,
    'title': title,
    if (description != null) 'description': description,
    'status': status,
    if (startDate != null) 'start_date': _formatDate(startDate!),
    if (endDate != null) 'end_date': _formatDate(endDate!),
    if (coverMediaId != null) 'cover_media_id': coverMediaId,
  };

  Map<String, dynamic> toUpdateJson() => {
    if (title.isNotEmpty) 'title': title,
    if (description != null) 'description': description,
    'status': status,
    if (startDate != null) 'start_date': _formatDate(startDate!),
    if (endDate != null) 'end_date': _formatDate(endDate!),
    if (coverMediaId != null) 'cover_media_id': coverMediaId,
  };

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
