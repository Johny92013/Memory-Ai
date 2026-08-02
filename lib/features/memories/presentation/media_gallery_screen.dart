import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/media_change_notifier.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/memories/data/media_repository.dart';
import 'package:memory_ai/features/memories/widgets/memory_grid_tile.dart';
import 'package:memory_ai/features/memories/widgets/memory_section_header.dart';
import 'package:memory_ai/features/memories/widgets/memory_tabs.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';
import 'package:memory_ai/shared/widgets/travel_ui.dart';

/// Chronologische Foto-Galerie mit Lazy Loading und Thumbnails.
class MediaGalleryScreen extends StatefulWidget {
  const MediaGalleryScreen({super.key});

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen> {
  final _repo = MediaRepository();
  final _items = <MediaItemModel>[];
  final _withoutGpsItems = <MediaItemModel>[];
  final _scrollController = ScrollController();

  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _showWithoutGps = false;
  String _ownershipFilter = 'all';
  MemoryGalleryTab _mediaTab = MemoryGalleryTab.all;
  String? _error;
  int _offset = 0;
  static const _pageSize = 30;

  static const _ownershipOptions = [
    ('all', 'Alle'),
    ('own', 'Eigene'),
    ('withMe', 'Mit mir'),
    ('shared', 'Geteilt'),
  ];

  @override
  void initState() {
    super.initState();
    MediaChangeNotifier.instance.addListener(_onMediaChanged);
    _loadInitial();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    MediaChangeNotifier.instance.removeListener(_onMediaChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onMediaChanged() {
    if (mounted) _loadInitial();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
      _offset = 0;
      _hasMore = true;
    });
    try {
      final rows = await _repo.listGalleryMedia(
        filter: _ownershipFilter,
        limit: _pageSize,
        offset: 0,
      );
      final withoutGps = await _repo.listMyMediaWithoutGps(limit: 20);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(rows);
        _withoutGpsItems
          ..clear()
          ..addAll(withoutGps);
        _offset = rows.length;
        _hasMore = rows.length >= _pageSize;
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

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final rows = await _repo.listGalleryMedia(
        filter: _ownershipFilter,
        limit: _pageSize,
        offset: _offset,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(rows);
        _offset += rows.length;
        _hasMore = rows.length >= _pageSize;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  List<MediaItemModel> _filteredItems() {
    return switch (_mediaTab) {
      MemoryGalleryTab.all => _items,
      MemoryGalleryTab.photos =>
        _items.where((i) => i.mediaType == 'image').toList(),
      MemoryGalleryTab.videos =>
        _items.where((i) => i.mediaType == 'video').toList(),
      MemoryGalleryTab.trips =>
        _items.where((i) => i.tripId != null && i.tripId!.isNotEmpty).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems();
    final sections = MemoryGalleryGrouping.byMonth(filtered);
    final showMainGallery = !_showWithoutGps || _items.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.turquoise),
              )
            : _error != null
            ? ErrorState(message: _error!, onRetry: _loadInitial)
            : _items.isEmpty && !_showWithoutGps
            ? _buildEmptyState(context)
            : RefreshIndicator(
                onRefresh: _loadInitial,
                color: AppColors.turquoise,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(context)),
                    if (_showWithoutGps && _withoutGpsItems.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Text(
                            'Ohne Standort – Ort manuell zuweisen',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
                                childAspectRatio: 1,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final item = _withoutGpsItems[index];
                            return MemoryGridTile(
                              item: item,
                              showNoGpsBadge: true,
                              onTap: () async {
                                final updated = await context.push<bool>(
                                  '/media/assign-location',
                                  extra: item,
                                );
                                if (updated == true) _loadInitial();
                              },
                            );
                          }, childCount: _withoutGpsItems.length),
                        ),
                      ),
                    ],
                    if (_mediaTab == MemoryGalleryTab.trips)
                      SliverToBoxAdapter(child: _buildTripsLink(context)),
                    if (showMainGallery && filtered.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildTabEmptyState(context),
                      )
                    else if (showMainGallery)
                      ..._buildSectionSlivers(sections),
                    if (_loadingMore && !_showWithoutGps)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.turquoise,
                            ),
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Erinnerungen',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
              ),
              IconButton(
                icon: Icon(
                  _showWithoutGps
                      ? Icons.location_off
                      : Icons.location_off_outlined,
                  color: _showWithoutGps ? AppColors.turquoise : null,
                ),
                tooltip: 'Ohne Standort',
                onPressed: () =>
                    setState(() => _showWithoutGps = !_showWithoutGps),
              ),
              IconButton(
                icon: const Icon(Icons.add_a_photo_outlined),
                onPressed: () => context.push('/memories/upload'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        MemoryTabs(
          selected: _mediaTab,
          onSelected: (tab) => setState(() => _mediaTab = tab),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              for (final entry in _ownershipOptions)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _OwnershipChip(
                    label: entry.$2,
                    selected: _ownershipFilter == entry.$1,
                    onSelected: () {
                      setState(() => _ownershipFilter = entry.$1);
                      _loadInitial();
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTripsLink(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TravelCard(
        onTap: () => context.push('/trips'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.turquoise.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.flight_takeoff_rounded,
                color: AppColors.turquoise,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alle Reisen',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Reisen planen und Erinnerungen zuordnen',
                    style: Theme.of(context).textTheme.bodySmall,
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
      ),
    );
  }

  List<Widget> _buildSectionSlivers(List<MemoryMonthGroup> sections) {
    final slivers = <Widget>[];
    for (final section in sections) {
      slivers.add(
        SliverToBoxAdapter(child: MemorySectionHeader.fromGroup(section)),
      );
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = section.items[index];
              return MemoryGridTile(
                item: item,
                onTap: () => context.push('/media/${item.id}'),
              );
            }, childCount: section.items.length),
          ),
        ),
      );
    }
    return slivers;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: EmptyTravelState(
            icon: Icons.photo_library_outlined,
            title: 'Noch keine Erinnerungen',
            message: 'Deine Fotos, Videos und Reisen erscheinen hier.',
            buttonLabel: 'Erinnerung hinzufügen',
            onPressed: () => context.push('/memories/upload'),
          ),
        ),
      ],
    );
  }

  Widget _buildTabEmptyState(BuildContext context) {
    final (title, message) = switch (_mediaTab) {
      MemoryGalleryTab.photos => (
        'Keine Fotos',
        'In dieser Auswahl sind noch keine Fotos vorhanden.',
      ),
      MemoryGalleryTab.videos => (
        'Keine Videos',
        'In dieser Auswahl sind noch keine Videos vorhanden.',
      ),
      MemoryGalleryTab.trips => (
        'Keine Reise-Erinnerungen',
        'Ordne Fotos einer Reise zu oder öffne deine Reisen.',
      ),
      MemoryGalleryTab.all => (
        'Noch keine Erinnerungen',
        'Deine Fotos, Videos und Reisen erscheinen hier.',
      ),
    };

    return EmptyTravelState(
      icon: switch (_mediaTab) {
        MemoryGalleryTab.videos => Icons.videocam_outlined,
        MemoryGalleryTab.trips => Icons.flight_takeoff_outlined,
        _ => Icons.photo_library_outlined,
      },
      title: title,
      message: message,
      buttonLabel: _mediaTab == MemoryGalleryTab.trips
          ? 'Reisen öffnen'
          : 'Erinnerung hinzufügen',
      onPressed: () => context.push(
        _mediaTab == MemoryGalleryTab.trips ? '/trips' : '/memories/upload',
      ),
    );
  }
}

class _OwnershipChip extends StatelessWidget {
  const _OwnershipChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.turquoise.withValues(alpha: 0.15)
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.turquoise : AppColors.divider,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColors.turquoise : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
