/// Person auf Erinnerungsfotos (`public.people`).
class PersonModel {
  const PersonModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.avatarPath,
    this.linkedTreePersonId,
    this.detectionSource = 'manual',
  });

  final String id;
  final String ownerId;
  final String name;
  final String? avatarPath;
  final String? linkedTreePersonId;
  final String detectionSource;

  factory PersonModel.fromJson(Map<String, dynamic> json) {
    return PersonModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      avatarPath: json['avatar_path'] as String?,
      linkedTreePersonId: json['linked_tree_person_id'] as String?,
      detectionSource: json['detection_source'] as String? ?? 'manual',
    );
  }
}
