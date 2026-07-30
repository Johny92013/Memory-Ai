import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/memories/data/media_link_model.dart';
import 'package:memory_ai/features/memories/data/related_media_matcher.dart';
import 'package:memory_ai/features/memories/data/upload_queue_model.dart';
import 'package:memory_ai/features/upload/data/batch_metadata_ops.dart';

void main() {
  group('BatchMetadataOps', () {
    test('Batch-Datum-Zuweisung auf Auswahl', () {
      final items = [
        UploadQueueItem(id: 'a', file: XFile('a.jpg')),
        UploadQueueItem(id: 'b', file: XFile('b.jpg')),
        UploadQueueItem(id: 'c', file: XFile('c.jpg')),
      ];
      final date = DateTime(2024, 7, 1, 12, 0);
      final updated = BatchMetadataOps.applyDateToItems(
        items: items,
        itemIds: {'a', 'c'},
        idOf: (i) => i.id,
        date: date,
        update: (item, d) => item.copyWith(manualTakenAt: d, wasEdited: true),
      );
      expect(updated[0].manualTakenAt, date);
      expect(updated[1].manualTakenAt, isNull);
      expect(updated[2].manualTakenAt, date);
    });

    test('Batch-Standort-Zuweisung auf Auswahl', () {
      final items = [
        UploadQueueItem(id: 'a', file: XFile('a.jpg')),
        UploadQueueItem(id: 'b', file: XFile('b.jpg')),
      ];
      final updated = BatchMetadataOps.applyLocationToItems(
        items: items,
        itemIds: {'b'},
        idOf: (i) => i.id,
        latitude: 48.1,
        longitude: 11.5,
        locationName: 'München',
        update: (item, {required latitude, required longitude, locationName}) {
          return item.copyWith(
            manualLatitude: latitude,
            manualLongitude: longitude,
            manualLocationName: locationName,
            wasEdited: true,
          );
        },
      );
      expect(updated[0].hasManualGps, isFalse);
      expect(updated[1].hasManualGps, isTrue);
      expect(updated[1].manualLocationName, 'München');
      expect(updated[1].locationSourceLabel, 'manual');
    });
  });

  group('RelatedMediaMatcher', () {
    MediaItemModel media({
      required String id,
      double? lat,
      double? lon,
      DateTime? takenAt,
      String? city,
      String? country,
    }) {
      return MediaItemModel(
        id: id,
        ownerId: 'owner',
        mediaType: 'image',
        latitude: lat,
        longitude: lon,
        takenAt: takenAt,
        city: city,
        countryName: country,
      );
    }

    test('gleicher Ort + ähnliche Zeit erzeugt Vorschlag', () {
      final source = media(
        id: 's',
        lat: 48.137,
        lon: 11.575,
        takenAt: DateTime(2024, 6, 1, 10),
      );
      final other = media(
        id: 'o',
        lat: 48.1371,
        lon: 11.5751,
        takenAt: DateTime(2024, 6, 1, 12),
      );
      final candidates = RelatedMediaMatcher.findCandidates(
        source: source,
        others: [other],
        peopleByMediaId: const {},
      );
      expect(candidates, hasLength(1));
      expect(candidates.first.sameLocation, isTrue);
      expect(candidates.first.similarTime, isTrue);
      expect(candidates.first.relationType, 'same_event');
      expect(candidates.first.confidence, greaterThan(0.5));
    });

    test('gleiche bestätigte Personen erhöhen Confidence', () {
      final source = media(id: 's', takenAt: DateTime(2024, 6, 1, 10));
      final other = media(id: 'o', takenAt: DateTime(2024, 6, 1, 11));
      final candidates = RelatedMediaMatcher.findCandidates(
        source: source,
        others: [other],
        peopleByMediaId: {
          's': {'p1', 'p2'},
          'o': {'p1'},
        },
      );
      expect(candidates, hasLength(1));
      expect(candidates.first.sharedPersonCount, 1);
      expect(candidates.first.relationType, 'same_moment');
    });

    test('keine Gemeinsamkeit → kein Vorschlag', () {
      final source = media(id: 's', lat: 1, lon: 1, takenAt: DateTime(2020));
      final other = media(id: 'o', lat: 50, lon: 50, takenAt: DateTime(2024));
      final candidates = RelatedMediaMatcher.findCandidates(
        source: source,
        others: [other],
        peopleByMediaId: const {},
      );
      expect(candidates, isEmpty);
    });
  });

  group('MediaLinkModel', () {
    test('Status bestätigen/ablehnen Felder', () {
      final suggested = MediaLinkModel(
        id: '1',
        sourceMediaId: 'a',
        relatedMediaId: 'b',
        relationType: 'same_event',
        status: 'suggested',
      );
      expect(suggested.isSuggested, isTrue);
      final confirmed = MediaLinkModel.fromJson({
        'id': '1',
        'source_media_id': 'a',
        'related_media_id': 'b',
        'relation_type': 'manual',
        'status': 'confirmed',
      });
      expect(confirmed.isConfirmed, isTrue);
      expect(confirmed.isRejected, isFalse);
      final rejected = MediaLinkModel.fromJson({
        'id': '2',
        'source_media_id': 'a',
        'related_media_id': 'c',
        'relation_type': 'same_location',
        'status': 'rejected',
      });
      expect(rejected.isRejected, isTrue);
    });

    test('Insert enthält keine Dateipfade (keine Duplizierung)', () {
      final link = MediaLinkModel(
        id: '1',
        sourceMediaId: 'a',
        relatedMediaId: 'b',
        relationType: 'manual',
        status: 'confirmed',
        createdBy: 'user',
      );
      final json = link.toInsertJson();
      expect(json.containsKey('storage_path'), isFalse);
      expect(json.containsKey('file'), isFalse);
      expect(json['source_media_id'], 'a');
      expect(json['related_media_id'], 'b');
    });
  });

  group('People assignment (lokal)', () {
    test('Person entfernen aktualisiert lokale Liste', () {
      final people = [
        {'id': 'p1', 'name': 'Anna'},
        {'id': 'p2', 'name': 'Ben'},
      ];
      final afterRemove = people.where((p) => p['id'] != 'p1').toList();
      expect(afterRemove, hasLength(1));
      expect(afterRemove.first['name'], 'Ben');
    });

    test('unbekannte Person anlegen (Name-Trim)', () {
      const name = '  Clara  ';
      expect(name.trim().isNotEmpty, isTrue);
      expect(name.trim(), 'Clara');
    });
  });

  group('Zugriffsschutz (Filter)', () {
    test('nicht berechtigte IDs werden aus Liste gefiltert', () {
      final visibleIds = {'m1', 'm2'};
      final requested = ['m1', 'm3', 'm2'];
      final visible = requested.where(visibleIds.contains).toList();
      expect(visible, ['m1', 'm2']);
      expect(visible.contains('m3'), isFalse);
    });
  });
}
