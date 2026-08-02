import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_radius.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/core/services/signed_url_service.dart';
import 'package:memory_ai/core/utils/initials_helper.dart';
import 'package:memory_ai/features/people/data/tagged_media_models.dart';

/// Kopfzeile „Markiert von …“ für Bestätigungskarten.
class TaggedByHeader extends StatelessWidget {
  const TaggedByHeader({super.key, required this.name, this.subtitle});

  final String name;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final initials = InitialsHelper.fromFullName(name);
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.brandGradient,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Markiert von $name',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Karte für offene oder abgeschlossene Gesichts-Markierungen.
class FaceConfirmationCard extends StatelessWidget {
  const FaceConfirmationCard({
    super.key,
    required this.item,
    required this.onTap,
    this.showQuickActions = false,
    this.onConfirm,
    this.onReject,
  });

  final TaggedMediaItem item;
  final VoidCallback onTap;
  final bool showQuickActions;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd.MM.yyyy');
    final taggedBy = item.taggedByName ?? 'Unbekannt';
    final dateLabel = item.takenAt != null
        ? dateFmt.format(item.takenAt!)
        : null;

    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TaggedByHeader(
                name: taggedBy,
                subtitle: item.ownerName != null
                    ? 'Aufnahme von ${item.ownerName}'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PreviewThumb(
                    thumbnailPath: item.thumbnailPath,
                    storagePath: item.storagePath,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dateLabel != null)
                          _MetaRow(
                            icon: Icons.calendar_today_outlined,
                            label: dateLabel,
                          ),
                        const SizedBox(height: AppSpacing.xs),
                        _MetaRow(
                          icon: Icons.place_outlined,
                          label: item.placeLabel,
                        ),
                        if (item.tripTitle != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          _MetaRow(
                            icon: Icons.flight_takeoff_outlined,
                            label: item.tripTitle!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (showQuickActions) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Ablehnen'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.divider),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onConfirm,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Bestätigen'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.turquoise,
                          foregroundColor: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.turquoise),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _PreviewThumb extends StatelessWidget {
  const _PreviewThumb({this.thumbnailPath, this.storagePath});

  final String? thumbnailPath;
  final String? storagePath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 88,
        height: 88,
        child: FutureBuilder<String?>(
          future: thumbnailPath != null && thumbnailPath!.isNotEmpty
              ? SignedUrlService.mediaThumbnailUrl(thumbnailPath)
              : SignedUrlService.mediaPhotoUrl(storagePath),
          builder: (context, snap) {
            final url = snap.data;
            if (url == null) {
              return ColoredBox(
                color: AppColors.cardElevated,
                child: Icon(
                  Icons.image_outlined,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              );
            }
            return CachedNetworkImage(imageUrl: url, fit: BoxFit.cover);
          },
        ),
      ),
    );
  }
}
