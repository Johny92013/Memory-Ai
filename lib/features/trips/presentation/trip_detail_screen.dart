import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_radius.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/app/theme_extensions.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/signed_url_service.dart';
import 'package:memory_ai/features/memories/data/media_repository.dart';
import 'package:memory_ai/features/trips/data/trip_member_model.dart';
import 'package:memory_ai/features/trips/data/trip_model.dart';
import 'package:memory_ai/features/trips/data/trip_repository.dart';
import 'package:memory_ai/features/trips/data/trip_role_permissions.dart';
import 'package:memory_ai/features/trips/widgets/add_traveler_button.dart';
import 'package:memory_ai/features/trips/widgets/trip_hero_header.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
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
  final _mediaRepo = MediaRepository();
  TripModel? _trip;
  List<TripMemberModel> _members = [];
  String? _coverImageUrl;
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
      if (trip == null) {
        setState(() {
          _loading = false;
          _error = 'Reise nicht gefunden.';
        });
        return;
      }

      final members = await _repo.listTripMembers(widget.tripId);
      final coverUrl = await _resolveCoverUrl(trip);

      if (!mounted) return;
      setState(() {
        _trip = trip;
        _members = members;
        _coverImageUrl = coverUrl;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ErrorMapper.map(e).message;
      });
    }
  }

  Future<String?> _resolveCoverUrl(TripModel trip) async {
    final coverId = trip.coverMediaId;
    if (coverId == null || coverId.isEmpty) return null;
    final item = await _mediaRepo.getAccessibleMediaItem(coverId);
    if (item == null) return null;
    return SignedUrlService.mediaGridUrl(item);
  }

  void _openMembers() => context.push('/trips/${widget.tripId}/members');

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppScaffold(
        showAppBar: false,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return AppScaffold(
        title: 'Reise',
        body: ErrorState(message: _error!, onRetry: _load),
      );
    }

    final trip = _trip;
    if (trip == null) {
      return const AppScaffold(showAppBar: false, body: SizedBox.shrink());
    }

    final role = trip.myRole;
    final canEdit = TripRolePermissions.canEditTrip(role);
    final canUpload = TripRolePermissions.canUploadMedia(role);
    final canManageMembers = TripRolePermissions.canManageMembers(role);

    return AppScaffold(
      showAppBar: false,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.turquoise,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: TripHeroHeader(
                trip: trip,
                members: _members,
                coverImageUrl: _coverImageUrl,
                onBack: () => context.pop(),
                onEdit: canEdit
                    ? () => context.push('/trips/${widget.tripId}/edit')
                    : null,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (canManageMembers)
                    AddTravelerButton(onTap: _openMembers)
                  else
                    _MembersPreviewCard(
                      onTap: _openMembers,
                      memberCount: _members
                          .where((m) => m.invitationStatus == 'accepted')
                          .length,
                    ),
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
                        accent: AppColors.turquoise,
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
                      if (canManageMembers)
                        _NavChip(
                          icon: Icons.group_outlined,
                          label: 'Mitglieder',
                          accent: AppColors.textSecondary,
                          onTap: _openMembers,
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
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembersPreviewCard extends StatelessWidget {
  const _MembersPreviewCard({required this.onTap, required this.memberCount});

  final VoidCallback onTap;
  final int memberCount;

  @override
  Widget build(BuildContext context) {
    final label = memberCount == 0
        ? 'Mitreisende anzeigen'
        : memberCount == 1
        ? '1 Mitreisender'
        : '$memberCount Mitreisende';

    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(
                Icons.groups_outlined,
                color: AppColors.turquoise.withValues(alpha: 0.9),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(label)),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
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
