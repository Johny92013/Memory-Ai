import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_radius.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/app/theme_extensions.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/trips/data/trip_model.dart';
import 'package:memory_ai/features/trips/data/trip_repository.dart';
import 'package:memory_ai/features/trips/data/trip_role_permissions.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/boarding_pass_trip_card.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';

/// Detailansicht einer Reise.
class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final _repo = TripRepository();
  TripModel? _trip;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final trip = await _repo.getTrip(widget.tripId);
      if (!mounted) return;
      setState(() {
        _trip = trip;
        _loading = false;
        if (trip == null) _error = 'Reise nicht gefunden.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ErrorMapper.map(e).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    final role = trip?.myRole;
    final canEdit = TripRolePermissions.canEditTrip(role);
    final canUpload = TripRolePermissions.canUploadMedia(role);

    return AppScaffold(
      title: trip?.title ?? 'Reise',
      actions: canEdit
          ? [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/trips/${widget.tripId}/edit'),
              ),
            ]
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorState(message: _error!, onRetry: _load)
          : trip == null
          ? const SizedBox.shrink()
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.accentWarm,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  BoardingPassTripCard(trip: trip, enableNavigation: false),
                  if (trip.description != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      trip.description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _NavChip(
                        icon: Icons.map_outlined,
                        label: 'Karte',
                        accent: AppColors.accentCool,
                        onTap: () => context.push('/trips/${trip.id}/map'),
                      ),
                      _NavChip(
                        icon: Icons.timeline,
                        label: 'Timeline',
                        accent: AppColors.textSecondary,
                        onTap: () => context.push('/trips/${trip.id}/timeline'),
                      ),
                      _NavChip(
                        icon: Icons.photo_library_outlined,
                        label: 'Galerie',
                        accent: AppColors.textSecondary,
                        onTap: () => context.push('/trips/${trip.id}/memories'),
                      ),
                      if (TripRolePermissions.canManageMembers(role))
                        _NavChip(
                          icon: Icons.group_outlined,
                          label: 'Mitglieder',
                          accent: AppColors.textSecondary,
                          onTap: () =>
                              context.push('/trips/${trip.id}/members'),
                        ),
                    ],
                  ),
                  if (canUpload) ...[
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: 'Fotos hochladen',
                      onPressed: () =>
                          context.push('/memories/upload?tripId=${trip.id}'),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${trip.locationCount} Orte · ${trip.countries.join(', ')}',
                    style: context.appTheme.statsMono.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _NavChip extends StatelessWidget {
  const _NavChip({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: accent),
      label: Text(label),
      backgroundColor: AppColors.surface,
      side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      onPressed: onTap,
    );
  }
}
