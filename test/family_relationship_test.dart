import 'package:flutter_test/flutter_test.dart';
import 'package:memory_ai/features/family_tree/data/family_tree_repository.dart';

void main() {
  group('FamilyTreeRepository.mirrorRelationship', () {
    test('spiegelt parent zu child', () {
      expect(FamilyTreeRepository.mirrorRelationship('parent'), 'child');
    });

    test('spiegelt child zu parent', () {
      expect(FamilyTreeRepository.mirrorRelationship('child'), 'parent');
    });

    test('symmetrische Typen bleiben gleich', () {
      for (final type in ['spouse', 'sibling', 'partner', 'other']) {
        expect(FamilyTreeRepository.mirrorRelationship(type), type);
      }
    });

    test('unbekannter Typ liefert null', () {
      expect(FamilyTreeRepository.mirrorRelationship('cousin'), isNull);
    });
  });
}
