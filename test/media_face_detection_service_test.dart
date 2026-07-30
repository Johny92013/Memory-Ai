import 'package:flutter_test/flutter_test.dart';
import 'package:memory_ai/features/memories/data/face_detector_engine.dart';
import 'package:memory_ai/features/memories/data/media_face_detection_model.dart';
import 'package:memory_ai/features/memories/data/media_face_detection_repository.dart';
import 'package:memory_ai/features/memories/data/media_face_detection_service.dart';

class _FakeEngine implements FaceDetectorEngine {
  _FakeEngine({this.faces = const []});

  final List<DetectedFaceBox> faces;
  int callCount = 0;

  @override
  Future<List<DetectedFaceBox>> detectFaces({
    required List<int> imageBytes,
    required int imageWidth,
    required int imageHeight,
  }) async {
    callCount++;
    return faces;
  }

  @override
  Future<void> dispose() async {}
}

class _MemoryStore implements MediaFaceDetectionStore {
  final inserted = <MediaFaceDetectionModel>[];
  final deletedUsers = <String>[];

  @override
  Future<void> insertMany(List<MediaFaceDetectionModel> items) async {
    inserted.addAll(items);
  }

  @override
  Future<void> deleteAllForUser(String userId) async {
    deletedUsers.add(userId);
    inserted.removeWhere((e) => e.ownerId == userId);
  }
}

void main() {
  group('MediaFaceDetectionService', () {
    test(
      'ohne Einwilligung wird KEINE Detection ausgeführt und kein Eintrag erzeugt',
      () async {
        final engine = _FakeEngine(
          faces: [
            const DetectedFaceBox(
              boundingBox: (x: 0.1, y: 0.1, width: 0.2, height: 0.2),
            ),
          ],
        );
        final store = _MemoryStore();

        final result =
            await MediaFaceDetectionService(
              consentCheck: (_) async => false,
              engine: engine,
              repository: store,
            ).processAfterUpload(
              mediaId: 'm1',
              ownerId: 'u1',
              imageBytes: [1, 2, 3],
              imageWidth: 100,
              imageHeight: 100,
            );

        expect(result, isEmpty);
        expect(engine.callCount, 0);
        expect(store.inserted, isEmpty);
      },
    );

    test(
      'mit Einwilligung wird Detection ausgeführt und gespeichert',
      () async {
        final engine = _FakeEngine(
          faces: [
            const DetectedFaceBox(
              boundingBox: (x: 0.1, y: 0.2, width: 0.3, height: 0.4),
              confidence: 0.9,
            ),
            const DetectedFaceBox(
              boundingBox: (x: 0.5, y: 0.2, width: 0.25, height: 0.35),
            ),
          ],
        );
        final store = _MemoryStore();

        final result =
            await MediaFaceDetectionService(
              consentCheck: (_) async => true,
              engine: engine,
              repository: store,
            ).processAfterUpload(
              mediaId: 'm1',
              ownerId: 'u1',
              imageBytes: [1, 2, 3],
              imageWidth: 200,
              imageHeight: 200,
            );

        expect(engine.callCount, 1);
        expect(result.length, 2);
        expect(store.inserted.length, 2);
        expect(store.inserted.first.mediaId, 'm1');
        expect(store.inserted.first.ownerId, 'u1');
        expect(store.inserted.first.boundingBox.x, 0.1);
        expect(store.inserted.first.source, 'ml_kit');
      },
    );

    test('Widerruf löscht bestehende Einträge vollständig', () async {
      final store = _MemoryStore();
      await store.insertMany([
        const MediaFaceDetectionModel(
          id: 'd1',
          mediaId: 'm1',
          ownerId: 'u1',
          boundingBox: FaceBoundingBox(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
        ),
        const MediaFaceDetectionModel(
          id: 'd2',
          mediaId: 'm2',
          ownerId: 'u1',
          boundingBox: FaceBoundingBox(x: 0.3, y: 0.3, width: 0.2, height: 0.2),
        ),
      ]);
      expect(store.inserted.length, 2);

      await store.deleteAllForUser('u1');

      expect(store.deletedUsers, ['u1']);
      expect(store.inserted, isEmpty);
    });
  });
}
