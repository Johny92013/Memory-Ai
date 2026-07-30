import 'package:flutter_test/flutter_test.dart';
import 'package:memory_ai/features/trips/data/trip_role_permissions.dart';

void main() {
  group('TripRolePermissions', () {
    test('viewer kann lesen aber nicht bearbeiten oder hochladen', () {
      expect(TripRolePermissions.canViewTrip('viewer'), isTrue);
      expect(TripRolePermissions.canEditTrip('viewer'), isFalse);
      expect(TripRolePermissions.canUploadMedia('viewer'), isFalse);
      expect(
        TripRolePermissions.canEditMedia('viewer', isOwnMedia: true),
        isFalse,
      );
    });

    test('contributor kann hochladen und eigene Medien bearbeiten', () {
      expect(TripRolePermissions.canUploadMedia('contributor'), isTrue);
      expect(
        TripRolePermissions.canEditMedia('contributor', isOwnMedia: true),
        isTrue,
      );
      expect(
        TripRolePermissions.canEditMedia('contributor', isOwnMedia: false),
        isFalse,
      );
      expect(TripRolePermissions.canEditTrip('contributor'), isFalse);
    });

    test('editor kann Reise und alle Medien bearbeiten', () {
      expect(TripRolePermissions.canEditTrip('editor'), isTrue);
      expect(
        TripRolePermissions.canEditMedia('editor', isOwnMedia: false),
        isTrue,
      );
      expect(TripRolePermissions.canManageMembers('editor'), isFalse);
    });

    test('owner hat volle Rechte', () {
      expect(TripRolePermissions.canManageMembers('owner'), isTrue);
      expect(TripRolePermissions.canDeleteTrip('owner'), isTrue);
    });
  });
}
