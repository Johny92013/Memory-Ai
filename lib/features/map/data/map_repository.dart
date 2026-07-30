import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/features/map/data/coordinate_key.dart';
import 'package:memory_ai/features/map/data/map_aggregation_helper.dart';
import 'package:memory_ai/features/map/data/map_filter_state.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/memories/data/media_link_repository.dart';
import 'package:memory_ai/features/memories/data/media_repository.dart';
import 'package:memory_ai/features/memories/data/people_repository.dart';

/// Lädt und filtert Karten-Daten (Batch, ohne Geocoding pro Marker).
class MapRepository {
  MapRepository({
    MediaRepository? mediaRepository,
    PeopleRepository? peopleRepository,
    MediaLinkRepository? linkRepository,
  }) : _mediaRepository = mediaRepository ?? MediaRepository(),
       _peopleRepository = peopleRepository ?? PeopleRepository(),
       _linkRepository = linkRepository ?? MediaLinkRepository();

  final MediaRepository _mediaRepository;
  final PeopleRepository _peopleRepository;
  final MediaLinkRepository _linkRepository;

  Future<List<MediaItemModel>> loadMapMedia({
    MapFilterState filter = const MapFilterState(),
    String? familyId,
  }) async {
    final scope = switch (filter.source) {
      MapMediaSource.family => 'family',
      MapMediaSource.all || MapMediaSource.connected => 'all',
      MapMediaSource.own => 'own',
    };

    List<MediaItemModel> items;
    if (scope == 'own') {
      items = await _mediaRepository.listMyMediaWithGps(limit: 1500);
    } else {
      final accessible = await _mediaRepository.listAccessibleMedia(
        scope: scope == 'family' ? 'family' : 'all',
        familyId: familyId,
        limit: 1500,
      );
      items = accessible.where((i) => i.hasGps).toList();
    }

    final peopleMap = await _peopleRepository.listPersonIdsByMediaIds(
      items.map((i) => i.id).toList(),
    );

    Set<String>? connectedIds;
    if (filter.source == MapMediaSource.connected) {
      connectedIds = await _loadConnectedIds(items.map((i) => i.id).toList());
    }

    String? selfPersonId;
    if (filter.onlyMe) {
      final people = await _peopleRepository.listMyPeople();
      for (final p in people) {
        if (p.name.toLowerCase() == 'ich') {
          selfPersonId = p.id;
          break;
        }
      }
      selfPersonId ??= people.isNotEmpty ? people.first.id : null;
    }

    final userId = SupabaseService.client.auth.currentUser?.id;

    return MapFilterEngine.apply(
      items: items,
      filter: filter,
      peopleByMediaId: peopleMap,
      currentUserPersonId: selfPersonId,
      connectedMediaIds: connectedIds,
      currentUserId: userId,
    );
  }

  Future<Set<String>> _loadConnectedIds(List<String> mediaIds) async {
    final ids = <String>{};
    for (final id in mediaIds.take(100)) {
      try {
        final links = await _linkRepository.listForMedia(
          id,
          status: 'confirmed',
        );
        for (final link in links) {
          ids.add(link.sourceMediaId);
          ids.add(link.relatedMediaId);
        }
      } catch (_) {}
    }
    return ids;
  }

  List<CountryStats> countryStats(List<MediaItemModel> items) {
    return MapAggregationHelper.aggregateCountries(items);
  }

  List<CityStats> cityStats(List<MediaItemModel> items, String countryName) {
    return MapAggregationHelper.aggregateCities(items, countryName);
  }

  List<MapLocationGroup> locationGroups(
    List<MediaItemModel> items, {
    String? countryName,
    String? cityName,
  }) {
    return MapAggregationHelper.groupByCoordinates(
      items,
      countryName: countryName,
      cityName: cityName,
    );
  }

  List<MapMarkerCluster> clusters(List<MapLocationGroup> groups, double zoom) {
    return MapAggregationHelper.clusterGroups(groups, zoom);
  }

  Future<List<MediaItemModel>> loadCountryMedia({
    required String countryName,
    MapFilterState filter = const MapFilterState(),
  }) async {
    return loadMapMedia(filter: filter.copyWith(country: countryName));
  }

  Future<List<MediaItemModel>> loadLocationMedia({
    String? countryName,
    String? cityName,
    String? coordinateKey,
    MapFilterState filter = const MapFilterState(),
  }) async {
    var items = await loadMapMedia(
      filter: filter.copyWith(
        country: countryName ?? filter.country,
        city: cityName ?? filter.city,
      ),
    );
    if (coordinateKey != null && coordinateKey.isNotEmpty) {
      items = items.where((i) {
        if (i.latitude == null || i.longitude == null) return false;
        return CoordinateKey.fromLatLon(i.latitude!, i.longitude!) ==
            coordinateKey;
      }).toList();
    }
    return items;
  }
}
