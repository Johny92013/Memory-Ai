import 'package:flutter_test/flutter_test.dart';
import 'package:memory_ai/features/memories/data/exif_metadata_service.dart';
import 'package:memory_ai/features/memories/data/person_model.dart';
import 'package:memory_ai/features/people/data/tagged_media_models.dart';
import 'package:memory_ai/features/trips/data/trip_role_permissions.dart';

void main() {
  group('Person tagging write path helpers', () {
    test('linkedProfileId survives copyWith', () {
      const p = PersonModel(
        id: 'p1',
        ownerId: 'o1',
        name: 'Anna',
        linkedProfileId: 'u-anna',
      );
      expect(p.copyWith(name: 'Anna M.').linkedProfileId, 'u-anna');
    });

    test('pending confirmation is open status', () {
      expect(
        MediaPersonStatus.openStatuses.contains(
          MediaPersonStatus.pendingConfirmation,
        ),
        isTrue,
      );
    });
  });

  group('EXIF date priority', () {
    test('DateTimeOriginal wins over file date', () {
      final meta = PhotoExifMetadata(
        dateTimeOriginal: DateTime.utc(2020, 1, 2),
        fileLastModified: DateTime.utc(2024, 1, 1),
      );
      expect(meta.resolveTakenAt(), DateTime.utc(2020, 1, 2));
      expect(meta.debugDateSourceLabel(), 'DateTimeOriginal');
    });

    test('CreateDate used when original missing', () {
      final meta = PhotoExifMetadata(
        createDateTag: DateTime.utc(2021, 5, 6),
        fileLastModified: DateTime.utc(2024, 1, 1),
      );
      expect(meta.resolveTakenAt(), DateTime.utc(2021, 5, 6));
      expect(meta.debugDateSourceLabel(), 'CreateDate');
    });

    test('manual override wins', () {
      final meta = PhotoExifMetadata(
        dateTimeOriginal: DateTime.utc(2020, 1, 2),
      );
      final manual = DateTime.utc(2019, 9, 9);
      expect(meta.resolveTakenAt(manualDate: manual), manual);
      expect(meta.resolveDateSource(manualDate: manual), 'manual');
    });
  });

  group('Trip roles', () {
    test('contributor can upload, viewer cannot', () {
      expect(TripRolePermissions.canUploadMedia('contributor'), isTrue);
      expect(TripRolePermissions.canUploadMedia('viewer'), isFalse);
      expect(TripRolePermissions.canManageMembers('owner'), isTrue);
      expect(TripRolePermissions.canManageMembers('editor'), isFalse);
    });
  });
}
