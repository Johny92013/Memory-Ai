import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/core/services/signed_url_service.dart';
import 'package:memory_ai/features/map/data/map_aggregation_helper.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/memories/data/people_repository.dart';

/// Kompakte schwebende Ortsvorschau (~10–15 % Höhe), Karte bleibt bedienbar.
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
      barrierColor: Colors.black.withValues(alpha: 0.15),
      builder: (ctx) {
        final maxH = MediaQuery.sizeOf(ctx).height * 0.15;
        final minH = MediaQuery.sizeOf(ctx).height * 0.1;
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH, minHeight: minH),
              child: Material(
                color: Colors.transparent,
                child: LocationPreviewSheet(group: group, personNames: names),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openGallery(BuildContext context) {
    Navigator.pop(context);
    context.push(
      '/map/location-gallery'
      '?coordinateKey=${Uri.encodeComponent(group.key)}'
      '&label=${Uri.encodeComponent(group.displayLabel)}'
      '${group.countryName != null ? '&country=${Uri.encodeComponent(group.countryName!)}' : ''}'
      '${group.city != null ? '&city=${Uri.encodeComponent(group.city!)}' : ''}',
    );
  }

  String _dateLabel() {
    final dates =
        group.items
            .map((i) => i.takenAt ?? i.createdAt)
            .whereType<DateTime>()
            .toList()
          ..sort();
    if (dates.isEmpty) return '—';
    if (dates.length == 1) {
      return DateFormat('MMM yyyy', 'de').format(dates.first);
    }
    final first = dates.first;
    final last = dates.last;
    if (first.year == last.year && first.month == last.month) {
      return DateFormat('MMM yyyy', 'de').format(first);
    }
    if (first.year == last.year) {
      return '${DateFormat('MMM', 'de').format(first)} – '
          '${DateFormat('MMM yyyy', 'de').format(last)}';
    }
    return '${DateFormat('MMM yyyy', 'de').format(first)} – '
        '${DateFormat('MMM yyyy', 'de').format(last)}';
  }

  @override
  Widget build(BuildContext context) {
    final preview = group.items.take(5).toList();
    final cover = group.items.first;
    final memoryCount = group.items.length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: AppColors.backgroundDark.withValues(alpha: 0.88),
        child: InkWell(
          onTap: () => _openGallery(context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.divider.withValues(alpha: 0.65),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CoverThumb(item: cover),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.displayLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (group.countryName != null)
                            Text(
                              group.countryName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          Text(
                            '${_dateLabel()} · $memoryCount '
                            '${memoryCount == 1 ? 'Erinnerung' : 'Erinnerungen'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                          if (personNames.isNotEmpty)
                            Text(
                              personNames.take(3).join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppColors.turquoise),
                            ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        for (var i = 0; i < preview.length; i++) ...[
                          if (i > 0) const SizedBox(width: 4),
                          Expanded(child: _MiniThumb(item: preview[i])),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Alle Erinnerungen anzeigen',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.turquoise,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.turquoise,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverThumb extends StatelessWidget {
  const _CoverThumb({required this.item});

  final MediaItemModel item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 52,
        height: 52,
        child: FutureBuilder<String?>(
          future: SignedUrlService.mediaGridUrl(item),
          builder: (context, snapshot) {
            final url = snapshot.data;
            if (url == null) {
              return Container(
                color: AppColors.cardElevated,
                child: const Icon(
                  Icons.place_outlined,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              );
            }
            return CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: AppColors.cardElevated),
              errorWidget: (_, _, _) => Container(
                color: AppColors.cardElevated,
                child: const Icon(Icons.broken_image_outlined, size: 20),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MiniThumb extends StatelessWidget {
  const _MiniThumb({required this.item});

  final MediaItemModel item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: FutureBuilder<String?>(
        future: SignedUrlService.mediaGridUrl(item),
        builder: (context, snapshot) {
          final url = snapshot.data;
          if (url == null) {
            return Container(
              color: AppColors.cardElevated,
              child: const Icon(Icons.image_outlined, size: 14),
            );
          }
          return CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(color: AppColors.cardElevated),
            errorWidget: (_, _, _) => Container(color: AppColors.cardElevated),
          );
        },
      ),
    );
  }
}
