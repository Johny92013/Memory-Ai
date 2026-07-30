/// Album-Modell (Phase 4).
class AlbumModel {
  const AlbumModel({
    required this.id,
    required this.familyId,
    required this.title,
    this.coverPath,
    this.createdAt,
  });

  final String id;
  final String familyId;
  final String title;
  final String? coverPath;
  final DateTime? createdAt;

  factory AlbumModel.fromJson(Map<String, dynamic> json) {
    return AlbumModel(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      title: json['title'] as String? ?? '',
      coverPath: json['cover_path'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'family_id': familyId,
    'title': title,
    if (coverPath != null) 'cover_path': coverPath,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };
}
