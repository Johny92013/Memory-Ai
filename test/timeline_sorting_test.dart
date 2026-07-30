import 'package:flutter_test/flutter_test.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/timeline/data/timeline_sorting.dart';

void main() {
  group('TimelineSorting', () {
    test('gruppiert chronologisch nach Jahr Monat Tag', () {
      final items = [
        MediaItemModel(
          id: 'a',
          ownerId: 'u',
          mediaType: 'image',
          takenAt: DateTime(2024, 3, 15),
        ),
        MediaItemModel(
          id: 'b',
          ownerId: 'u',
          mediaType: 'image',
          takenAt: DateTime(2026, 7, 10),
        ),
        MediaItemModel(
          id: 'c',
          ownerId: 'u',
          mediaType: 'image',
          takenAt: DateTime(2026, 7, 12),
        ),
      ];

      final years = TimelineSorting.groupChronologically(items);
      expect(years.first.year, 2026);
      expect(years.last.year, 2024);
      expect(years.first.months.first.days.length, 2);
      expect(years.first.months.first.days.first.items.length, 1);
    });

    test('sortiert Tage innerhalb eines Monats absteigend', () {
      final items = [
        MediaItemModel(
          id: '1',
          ownerId: 'u',
          mediaType: 'image',
          takenAt: DateTime(2025, 5, 1),
        ),
        MediaItemModel(
          id: '2',
          ownerId: 'u',
          mediaType: 'image',
          takenAt: DateTime(2025, 5, 20),
        ),
      ];

      final years = TimelineSorting.groupChronologically(items);
      final days = years.first.months.first.days;
      expect(days.first.date.day, 20);
      expect(days.last.date.day, 1);
    });
  });
}
