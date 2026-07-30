import 'package:flutter_test/flutter_test.dart';
import 'package:memory_ai/features/family_tree/data/family_relationship_model.dart';
import 'package:memory_ai/features/family_tree/data/family_tree_person_model.dart';
import 'package:memory_ai/features/family_tree/data/family_tree_repository.dart';

void main() {
  group('FamilyTreeRepository.generationLayout', () {
    const grandpa = FamilyTreePersonModel(
      id: 'g',
      familyId: 'f1',
      firstName: 'Opa',
    );
    const parent = FamilyTreePersonModel(
      id: 'p',
      familyId: 'f1',
      firstName: 'Papa',
    );
    const child = FamilyTreePersonModel(
      id: 'c',
      familyId: 'f1',
      firstName: 'Kind',
    );

    test('leere Beziehungen setzt alle auf Generation 0', () {
      final layout = FamilyTreeRepository.generationLayout([
        grandpa,
        parent,
        child,
      ], []);
      expect(layout, {'g': 0, 'p': 0, 'c': 0});
    });

    test('parent-Kante erhöht Generation des Kindes', () {
      final relationships = [
        const FamilyRelationshipModel(
          id: 'r1',
          familyId: 'f1',
          personAId: 'p',
          personBId: 'c',
          type: 'parent',
        ),
      ];
      final layout = FamilyTreeRepository.generationLayout([
        parent,
        child,
      ], relationships);
      expect(layout['p'], 0);
      expect(layout['c'], 1);
    });

    test('mehrstufige Eltern-Ketten', () {
      final relationships = [
        const FamilyRelationshipModel(
          id: 'r1',
          familyId: 'f1',
          personAId: 'g',
          personBId: 'p',
          type: 'parent',
        ),
        const FamilyRelationshipModel(
          id: 'r2',
          familyId: 'f1',
          personAId: 'p',
          personBId: 'c',
          type: 'parent',
        ),
      ];
      final layout = FamilyTreeRepository.generationLayout([
        grandpa,
        parent,
        child,
      ], relationships);
      expect(layout['g'], 0);
      expect(layout['p'], 1);
      expect(layout['c'], 2);
    });

    test('ignoriert Nicht-Eltern-Beziehungen', () {
      final relationships = [
        const FamilyRelationshipModel(
          id: 'r1',
          familyId: 'f1',
          personAId: 'p',
          personBId: 'c',
          type: 'sibling',
        ),
      ];
      final layout = FamilyTreeRepository.generationLayout([
        parent,
        child,
      ], relationships);
      expect(layout['p'], 0);
      expect(layout['c'], 0);
    });
  });
}
