import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';

/// Monats-Gruppe für die chronologische Galerie.
class MemoryMonthGroup {
  const MemoryMonthGroup({
    required this.year,
    required this.month,
    required this.items,
  });

  final int year;
  final int month;
  final List<MediaItemModel> items;

  String get title => '${MemoryMonthNames.name(month)} $year';

  String? get placeSubtitle => MemoryMonthGroup._dominantPlace(items);

  static String? _dominantPlace(List<MediaItemModel> items) {
    final counts = <String, int>{};
    for (final item in items) {
      final city = item.city?.trim();
      final country = item.countryName?.trim();
      if (city != null &&
          city.isNotEmpty &&
          country != null &&
          country.isNotEmpty) {
        final label = '$city, $country';
        counts[label] = (counts[label] ?? 0) + 1;
      } else if (city != null && city.isNotEmpty) {
        counts[city] = (counts[city] ?? 0) + 1;
      } else if (country != null && country.isNotEmpty) {
        counts[country] = (counts[country] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

abstract final class MemoryMonthNames {
  static const _months = [
    'Januar',
    'Februar',
    'März',
    'April',
    'Mai',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'Dezember',
  ];

  static String name(int month) => _months[month - 1];
}

abstract final class MemoryGalleryGrouping {
  static List<MemoryMonthGroup> byMonth(List<MediaItemModel> items) {
    final sorted = List<MediaItemModel>.from(items)
      ..sort((a, b) {
        final da = a.takenAt ?? a.createdAt ?? DateTime(1970);
        final db = b.takenAt ?? b.createdAt ?? DateTime(1970);
        return db.compareTo(da);
      });

    final map = <String, List<MediaItemModel>>{};
    for (final item in sorted) {
      final date = item.takenAt ?? item.createdAt;
      if (date == null) continue;
      final key = '${date.year}-${date.month}';
      map.putIfAbsent(key, () => []).add(item);
    }

    return map.entries.map((entry) {
      final parts = entry.key.split('-');
      return MemoryMonthGroup(
        year: int.parse(parts[0]),
        month: int.parse(parts[1]),
        items: entry.value,
      );
    }).toList()..sort((a, b) {
      if (a.year != b.year) return b.year.compareTo(a.year);
      return b.month.compareTo(a.month);
    });
  }
}

/// Abschnittsüberschrift für eine Monatsgruppe.
class MemorySectionHeader extends StatelessWidget {
  const MemorySectionHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  factory MemorySectionHeader.fromGroup(MemoryMonthGroup group) {
    return MemorySectionHeader(
      title: group.title,
      subtitle: group.placeSubtitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
