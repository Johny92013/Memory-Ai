import 'package:flutter_test/flutter_test.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';

void main() {
  group('MediaItemModel', () {
    test('fromJson und toInsertJson', () {
      final json = {
        'id': 'abc-123',
        'owner_id': 'user-1',
        'media_type': 'image',
        'storage_path': 'user-1/2024/06/abc.jpg',
        'thumbnail_path': 'user-1/2024/06/abc_thumb.jpg',
        'taken_at': '2024-06-15T10:30:00.000Z',
        'latitude': 48.1,
        'longitude': 11.5,
        'location_source': 'exif',
        'metadata_status': 'automatic',
        'width': 1920,
        'height': 1080,
        'exif_data': {'Make': 'Apple'},
      };

      final model = MediaItemModel.fromJson(json);
      expect(model.id, 'abc-123');
      expect(model.hasThumbnail, isTrue);
      expect(model.latitude, 48.1);

      final insert = model.toInsertJson();
      expect(insert['owner_id'], 'user-1');
      expect(insert['media_type'], 'image');
      expect(insert['metadata_status'], 'automatic');
      expect(insert['exif_data'], {'Make': 'Apple'});
    });
  });
}
