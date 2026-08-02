import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_radius.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/app/theme_extensions.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/map/data/map_aggregation_helper.dart';
import 'package:memory_ai/features/map/data/map_filter_state.dart';
import 'package:memory_ai/features/map/data/map_repository.dart';
import 'package:memory_ai/features/map/data/media_location_enrichment_service.dart';
import 'package:memory_ai/features/map/presentation/active_filter_chips.dart';
import 'package:memory_ai/features/map/presentation/location_preview_sheet.dart';
import 'package:memory_ai/features/map/presentation/map_filter_sheet.dart';
import 'package:memory_ai/features/map/presentation/year_color_legend.dart';
import 'package:memory_ai/features/map/widgets/photo_location_marker.dart';
import 'package:memory_ai/features/map/widgets/travel_map_search_bar.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/memories/data/people_repository.dart';
import 'package:memory_ai/features/memories/data/person_model.dart';
import 'package:memory_ai/shared/widgets/travel_ui.dart';

/// OpenStreetMap-Weltkarte mit Filtern, Jahresfarben, Clustering und Vorschau.
class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  final _mapController = MapController();
  final _repo = MapRepository();
  final _searchController = TextEditingController();

  List<MediaItemModel> _allItems = [];
  List<CountryStats> _countries = [];
  List<MapMarkerCluster> _clusters = [];
  List<PersonModel> _people = [];
  MapFilterState _filter = const MapFilterState();
  bool _loading = true;
  String? _error;
  double _currentZoom = 4;

  @override
  void initState() {
    super.initState();
    _load();
    MediaLocationEnrichmentService().enrichPendingInBackground();
    PeopleRepository().listMyPeople().then((p) {
      if (mounted) setState(() => _people = p);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repo.loadMapMedia(filter: _filter);
      final countries = _repo.countryStats(items);
      final groups = _repo.locationGroups(items);
      final clusters = _repo.clusters(groups, _currentZoom);

      if (!mounted) return;
      setState(() {
        _allItems = items;
        _countries = countries;
        _clusters = clusters;
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

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMove) {
      final zoom = _mapController.camera.zoom;
      if (zoom != _currentZoom) {
        _currentZoom = zoom;
        final groups = _repo.locationGroups(_allItems);
        setState(() => _clusters = _repo.clusters(groups, zoom));
      }
    }
  }

  Future<void> _openFilters() async {
    final years = YearColorPalette.yearsInItems(_allItems);
    final next = await MapFilterSheet.show(
      context,
      initial: _filter,
      availableYears: years.isEmpty
          ? List.generate(5, (i) => DateTime.now().year - i)
          : years,
      people: _people,
    );
    if (next == null) return;
    setState(() {
      _filter = next;
      _searchController.text = next.locationQuery ?? '';
    });
    await _load();
  }

  void _applySearch(String query) {
    final trimmed = query.trim();
    setState(
      () => _filter = _filter.copyWith(
        locationQuery: trimmed.isEmpty ? null : trimmed,
        clearLocationQuery: trimmed.isEmpty,
      ),
    );
    _load();
  }

  void _openCountry(CountryStats country) {
    context.push(
      '/map/country?name=${Uri.encodeComponent(country.countryName)}',
    );
  }

  void _showClusterPreview(MapMarkerCluster cluster) {
    final group = cluster.groups.length == 1
        ? cluster.groups.first
        : MapLocationGroup(
            key: cluster.groups.first.key,
            latitude: cluster.latitude,
            longitude: cluster.longitude,
            items: [for (final g in cluster.groups) ...g.items],
            locationName: cluster.label,
            city: cluster.groups.first.city,
            countryName: cluster.groups.first.countryName,
          );
    LocationPreviewSheet.show(context, group: group);
  }

  List<Polyline> _tripRoutePolylines() {
    final withGps = _allItems
        .where((i) => i.latitude != null && i.longitude != null)
        .toList();
    final byTrip = <String, List<MediaItemModel>>{};
    for (final item in withGps) {
      final key = item.tripId ?? item.id;
      byTrip.putIfAbsent(key, () => []).add(item);
    }

    final polylines = <Polyline>[];
    for (final group in byTrip.values) {
      if (group.length < 2) continue;
      group.sort((a, b) {
        final ad = a.takenAt ?? a.createdAt ?? DateTime(0);
        final bd = b.takenAt ?? b.createdAt ?? DateTime(0);
        return ad.compareTo(bd);
      });
      polylines.add(
        Polyline(
          points: group.map((i) => LatLng(i.latitude!, i.longitude!)).toList(),
          strokeWidth: 2.5,
          color: AppColors.accentCool.withValues(alpha: 0.65),
          pattern: const StrokePattern.dotted(spacingFactor: 2.2),
        ),
      );
    }
    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    final routePolylines = _currentZoom >= 6
        ? _tripRoutePolylines()
        : const <Polyline>[];
    final years = YearColorPalette.yearsInItems(_allItems);
    final mapWidth = MediaQuery.sizeOf(context).width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.sheet),
                  ),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(51.1657, 10.4515),
                      initialZoom: 4,
                      onMapEvent: _onMapEvent,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.johny92013.memoryai',
                      ),
                      if (!_loading &&
                          _error == null &&
                          _allItems.isNotEmpty) ...[
                        if (routePolylines.isNotEmpty)
                          PolylineLayer(polylines: routePolylines),
                        MarkerLayer(
                          markers: _currentZoom < 6
                              ? _countries.map(_countryMarker).toList()
                              : _clusters.map(_clusterMarker).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_loading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x88071624),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (_error != null)
                Positioned.fill(
                  child: ColoredBox(
                    color: AppColors.backgroundDark.withValues(alpha: 0.85),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                  ),
                )
              else if (_allItems.isEmpty)
                Positioned.fill(
                  child: ColoredBox(
                    color: AppColors.backgroundDark.withValues(alpha: 0.55),
                    child: EmptyTravelState(
                      icon: Icons.public_outlined,
                      title: _filter.isEmpty
                          ? 'Deine Weltkarte ist noch leer'
                          : 'Keine Treffer für diese Filter',
                      message: _filter.isEmpty
                          ? 'Lade Fotos oder Videos mit Standortdaten hoch und entdecke deine Reisen auf der Weltkarte.'
                          : 'Passe die Filter an oder lösche sie.',
                      buttonLabel: _filter.isEmpty
                          ? 'Erinnerung hinzufügen'
                          : 'Alle Filter löschen',
                      onPressed: _filter.isEmpty
                          ? () => context.push('/memories/upload')
                          : () {
                              setState(() {
                                _filter = const MapFilterState();
                                _searchController.clear();
                              });
                              _load();
                            },
                    ),
                  ),
                ),
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.md,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TravelMapSearchBar(
                      controller: _searchController,
                      hasActiveFilters: !_filter.isEmpty,
                      onFilterPressed: _openFilters,
                      onSubmitted: _applySearch,
                    ),
                    ActiveFilterChips(
                      filter: _filter,
                      onChanged: (f) {
                        setState(() {
                          _filter = f;
                          _searchController.text = f.locationQuery ?? '';
                        });
                        _load();
                      },
                    ),
                  ],
                ),
              ),
              if (!_loading && _error == null && years.isNotEmpty)
                Positioned(
                  right: AppSpacing.md,
                  bottom: _countries.isNotEmpty ? 132 : AppSpacing.md,
                  child: SizedBox(
                    width: mapWidth * 0.2,
                    child: YearColorLegend(years: years),
                  ),
                ),
              if (!_loading && _countries.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 120,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.backgroundDark.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _countries.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final country = _countries[index];
                        return _CountryCard(
                          country: country,
                          onTap: () => _openCountry(country),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Marker _countryMarker(CountryStats country) {
    final color = country.years.isEmpty
        ? AppColors.turquoise
        : YearColorPalette.forYear(country.years.last);
    return Marker(
      point: LatLng(country.centerLatitude, country.centerLongitude),
      width: 64,
      height: 72,
      child: TravelMapClusterMarker(
        count: country.photoCount,
        color: color,
        onTap: () => _openCountry(country),
      ),
    );
  }

  Marker _clusterMarker(MapMarkerCluster cluster) {
    final items = [for (final g in cluster.groups) ...g.items];
    return Marker(
      point: LatLng(cluster.latitude, cluster.longitude),
      width: 64,
      height: 78,
      child: PhotoLocationMarker(
        items: items,
        count: cluster.count,
        onTap: () => _showClusterPreview(cluster),
      ),
    );
  }
}

class _CountryCard extends StatelessWidget {
  const _CountryCard({required this.country, required this.onTap});

  final CountryStats country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = country.years.isEmpty
        ? AppColors.accentWarm
        : YearColorPalette.forYear(country.years.last);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: AppColors.cardBackground.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Container(width: 4, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      country.countryName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${country.photoCount} Medien',
                      style: context.appTheme.statsMono.copyWith(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
