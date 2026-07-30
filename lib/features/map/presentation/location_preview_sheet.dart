import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_radius.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/features/map/data/map_aggregation_helper.dart';
import 'package:memory_ai/features/memories/data/people_repository.dart';
import 'package:memory_ai/features/memories/widgets/media_thumbnail_grid.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';

/// Kleine Ortsvorschau (~10–20% Höhe), Karte bleibt bedienbar.
class LocationPreviewSheet extends StatelessWidget {
  const LocationPreviewSheet({
    super.key,
    required this.group,
    this.personNames = const [],
  });

  final MapLocationGroup group;
  final List<String> personNames;

  static Future<void> show(
    BuildContext context, {
    required MapLocationGroup group,
  }) async {
    List<String> names = [];
    try {
      final people = await PeopleRepository().listPeopleForMedia(
        group.items.first.id,
      );
      names = people.map((p) => p.name).toList();
      // Sammle aus ersten Medien
      final seen = <String>{...names};
      for (final item in group.items.take(8)) {
        final more = await PeopleRepository().listPeopleForMedia(item.id);
        for (final p in more) {
          if (seen.add(p.name)) names.add(p.name);
        }
      }
    } catch (_) {}

    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        final maxH = MediaQuery.sizeOf(ctx).height * 0.2;
        final minH = MediaQuery.sizeOf(ctx).height * 0.1;
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH, minHeight: minH),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.sheet),
              ),
              child: LocationPreviewSheet(group: group, personNames: names),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = group.items.where((i) => i.mediaType == 'image').length;
    final videos = group.items.where((i) => i.mediaType == 'video').length;
    final dates =
        group.items
            .map((i) => i.takenAt ?? i.createdAt)
            .whereType<DateTime>()
            .toList()
          ..sort();
    final range = dates.isEmpty
        ? '—'
        : dates.length == 1
        ? DateFormat('dd.MM.yyyy').format(dates.first)
        : '${DateFormat('dd.MM.yyyy').format(dates.first)} – '
              '${DateFormat('dd.MM.yyyy').format(dates.last)}';
    final preview = group.items.take(5).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            group.displayLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            [
              if (group.countryName != null) group.countryName!,
              range,
              if (photos > 0) '$photos Fotos',
              if (videos > 0) '$videos Videos',
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          if (personNames.isNotEmpty)
            Text(
              personNames.take(4).join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          const SizedBox(height: 6),
          SizedBox(
            height: 48,
            child: MediaThumbnailGrid(items: preview, crossAxisCount: 5),
          ),
          const SizedBox(height: 6),
          AppButton(
            label: 'Galerie öffnen',
            onPressed: () {
              Navigator.pop(context);
              context.push(
                '/map/location-gallery'
                '?coordinateKey=${Uri.encodeComponent(group.key)}'
                '&label=${Uri.encodeComponent(group.displayLabel)}'
                '${group.countryName != null ? '&country=${Uri.encodeComponent(group.countryName!)}' : ''}'
                '${group.city != null ? '&city=${Uri.encodeComponent(group.city!)}' : ''}',
              );
            },
          ),
        ],
      ),
    );
  }
}
