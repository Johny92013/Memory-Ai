/// Familienmodell für `public.families`.
class FamilyModel {
  const FamilyModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdBy,
    required this.createdAt,
    this.description,
    this.imagePath,
  });

  final String id;
  final String name;
  final String inviteCode;
  final String createdBy;
  final DateTime createdAt;
  final String? description;
  final String? imagePath;

  factory FamilyModel.fromJson(Map<String, dynamic> json) {
    final inviteCode = (json['invite_code'] as String?)?.trim() ?? '';
    return FamilyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      inviteCode: inviteCode,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      description: json['description'] as String?,
      imagePath: json['image_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'invite_code': inviteCode,
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
    if (description != null) 'description': description,
    if (imagePath != null) 'image_path': imagePath,
  };
}
