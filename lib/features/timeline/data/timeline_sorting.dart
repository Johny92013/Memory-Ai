import 'package:memory_ai/features/memories/data/media_item_model.dart';

/// Ein Tag in der globalen Timeline.
class TimelineDayGroup {
  const TimelineDayGroup({required this.date, required this.items});

  final DateTime date;
  final List<MediaItemModel> items;
}

/// Jahr-Monat-Gruppierung.
class TimelineMonthGroup {
  const TimelineMonthGroup({
    required this.year,
    required this.month,
    required this.days,
  });

  final int year;
  final int month;
  final List<TimelineDayGroup> days;
}

/// Jahr-Gruppierung.
class TimelineYearGroup {
  const TimelineYearGroup({required this.year, required this.months});

  final int year;
  final List<TimelineMonthGroup> months;
}

/// Chronologische Sortierung für die globale Timeline.
class TimelineSorting {
  TimelineSorting._();

  static List<TimelineYearGroup> groupChronologically(
    List<MediaItemModel> items,
  ) {
    final sorted = List<MediaItemModel>.from(items)
      ..sort((a, b) {
        final da = a.takenAt ?? a.createdAt ?? DateTime(1970);
        final db = b.takenAt ?? b.createdAt ?? DateTime(1970);
        return db.compareTo(da);
      });

    final dayMap = <String, List<MediaItemModel>>{};
    for (final item in sorted) {
      final date = item.takenAt ?? item.createdAt;
      if (date == null) continue;
      final key = _dayKey(date);
      dayMap.putIfAbsent(key, () => []).add(item);
    }

    final days = dayMap.entries.map((entry) {
      final parts = entry.key.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return TimelineDayGroup(date: date, items: entry.value);
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    final yearMap = <int, Map<int, List<TimelineDayGroup>>>{};
    for (final day in days) {
      yearMap.putIfAbsent(day.date.year, () => {});
      yearMap[day.date.year]!.putIfAbsent(day.date.month, () => []).add(day);
    }

    return yearMap.entries.map((yearEntry) {
      final months = yearEntry.value.entries.map((monthEntry) {
        final sortedDays = List<TimelineDayGroup>.from(monthEntry.value)
          ..sort((a, b) => b.date.compareTo(a.date));
        return TimelineMonthGroup(
          year: yearEntry.key,
          month: monthEntry.key,
          days: sortedDays,
        );
      }).toList()..sort((a, b) => b.month.compareTo(a.month));

      return TimelineYearGroup(year: yearEntry.key, months: months);
    }).toList()..sort((a, b) => b.year.compareTo(a.year));
  }

  static String _dayKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';
}
