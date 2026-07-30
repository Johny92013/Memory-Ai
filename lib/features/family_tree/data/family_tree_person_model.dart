/// Person im Familienstammbaum (`family_tree_people`).
class FamilyTreePersonModel {
  const FamilyTreePersonModel({
    required this.id,
    required this.familyId,
    required this.firstName,
    this.lastName,
    this.linkedProfileId,
    this.birthDate,
    this.deathDate,
    this.gender,
    this.photoPath,
    this.notes,
  });

  final String id;
  final String familyId;
  final String firstName;
  final String? lastName;
  final String? linkedProfileId;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String? gender;
  final String? photoPath;
  final String? notes;

  String get displayName {
    final parts = [
      firstName,
      lastName,
    ].whereType<String>().map((p) => p.trim()).where((p) => p.isNotEmpty);
    return parts.join(' ');
  }

  factory FamilyTreePersonModel.fromJson(Map<String, dynamic> json) {
    return FamilyTreePersonModel(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String?,
      linkedProfileId: json['linked_profile_id'] as String?,
      birthDate: _parseDate(json['birth_date']),
      deathDate: _parseDate(json['death_date']),
      gender: json['gender'] as String?,
      photoPath: json['photo_path'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'family_id': familyId,
    'first_name': firstName,
    if (lastName != null) 'last_name': lastName,
    if (linkedProfileId != null) 'linked_profile_id': linkedProfileId,
    if (birthDate != null)
      'birth_date': birthDate!.toIso8601String().split('T').first,
    if (deathDate != null)
      'death_date': deathDate!.toIso8601String().split('T').first,
    if (gender != null) 'gender': gender,
    if (photoPath != null) 'photo_path': photoPath,
    if (notes != null) 'notes': notes,
  };

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
