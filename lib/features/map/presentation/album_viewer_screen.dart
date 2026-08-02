import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/core/services/signed_url_service.dart';
import 'package:memory_ai/features/map/data/memory_album_session.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';

/// Vollbild-Album außerhalb der Bottom-Navigation-Shell.
class AlbumViewerScreen extends StatefulWidget {
  const AlbumViewerScreen({super.key, required this.session, this.onClose});

  final MemoryAlbumSession session;
  final VoidCallback? onClose;

  @override
  State<AlbumViewerScreen> createState() => _AlbumViewerScreenState();
}

class _AlbumViewerScreenState extends State<AlbumViewerScreen> {
  late final PageController _controller;
  int _page = 0;
  final _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _pageCount {
    final n = widget.session.items.length;
    if (n == 0) return 0;
    switch (widget.session.layout) {
      case AlbumLayout.doublePage:
        return (n / 2).ceil();
      case AlbumLayout.collage:
        return (n / 4).ceil();
      case AlbumLayout.mixed:
        return (n / 2).ceil();
      case AlbumLayout.single:
        return n;
    }
  }

  List<MediaItemModel> _itemsForPage(int page) {
    final items = widget.session.items;
    switch (widget.session.layout) {
      case AlbumLayout.single:
        return [items[page]];
      case AlbumLayout.doublePage:
      case AlbumLayout.mixed:
        final start = page * 2;
        return items.sublist(start, (start + 2).clamp(0, items.length));
      case AlbumLayout.collage:
        final start = page * 4;
        return items.sublist(start, (start + 4).clamp(0, items.length));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    if (session.items.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Zu wenige Medien für ein Album.',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                TextButton(
                  onPressed: () =>
                      (widget.onClose ?? () => Navigator.pop(context))(),
                  child: const Text('Zurück'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final range = [
      if (session.dateFrom != null) _dateFormat.format(session.dateFrom!),
      if (session.dateTo != null) _dateFormat.format(session.dateTo!),
    ].join(' – ');

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        (widget.onClose ?? () => Navigator.pop(context))(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          [
                            if (session.locationLabel != null)
                              session.locationLabel!,
                            if (range.isNotEmpty) range,
                          ].join(' · '),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${_page + 1}/$_pageCount',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pageCount,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, page) {
                  final pageItems = _itemsForPage(page);
                  if (pageItems.length == 1) {
                    return _fullImage(pageItems.first);
                  }
                  return GridView.count(
                    crossAxisCount: pageItems.length > 2 ? 2 : pageItems.length,
                    physics: const NeverScrollableScrollPhysics(),
                    children: pageItems.map(_fullImage).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fullImage(MediaItemModel item) {
    return FutureBuilder<String?>(
      future: SignedUrlService.mediaGridUrl(item),
      builder: (context, snap) {
        final url = snap.data;
        return Column(
          children: [
            Expanded(
              child: url == null
                  ? const Center(child: CircularProgressIndicator())
                  : CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
            ),
            if (widget.session.captionsEnabled)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  item.takenAt != null
                      ? _dateFormat.format(item.takenAt!.toLocal())
                      : (item.locationName ?? ''),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
          ],
        );
      },
    );
  }
}
