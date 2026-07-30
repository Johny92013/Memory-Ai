/// Beziehung zwischen zwei Stammbaum-Personen (`family_relationships`).
class FamilyRelationshipModel {
  const FamilyRelationshipModel({
    required this.id,
    required this.familyId,
    required this.personAId,
    required this.personBId,
    required this.type,
  });

  final String id;
  final String familyId;
  final String personAId;
  final String personBId;
  final String type;

  factory FamilyRelationshipModel.fromJson(Map<String, dynamic> json) {
    return FamilyRelationshipModel(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      personAId: json['person_a_id'] as String,
      personBId: json['person_b_id'] as String,
      type: json['relationship_type'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'family_id': familyId,
    'person_a_id': personAId,
    'person_b_id': personBId,
    'relationship_type': type,
  };
}
