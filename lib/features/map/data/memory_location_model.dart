/// Standort einer Erinnerung auf der Karte.
class MemoryLocationModel {
  const MemoryLocationModel({
    required this.id,
    required this.familyId,
    required this.latitude,
    required this.longitude,
    this.label,
    this.memoryCount = 0,
  });

  final String id;
  final String familyId;
  final double latitude;
  final double longitude;
  final String? label;
  final int memoryCount;

  factory MemoryLocationModel.fromJson(Map<String, dynamic> json) {
    return MemoryLocationModel(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      label: json['label'] as String?,
      memoryCount: json['memory_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'family_id': familyId,
    'latitude': latitude,
    'longitude': longitude,
    if (label != null) 'label': label,
    'memory_count': memoryCount,
  };
}
