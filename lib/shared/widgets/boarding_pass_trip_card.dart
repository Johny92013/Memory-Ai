import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_radius.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/app/app_typography.dart';
import 'package:memory_ai/app/theme_extensions.dart';
import 'package:memory_ai/features/trips/data/trip_model.dart';
import 'package:memory_ai/shared/widgets/perforated_divider.dart';

/// Reise-Karte im Boarding-Pass-Stil.
class BoardingPassTripCard extends StatelessWidget {
  const BoardingPassTripCard({
    super.key,
    required this.trip,
    this.onTap,
    this.compact = false,
    this.enableNavigation = true,
  });

  final TripModel trip;
  final VoidCallback? onTap;
  final bool compact;
  final bool enableNavigation;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yy');
    final start = trip.startDate != null
        ? dateFormat.format(trip.startDate!)
        : '—';
    final end = trip.endDate != null ? dateFormat.format(trip.endDate!) : '—';
    final countries = trip.countries.isEmpty
        ? '—'
        : trip.countries.take(3).map((c) => _countryCode(c)).join(' · ');

    final coverHeight = compact ? 100.0 : 140.0;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enableNavigation
            ? (onTap ?? () => context.push('/trips/${trip.id}'))
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: coverHeight,
              decoration: const BoxDecoration(
                gradient: AppColors.ticketCoverGradient,
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(
                      Icons.flight_takeoff,
                      size: 96,
                      color: AppColors.accentWarm.withValues(alpha: 0.12),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Text(
                          'MEMORYAI TRAVEL',
                          style: AppTypography.statsMono(
                            color: AppColors.accentCool.withValues(alpha: 0.9),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const PerforatedDivider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TicketField(
                      label: 'VON',
                      value: start,
                      mono: context.appTheme.statsMono,
                    ),
                  ),
                  Expanded(
                    child: _TicketField(
                      label: 'BIS',
                      value: end,
                      mono: context.appTheme.statsMono,
                    ),
                  ),
                  Expanded(
                    child: _TicketField(
                      label: 'DEST',
                      value: countries,
                      mono: context.appTheme.statsMono,
                    ),
                  ),
                  _TicketField(
                    label: 'FOTOS',
                    value: '${trip.photoCount}',
                    mono: context.appTheme.statsMono,
                    alignEnd: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _countryCode(String name) {
    if (name.length <= 3) return name.toUpperCase();
    return name.substring(0, 3).toUpperCase();
  }
}

class _TicketField extends StatelessWidget {
  const _TicketField({
    required this.label,
    required this.value,
    required this.mono,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final TextStyle mono;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: mono, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
