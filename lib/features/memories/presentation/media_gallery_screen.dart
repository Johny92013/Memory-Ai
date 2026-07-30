import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/media_change_notifier.dart';
import 'package:memory_ai/core/services/signed_url_service.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/memories/data/media_repository.dart';
import 'package:memory_ai/shared/widgets/empty_state.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';

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
  String? _error;
  int _offset = 0;
  static const _pageSize = 30;

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
      final rows = await _repo.listMyMedia(limit: _pageSize, offset: 0);
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
      final rows = await _repo.listMyMedia(limit: _pageSize, offset: _offset);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fotos'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: Icon(
              _showWithoutGps
                  ? Icons.location_off
                  : Icons.location_off_outlined,
              color: _showWithoutGps ? AppColors.primary : null,
            ),
            tooltip: 'Ohne Standort',
            onPressed: () => setState(() => _showWithoutGps = !_showWithoutGps),
          ),
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined),
            onPressed: () => context.push('/memories/upload'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorState(message: _error!, onRetry: _loadInitial)
          : _items.isEmpty && !_showWithoutGps
          ? EmptyState(
              icon: Icons.photo_library_outlined,
              title: 'Noch keine Fotos',
              subtitle: 'Lade deine ersten Erinnerungen hoch.',
              buttonLabel: 'Fotos hochladen',
              onButtonPressed: () => context.push('/memories/upload'),
            )
          : RefreshIndicator(
              onRefresh: _loadInitial,
              color: AppColors.primary,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  if (_showWithoutGps && _withoutGpsItems.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text(
                          'Ohne Standort – Ort manuell zuweisen',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ),
                  if (_showWithoutGps && _withoutGpsItems.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = _withoutGpsItems[index];
                          return _GalleryTile(
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
                  if (!_showWithoutGps || _items.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.all(8),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= _items.length) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final item = _items[index];
                            return _GalleryTile(
                              item: item,
                              onTap: () => context.push('/media/${item.id}'),
                            );
                          },
                          childCount:
                              _items.length +
                              (_loadingMore && !_showWithoutGps ? 1 : 0),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({
    required this.item,
    this.onTap,
    this.showNoGpsBadge = false,
  });

  final MediaItemModel item;
  final VoidCallback? onTap;
  final bool showNoGpsBadge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<String?>(
            future: SignedUrlService.mediaGridUrl(item),
            builder: (context, snapshot) {
              final url = snapshot.data;
              if (url == null) {
                return Container(
                  color: AppColors.card,
                  child: const Icon(
                    Icons.image_outlined,
                    color: AppColors.textSecondary,
                  ),
                );
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(color: AppColors.card),
                  errorWidget: (_, _, _) => Container(
                    color: AppColors.card,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              );
            },
          ),
          if (showNoGpsBadge)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.location_off,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
