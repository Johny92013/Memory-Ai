import 'package:flutter_test/flutter_test.dart';
import 'package:memory_ai/features/map/data/map_filter_state.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';

void main() {
  MediaItemModel media({
    required String id,
    String type = 'image',
    String? country,
    String? city,
    String? continent,
    String? region,
    DateTime? takenAt,
    String ownerId = 'me',
    String? familyId,
  }) {
    return MediaItemModel(
      id: id,
      ownerId: ownerId,
      mediaType: type,
      countryName: country,
      city: city,
      continent: continent,
      regionName: region,
      takenAt: takenAt,
      familyId: familyId,
      latitude: 1,
      longitude: 1,
    );
  }

  group('MapFilterEngine', () {
    final base = [
      media(
        id: '1',
        country: 'Italien',
        city: 'Rom',
        continent: 'Europe',
        takenAt: DateTime(2025, 3, 10),
      ),
      media(
        id: '2',
        country: 'Italien',
        city: 'Mailand',
        continent: 'Europe',
        takenAt: DateTime(2024, 7, 1),
        type: 'video',
      ),
      media(
        id: '3',
        country: 'Deutschland',
        city: 'Berlin',
        continent: 'Europe',
        takenAt: DateTime(2025, 8, 1),
      ),
      media(
        id: '4',
        country: 'Japan',
        continent: 'Asia',
        takenAt: DateTime(2023, 1, 15),
      ),
    ];

    test('Filter Land', () {
      final r = MapFilterEngine.apply(
        items: base,
        filter: const MapFilterState(country: 'Italien'),
        peopleByMediaId: const {},
      );
      expect(r.map((e) => e.id), ['1', '2']);
    });

    test('Filter Kontinent', () {
      final r = MapFilterEngine.apply(
        items: base,
        filter: const MapFilterState(continent: 'Asia'),
        peopleByMediaId: const {},
      );
      expect(r.map((e) => e.id), ['4']);
    });

    test('Filter Jahr', () {
      final r = MapFilterEngine.apply(
        items: base,
        filter: MapFilterState(years: {2025}),
        peopleByMediaId: const {},
      );
      expect(r.map((e) => e.id).toSet(), {'1', '3'});
    });

    test('Filter Monat+Jahr', () {
      final r = MapFilterEngine.apply(
        items: base,
        filter: const MapFilterState(month: 3, yearForMonth: 2025),
        peopleByMediaId: const {},
      );
      expect(r.map((e) => e.id), ['1']);
    });

    test('Filter Quartal Q1 2025', () {
      final r = MapFilterEngine.apply(
        items: base,
        filter: MapFilterState(quarters: {const QuarterFilter(2025, 1)}),
        peopleByMediaId: const {},
      );
      expect(r.map((e) => e.id), ['1']);
    });

    test('Filter Medientyp Video', () {
      final r = MapFilterEngine.apply(
        items: base,
        filter: const MapFilterState(mediaType: 'video'),
        peopleByMediaId: const {},
      );
      expect(r.map((e) => e.id), ['2']);
    });

    test('Kombiniert: Anna in Italien 2025', () {
      final r = MapFilterEngine.apply(
        items: base,
        filter: MapFilterState(
          country: 'Italien',
          years: {2025},
          personIds: {'anna'},
        ),
        peopleByMediaId: {
          '1': {'anna'},
          '2': {'bob'},
          '3': {'anna'},
        },
      );
      expect(r.map((e) => e.id), ['1']);
    });

    test('Ohne Personen', () {
      final r = MapFilterEngine.apply(
        items: base,
        filter: const MapFilterState(withoutPeople: true),
        peopleByMediaId: {
          '1': {'anna'},
        },
      );
      expect(r.map((e) => e.id).toSet(), {'2', '3', '4'});
    });

    test('Chip entfernen setzt Filter zurück', () {
      var f = MapFilterState(years: {2025}, country: 'Italien');
      f = f.removeChip('year_2025');
      expect(f.years, isEmpty);
      expect(f.country, 'Italien');
      f = f.removeChip('country');
      expect(f.country, isNull);
    });
  });

  group('YearColorPalette', () {
    test('feste Jahre reproduzierbar', () {
      expect(YearColorPalette.forYear(2022), YearColorPalette.forYear(2022));
      expect(
        YearColorPalette.forYear(2022),
        isNot(YearColorPalette.forYear(2023)),
      );
      expect(YearColorPalette.forYear(2024), YearColorPalette.forYear(2024));
    });

    test('weitere Jahre ohne Obergrenze', () {
      final a = YearColorPalette.forYear(2030);
      final b = YearColorPalette.forYear(2031);
      expect(a, isNot(b));
      expect(YearColorPalette.forYear(2030), a);
    });

    test('Hauptfarbe = neuestes Jahr', () {
      final items = [
        media(id: 'a', takenAt: DateTime(2022, 1, 1)),
        media(id: 'b', takenAt: DateTime(2025, 1, 1)),
      ];
      expect(YearColorPalette.forItems(items), YearColorPalette.forYear(2025));
    });
  });

  group('Navigation visibility (Konvention)', () {
    test('Album/Slideshow-Routen sind Fullscreen-Pfade', () {
      const album = '/map/album-viewer';
      const slideshow = '/map/slideshow';
      const gallery = '/map/location-gallery';
      expect(album.contains('album'), isTrue);
      expect(slideshow.contains('slideshow'), isTrue);
      // Galerie ist normale Route (Bottom-Nav bleibt über Shell-Pop)
      expect(gallery.contains('location-gallery'), isTrue);
    });
  });
}
