import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/constants/app_constants.dart';
import 'package:memory_ai/features/home/data/home_dashboard_data.dart';
import 'package:memory_ai/features/home/data/home_greeting.dart';
import 'package:memory_ai/features/home/data/home_repository.dart';
import 'package:memory_ai/features/home/widgets/recent_memories_section.dart';
import 'package:memory_ai/features/home/widgets/tagged_media_notification_card.dart';
import 'package:memory_ai/features/home/widgets/user_greeting.dart';
import 'package:memory_ai/shared/widgets/app_travel_logo.dart';
import 'package:memory_ai/shared/widgets/travel_ui.dart';

/// Startseite – Premium Travel Dashboard.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.familyId});

  final String? familyId;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _homeRepo = HomeRepository();
  HomeDashboardData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final data = await _homeRepo.loadDashboard();
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  String get _greeting {
    return HomeGreeting.greetingLine(
      profile: _data?.profile,
      userMetadata: HomeGreeting.currentUserMetadata(),
      email: HomeGreeting.currentUserEmail(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final maxWidth = MediaQuery.sizeOf(context).width > 720
        ? 800.0
        : double.infinity;

    return ColoredBox(
      color: AppColors.backgroundDark,
      child: RefreshIndicator(
        color: AppColors.turquoise,
        onRefresh: _reload,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      const AppTravelLogo(size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _loading && data == null ? 'Hallo!' : _greeting,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              AppConstants.appTagline,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      UserGreeting(
                        greeting: '',
                        subtitle: '',
                        profile: data?.profile,
                        onProfileTap: () => context.push('/profile'),
                        compactAvatarOnly: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        _StatsRow(data: data, loading: _loading),
                        const SizedBox(height: 16),
                        const TaggedMediaNotificationCard(),
                        SectionHeader(
                          title: 'Entdecken',
                          actionLabel: 'Alle',
                          onAction: () => context.go('/home?tab=2'),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _QuickCard(
                                icon: Icons.map_rounded,
                                title: 'Weltkarte',
                                subtitle: data?.mapSubtitle ?? '…',
                                onTap: () => context.go('/home?tab=2'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickCard(
                                icon: Icons.flight_takeoff_rounded,
                                title: 'Reisen',
                                subtitle: 'Übersicht',
                                onTap: () => context.push('/trips'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _QuickCard(
                                icon: Icons.photo_library_rounded,
                                title: 'Erinnerungen',
                                subtitle: data?.memoriesSubtitle ?? '…',
                                onTap: () => context.push('/media/gallery'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickCard(
                                icon: Icons.person_pin_outlined,
                                title: 'Mit mir',
                                subtitle: 'Markierungen',
                                onTap: () =>
                                    context.push('/profile/tagged-media'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        SectionHeader(
                          title: 'Neueste Erinnerungen',
                          actionLabel: 'Alle',
                          onAction: () => context.push('/media/gallery'),
                        ),
                        const SizedBox(height: 8),
                        if (_loading && data == null)
                          const LoadingTravelSkeleton(height: 140)
                        else
                          RecentMemoriesSection(
                            items: data?.recentMemories ?? const [],
                            failed: data?.memoriesFailed ?? false,
                            onRetry: _reload,
                            onShowAll: () => context.push('/media/gallery'),
                            onAddMemory: () => context.push('/memories/upload'),
                            onItemTap: (item) =>
                                context.push('/media/${item.id}'),
                          ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.data, required this.loading});

  final HomeDashboardData? data;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final locations = data?.visitedLocationCount ?? 0;
    final memories = (data?.photoCount ?? 0) + (data?.videoCount ?? 0);
    return Row(
      children: [
        _StatChip(label: 'Orte', value: loading ? '–' : '$locations'),
        _StatChip(label: 'Erinnerungen', value: loading ? '–' : '$memories'),
        _StatChip(
          label: 'Fotos',
          value: loading ? '–' : '${data?.photoCount ?? 0}',
        ),
        _StatChip(
          label: 'Videos',
          value: loading ? '–' : '${data?.videoCount ?? 0}',
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TravelCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.turquoise),
            ),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TravelCard(
      onTap: onTap,
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientIconContainer(icon: icon, size: 40, iconSize: 20),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
