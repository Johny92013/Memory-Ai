import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/home_dashboard_colors.dart';
import 'package:memory_ai/features/home/data/home_dashboard_data.dart';
import 'package:memory_ai/features/home/data/home_greeting.dart';
import 'package:memory_ai/features/home/data/home_repository.dart';
import 'package:memory_ai/features/home/widgets/home_feature_grid.dart';
import 'package:memory_ai/features/home/widgets/home_header.dart';
import 'package:memory_ai/features/home/widgets/recent_memories_section.dart';

/// Startseite als mobiles Dashboard.
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
        ? 680.0
        : double.infinity;

    return ColoredBox(
      color: HomeDashboardColors.pageBackground,
      child: RefreshIndicator(
        color: HomeDashboardColors.coral,
        onRefresh: _reload,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: HomeHeader(
                greeting: _loading && data == null ? 'Hallo! 👋' : _greeting,
                profile: data?.profile,
                onProfileTap: () => context.push('/profile'),
              ),
            ),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -36),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_loading && data == null)
                            const _FeatureGridSkeleton()
                          else
                            HomeFeatureGrid(
                              memoriesSubtitle: data?.memoriesSubtitle ?? '…',
                              familySubtitle: data?.familySubtitle ?? '…',
                              mapSubtitle: data?.mapSubtitle ?? '…',
                              chatSubtitle: data?.chatSubtitle ?? '…',
                              onMemories: () => context.push('/media/gallery'),
                              onFamily: () => context.push('/family'),
                              onMap: () => context.push('/map'),
                              onChat: () => context.push('/chat'),
                            ),
                          const SizedBox(height: 22),
                          if (_loading && data == null)
                            const _RecentSkeleton()
                          else
                            RecentMemoriesSection(
                              items: data?.recentMemories ?? const [],
                              failed: data?.memoriesFailed ?? false,
                              onRetry: _reload,
                              onShowAll: () => context.push('/media/gallery'),
                              onAddMemory: () =>
                                  context.push('/memories/upload'),
                              onItemTap: (item) =>
                                  context.push('/media/${item.id}'),
                            ),
                          const SizedBox(height: 88),
                        ],
                      ),
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

class _FeatureGridSkeleton extends StatelessWidget {
  const _FeatureGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.55,
      children: List.generate(
        4,
        (_) => Container(
          decoration: BoxDecoration(
            color: HomeDashboardColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _RecentSkeleton extends StatelessWidget {
  const _RecentSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 18,
          width: 160,
          decoration: BoxDecoration(
            color: HomeDashboardColors.white,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, _) => Container(
              width: 110,
              decoration: BoxDecoration(
                color: HomeDashboardColors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
