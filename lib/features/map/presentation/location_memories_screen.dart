import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/map/data/map_repository.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/memories/widgets/media_thumbnail_grid.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/empty_state.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';

/// Fotos an einem Standort, in einer Stadt oder einem Land.
class LocationMemoriesScreen extends StatefulWidget {
  const LocationMemoriesScreen({
    super.key,
    this.locationId,
    this.countryName,
    this.cityName,
    this.coordinateKey,
    this.locationLabel,
  });

  final String? locationId;
  final String? countryName;
  final String? cityName;
  final String? coordinateKey;
  final String? locationLabel;

  @override
  State<LocationMemoriesScreen> createState() => _LocationMemoriesScreenState();
}

class _LocationMemoriesScreenState extends State<LocationMemoriesScreen> {
  final _repo = MapRepository();
  List<MediaItemModel> _items = [];
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
      final items = await _repo.loadLocationMedia(
        countryName: widget.countryName,
        cityName: widget.cityName,
        coordinateKey: widget.coordinateKey,
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

  String get _title {
    if (widget.locationLabel != null && widget.locationLabel!.isNotEmpty) {
      return widget.locationLabel!;
    }
    if (widget.cityName != null && widget.cityName!.isNotEmpty) {
      return widget.cityName!;
    }
    if (widget.countryName != null && widget.countryName!.isNotEmpty) {
      return widget.countryName!;
    }
    return 'Erinnerungen am Ort';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final latest = _items.isEmpty
        ? null
        : _items
              .map((i) => i.takenAt ?? i.createdAt)
              .whereType<DateTime>()
              .fold<DateTime?>(
                null,
                (prev, d) => prev == null || d.isAfter(prev) ? d : prev,
              );

    return AppScaffold(
      title: _title,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorState(message: _error!, onRetry: _load)
          : _items.isEmpty
          ? EmptyState(
              icon: Icons.place_outlined,
              title: 'Keine Erinnerungen',
              subtitle: widget.locationId?.isEmpty ?? true
                  ? 'An diesem Ort gibt es noch keine Erinnerungen.'
                  : 'Kein Standort ausgewählt.',
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_items.length} Erinnerungen',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        if (latest != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Zuletzt: ${dateFormat.format(latest)}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  MediaThumbnailGrid(
                    items: _items,
                    onTap: (item) => context.push('/media/${item.id}'),
                  ),
                ],
              ),
            ),
    );
  }
}
