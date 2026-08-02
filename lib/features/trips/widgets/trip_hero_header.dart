import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/features/trips/data/trip_member_model.dart';
import 'package:memory_ai/features/trips/data/trip_model.dart';
import 'package:memory_ai/features/trips/widgets/traveler_avatar_stack.dart';

/// Hero-Bereich für die Reisedetailseite mit Cover, Titel und Mitreisenden.
class TripHeroHeader extends StatelessWidget {
  const TripHeroHeader({
    super.key,
    required this.trip,
    required this.members,
    this.coverImageUrl,
    required this.onBack,
    this.onEdit,
    this.heightFactor = 0.34,
  });

  final TripModel trip;
  final List<TripMemberModel> members;
  final String? coverImageUrl;
  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final double heightFactor;

  String get _dateRange {
    final fmt = DateFormat('d. MMM yyyy', 'de');
    final start = trip.startDate;
    final end = trip.endDate;
    if (start != null && end != null) {
      return '${fmt.format(start)} – ${fmt.format(end)}';
    }
    if (start != null) return fmt.format(start);
    if (end != null) return fmt.format(end);
    return 'Datum offen';
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * heightFactor;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _CoverBackground(coverImageUrl: coverImageUrl),
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.coverFadeGradient),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.45),
                  Colors.transparent,
                  AppColors.backgroundDark.withValues(alpha: 0.92),
                ],
                stops: const [0.0, 0.35, 1.0],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, color: AppColors.white),
                    tooltip: 'Zurück',
                  ),
                  const Spacer(),
                  if (onEdit != null)
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.white,
                      ),
                      tooltip: 'Bearbeiten',
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trip.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _dateRange,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (members.any((m) => m.invitationStatus == 'accepted')) ...[
                  const SizedBox(height: AppSpacing.md),
                  TravelerAvatarStack(members: members),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverBackground extends StatelessWidget {
  const _CoverBackground({this.coverImageUrl});

  final String? coverImageUrl;

  @override
  Widget build(BuildContext context) {
    if (coverImageUrl != null && coverImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: coverImageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, _) => const _FallbackCover(),
        errorWidget: (_, _, _) => const _FallbackCover(),
      );
    }
    return const _FallbackCover();
  }
}

class _FallbackCover extends StatelessWidget {
  const _FallbackCover();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.ticketCoverGradient),
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Icon(
            Icons.flight_takeoff,
            size: 120,
            color: AppColors.turquoise.withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }
}
