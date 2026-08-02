/// Mitreisender ohne Account (`public.trip_companions`).
class TripCompanionModel {
  const TripCompanionModel({
    required this.id,
    required this.tripId,
    required this.displayName,
    this.notes,
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String tripId;
  final String displayName;
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;

  factory TripCompanionModel.fromJson(Map<String, dynamic> json) {
    return TripCompanionModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      displayName: json['display_name'] as String? ?? '',
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
