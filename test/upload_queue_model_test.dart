import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:memory_ai/features/memories/data/exif_metadata_service.dart';
import 'package:memory_ai/features/memories/data/upload_queue_model.dart';

void main() {
  group('UploadQueueItem', () {
    test('effectiveTakenAt nutzt manuelles Datum', () {
      final item = UploadQueueItem(
        id: '1',
        file: XFile('test.jpg'),
        manualTakenAt: DateTime(2025, 2, 1, 14, 0),
        exif: PhotoExifMetadata(dateTimeOriginal: DateTime(2024, 1, 1)),
      );
      expect(
        item.effectiveTakenAt(DateTime(2026)),
        DateTime(2025, 2, 1, 14, 0),
      );
    });

    test('metadataStatusLabel manual bei Bearbeitung', () {
      final item = UploadQueueItem(
        id: '1',
        file: XFile('test.jpg'),
        wasEdited: true,
      );
      expect(item.metadataStatusLabel, 'manual');
    });

    test('canRetry nur bei failed', () {
      final failed = UploadQueueItem(
        id: '1',
        file: XFile('a.jpg'),
        status: UploadQueueStatus.failed,
      );
      final done = UploadQueueItem(
        id: '2',
        file: XFile('b.jpg'),
        status: UploadQueueStatus.completed,
        uploadedMediaId: 'x',
      );
      expect(failed.canRetry, isTrue);
      expect(done.canUpload, isFalse);
    });
  });
}
