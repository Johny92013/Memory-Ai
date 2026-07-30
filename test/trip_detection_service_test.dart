import 'package:flutter_test/flutter_test.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/trips/data/trip_detection_service.dart';

MediaItemModel _photo({
  required String id,
  required DateTime takenAt,
  required String country,
  double? lat,
  double? lon,
}) {
  return MediaItemModel(
    id: id,
    ownerId: 'user',
    mediaType: 'image',
    takenAt: takenAt,
    countryName: country,
    latitude: lat,
    longitude: lon,
  );
}

void main() {
  group('TripDetectionService', () {
    final service = TripDetectionService(maxGapDays: 14);

    test(
      'schlägt getrennte Reisen bei großer Zeitlücke im selben Land vor',
      () {
        final media = [
          _photo(
            id: '1',
            takenAt: DateTime(2026, 1, 5),
            country: 'Italien',
            lat: 41.9,
            lon: 12.5,
          ),
          _photo(
            id: '2',
            takenAt: DateTime(2026, 1, 7),
            country: 'Italien',
            lat: 41.91,
            lon: 12.51,
          ),
          _photo(
            id: '3',
            takenAt: DateTime(2026, 8, 10),
            country: 'Italien',
            lat: 45.4,
            lon: 9.2,
          ),
          _photo(
            id: '4',
            takenAt: DateTime(2026, 8, 12),
            country: 'Italien',
            lat: 45.41,
            lon: 9.21,
          ),
        ];

        final suggestions = service.detectSuggestions(media: media);
        expect(suggestions.length, 2);
        expect(suggestions[0].countryName, 'Italien');
        expect(suggestions[1].countryName, 'Italien');
        expect(suggestions[0].photoCount, 2);
        expect(suggestions[1].photoCount, 2);
      },
    );

    test('ignoriert Medien die bereits einer Reise zugeordnet sind', () {
      final media = [
        MediaItemModel(
          id: '1',
          ownerId: 'user',
          mediaType: 'image',
          takenAt: DateTime(2026, 3, 1),
          countryName: 'Spanien',
          tripId: 'existing-trip',
        ),
        _photo(id: '2', takenAt: DateTime(2026, 3, 2), country: 'Spanien'),
      ];

      final suggestions = service.detectSuggestions(media: media);
      expect(suggestions.length, 1);
      expect(suggestions.first.mediaItems.single.id, '2');
    });
  });
}
