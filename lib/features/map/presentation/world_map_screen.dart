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
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/memories/data/people_repository.dart';
import 'package:memory_ai/features/memories/data/person_model.dart';
import 'package:memory_ai/shared/widgets/empty_state.dart';

/// OpenStreetMap-Weltkarte mit Filtern, Jahresfarben, Clustering und Vorschau.
class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  final _mapController = MapController();
  final _repo = MapRepository();

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
    setState(() => _filter = next);
    await _load();
  }

  void _openCountry(CountryStats country) {
    context.push(
      '/map/country?name=${Uri.encodeComponent(country.countryName)}',
    );
  }

  void _showClusterPreview(MapMarkerCluster cluster) {
    // Bei mehreren Gruppen: erste Gruppe als Vorschau; sonst Cluster-Sheet
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Weltkarte',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Filter',
                    onPressed: _openFilters,
                    icon: Badge(
                      isLabelVisible: !_filter.isEmpty,
                      child: const Icon(Icons.filter_list),
                    ),
                  ),
                ],
              ),
              Text(
                '${_allItems.length} Medien mit Standort'
                '${_countries.isNotEmpty ? ' · ${_countries.length} Länder' : ''}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              ActiveFilterChips(
                filter: _filter,
                onChanged: (f) {
                  setState(() => _filter = f);
                  _load();
                },
              ),
            ],
          ),
        ),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_error != null)
          Expanded(
            child: Center(
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          )
        else if (_allItems.isEmpty)
          Expanded(
            child: EmptyState(
              icon: Icons.public_off_outlined,
              title: _filter.isEmpty
                  ? 'Noch keine Orte auf deiner Weltkarte'
                  : 'Keine Treffer für diese Filter',
              subtitle: _filter.isEmpty
                  ? 'Lade Fotos oder Videos mit Standortdaten hoch oder ergänze den Standort manuell.'
                  : 'Passe die Filter an oder lösche sie.',
              buttonLabel: _filter.isEmpty
                  ? 'Medien hinzufügen'
                  : 'Alle Filter löschen',
              onButtonPressed: _filter.isEmpty
                  ? () => context.push('/memories/upload')
                  : () {
                      setState(() => _filter = const MapFilterState());
                      _load();
                    },
            ),
          )
        else
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
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
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'memory_ai',
                      ),
                      if (routePolylines.isNotEmpty)
                        PolylineLayer(polylines: routePolylines),
                      MarkerLayer(
                        markers: _currentZoom < 6
                            ? _countries.map(_countryMarker).toList()
                            : _clusters.map(_clusterMarker).toList(),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: AppSpacing.md,
                  top: AppSpacing.md,
                  child: YearColorLegend(years: years),
                ),
              ],
            ),
          ),
        if (!_loading && _countries.isNotEmpty)
          Container(
            height: 120,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _countries.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final country = _countries[index];
                return _CountryCard(
                  country: country,
                  onTap: () => _openCountry(country),
                );
              },
            ),
          ),
      ],
    );
  }

  Marker _countryMarker(CountryStats country) {
    final color = country.years.isEmpty
        ? AppColors.accentWarm
        : YearColorPalette.forYear(country.years.last);
    return Marker(
      point: LatLng(country.centerLatitude, country.centerLongitude),
      width: 56,
      height: 56,
      child: GestureDetector(
        onTap: () => _openCountry(country),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            '${country.photoCount}',
            style: const TextStyle(
              color: AppColors.background,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Marker _clusterMarker(MapMarkerCluster cluster) {
    final items = [for (final g in cluster.groups) ...g.items];
    final color = YearColorPalette.forItems(items);
    return Marker(
      point: LatLng(cluster.latitude, cluster.longitude),
      width: 48,
      height: 48,
      child: GestureDetector(
        onTap: () => _showClusterPreview(cluster),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            '${cluster.count}',
            style: const TextStyle(
              color: AppColors.background,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
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
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
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
    );
  }
}
