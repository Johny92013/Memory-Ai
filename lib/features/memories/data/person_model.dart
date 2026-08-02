/// Person auf Erinnerungsfotos (`public.people`).
class PersonModel {
  const PersonModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.avatarPath,
    this.linkedTreePersonId,
    this.detectionSource = 'manual',
    this.linkedProfileId,
  });

  final String id;
  final String ownerId;
  final String name;
  final String? avatarPath;
  final String? linkedTreePersonId;
  final String detectionSource;

  /// App-Nutzer-Profil, falls diese Person ein Familienmitglied mit Account ist.
  /// Nicht in der DB-Spalte von `people` – nur für Tagging-Flows im Client.
  final String? linkedProfileId;

  PersonModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? avatarPath,
    String? linkedTreePersonId,
    String? detectionSource,
    String? linkedProfileId,
  }) {
    return PersonModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      linkedTreePersonId: linkedTreePersonId ?? this.linkedTreePersonId,
      detectionSource: detectionSource ?? this.detectionSource,
      linkedProfileId: linkedProfileId ?? this.linkedProfileId,
    );
  }

  factory PersonModel.fromJson(Map<String, dynamic> json) {
    return PersonModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      avatarPath: json['avatar_path'] as String?,
      linkedTreePersonId: json['linked_tree_person_id'] as String?,
      detectionSource: json['detection_source'] as String? ?? 'manual',
      linkedProfileId: json['linked_profile_id'] as String?,
    );
  }
}
