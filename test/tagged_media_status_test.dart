import 'package:flutter_test/flutter_test.dart';
import 'package:memory_ai/features/people/data/tagged_media_models.dart';

void main() {
  group('MediaPersonStatus', () {
    test('open vs confirmed vs rejected partitions', () {
      expect(
        MediaPersonStatus.openStatuses,
        containsAll([
          MediaPersonStatus.suggested,
          MediaPersonStatus.pendingConfirmation,
        ]),
      );
      expect(
        MediaPersonStatus.confirmedStatuses,
        containsAll([
          MediaPersonStatus.confirmed,
          MediaPersonStatus.acceptedToGallery,
          MediaPersonStatus.linkedOnly,
        ]),
      );
      expect(MediaPersonStatus.rejectedStatuses, [MediaPersonStatus.rejected]);
    });

    test('TaggedMediaItem parses inbox row without storage copy fields', () {
      final item = TaggedMediaItem.fromJson({
        'tag_id': 't1',
        'media_id': 'm1',
        'status': MediaPersonStatus.pendingConfirmation,
        'source': 'manual',
        'created_at': '2026-08-01T10:00:00Z',
        'media_type': 'image',
        'owner_id': 'u1',
        'owner_name': 'Anna',
        'tagged_by_name': 'Michael',
        'storage_path': 'u1/2026/08/m1.jpg',
      });
      expect(item.isOpen, isTrue);
      expect(item.ownerName, 'Anna');
      expect(item.storagePath, 'u1/2026/08/m1.jpg');
      expect(item.status, MediaPersonStatus.pendingConfirmation);
    });

    test('accepted_to_gallery remains a link status not a copy', () {
      final item = TaggedMediaItem.fromJson({
        'tag_id': 't2',
        'media_id': 'm2',
        'status': MediaPersonStatus.acceptedToGallery,
        'source': 'family_tag',
        'created_at': '2026-08-01T10:00:00Z',
        'added_to_gallery_at': '2026-08-01T11:00:00Z',
        'media_type': 'image',
        'owner_id': 'uploader',
      });
      expect(item.ownerId, 'uploader');
      expect(item.addedToGalleryAt, isNotNull);
      expect(MediaPersonStatus.confirmedStatuses.contains(item.status), isTrue);
      expect(item.isOpen, isFalse);
    });
  });

  group('GalleryOwnershipFilter', () {
    test('has expected values', () {
      expect(GalleryOwnershipFilter.values.length, 4);
    });
  });
}
