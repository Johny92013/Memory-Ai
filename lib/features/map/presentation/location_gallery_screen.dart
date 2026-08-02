import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/signed_url_service.dart';
import 'package:memory_ai/features/map/data/map_filter_state.dart';
import 'package:memory_ai/features/map/data/map_repository.dart';
import 'package:memory_ai/features/map/presentation/album_creation_sheet.dart';
import 'package:memory_ai/features/map/presentation/slideshow_configuration_sheet.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/empty_state.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';

/// Ortsgalerie mit Filtern, Auswahl, Album- und Video-Button.
/// Bottom Navigation bleibt sichtbar (normale Push-Route).
class LocationGalleryScreen extends StatefulWidget {
  const LocationGalleryScreen({
    super.key,
    this.coordinateKey,
    this.countryName,
    this.cityName,
    this.locationLabel,
  });

  final String? coordinateKey;
  final String? countryName;
  final String? cityName;
  final String? locationLabel;

  @override
  State<LocationGalleryScreen> createState() => _LocationGalleryScreenState();
}

class _LocationGalleryScreenState extends State<LocationGalleryScreen> {
  final _repo = MapRepository();
  List<MediaItemModel> _items = [];
  final Set<String> _selected = {};
  bool _selectionMode = false;
  bool _loading = true;
  String? _error;
  MapMediaSource _source = MapMediaSource.all;

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
      final items = await _repo.loadLocationMedia(
        countryName: widget.countryName,
        cityName: widget.cityName,
        coordinateKey: widget.coordinateKey,
        filter: MapFilterState(source: _source),
      );
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _openAlbum() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zu wenige Medien für ein Album.')),
      );
      return;
    }
    final session = await AlbumCreationSheet.show(
      context,
      items: _items,
      selectedIds: _selected,
      locationLabel: widget.locationLabel ?? widget.cityName ?? 'Ort',
    );
    if (session == null || !mounted) return;
    if (session.albumId != null) {
      context.push('/album/${session.albumId}');
    } else {
      context.push('/map/album-viewer', extra: session);
    }
  }

  Future<void> _openSlideshow() async {
    if (_items.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Für ein Video brauchst du mindestens 2 Medien.'),
        ),
      );
      return;
    }
    final session = await SlideshowConfigurationSheet.show(
      context,
      items: _items,
      selectedIds: _selected,
      locationLabel: widget.locationLabel ?? widget.cityName ?? 'Ort',
    );
    if (session == null || !mounted) return;
    context.push('/map/slideshow', extra: session);
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.locationLabel ??
        widget.cityName ??
        widget.countryName ??
        'Ortsgalerie';

    return AppScaffold(
      title: title,
      actions: [
        IconButton(
          tooltip: 'Auswahl',
          onPressed: () => setState(() {
            _selectionMode = !_selectionMode;
            if (!_selectionMode) _selected.clear();
          }),
          icon: Icon(_selectionMode ? Icons.close : Icons.checklist),
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final s in [
                    MapMediaSource.all,
                    MapMediaSource.own,
                    MapMediaSource.family,
                    MapMediaSource.connected,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(s.labelDe),
                        selected: _source == s,
                        onSelected: (_) {
                          _source = s;
                          _load();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? ErrorState(message: _error!, onRetry: _load)
                : _items.isEmpty
                ? EmptyState(
                    icon: Icons.place_outlined,
                    title: 'Keine Medien an diesem Ort',
                    subtitle:
                        'Lade Fotos mit Standortdaten hoch oder ändere den Filter.',
                    buttonLabel: 'Medien hinzufügen',
                    onButtonPressed: () => context.push('/memories/upload'),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final selected = _selected.contains(item.id);
                      return GestureDetector(
                        onTap: () {
                          if (_selectionMode) {
                            setState(() {
                              if (selected) {
                                _selected.remove(item.id);
                              } else {
                                _selected.add(item.id);
                              }
                            });
                          } else {
                            context.push('/media/${item.id}');
                          }
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            FutureBuilder<String?>(
                              future: SignedUrlService.mediaGridUrl(item),
                              builder: (context, snap) {
                                final url = snap.data;
                                if (url == null) {
                                  return Container(color: AppColors.surface);
                                }
                                return CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                            if (_selectionMode && selected)
                              const Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: AppColors.accentWarm,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (!_loading && _items.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openAlbum,
                        icon: const Icon(Icons.photo_album_outlined),
                        label: Text(
                          _selectionMode && _selected.isNotEmpty
                              ? 'Album (${_selected.length})'
                              : 'Album',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _openSlideshow,
                        icon: const Icon(Icons.slideshow),
                        label: const Text('Video'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
