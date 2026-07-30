import 'package:memory_ai/features/map/data/coordinate_key.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';

/// Aggregierte Länderstatistik für die Weltkarte.
class CountryStats {
  const CountryStats({
    required this.countryName,
    this.countryCode,
    required this.photoCount,
    required this.tripCount,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.years,
    required this.topCities,
    required this.previewItems,
  });

  final String countryName;
  final String? countryCode;
  final int photoCount;
  final int tripCount;
  final double centerLatitude;
  final double centerLongitude;
  final List<int> years;
  final List<CityStats> topCities;
  final List<MediaItemModel> previewItems;
}

/// Stadt-/Ortsstatistik innerhalb eines Landes.
class CityStats {
  const CityStats({
    required this.cityName,
    required this.photoCount,
    required this.centerLatitude,
    required this.centerLongitude,
  });

  final String cityName;
  final int photoCount;
  final double centerLatitude;
  final double centerLongitude;
}

/// Gruppe von Medien an einem Standort (gerundete Koordinaten).
class MapLocationGroup {
  const MapLocationGroup({
    required this.key,
    required this.latitude,
    required this.longitude,
    required this.items,
    this.locationName,
    this.city,
    this.countryName,
  });

  final String key;
  final double latitude;
  final double longitude;
  final List<MediaItemModel> items;
  final String? locationName;
  final String? city;
  final String? countryName;

  int get count => items.length;

  String get displayLabel {
    if (locationName != null && locationName!.isNotEmpty) return locationName!;
    if (city != null && city!.isNotEmpty) return city!;
    return '$latitude, $longitude';
  }

  DateTime? get latestTakenAt {
    DateTime? latest;
    for (final item in items) {
      final date = item.takenAt ?? item.createdAt;
      if (date != null && (latest == null || date.isAfter(latest))) {
        latest = date;
      }
    }
    return latest;
  }
}

/// Marker-Cluster abhängig von Zoomstufe.
class MapMarkerCluster {
  const MapMarkerCluster({
    required this.latitude,
    required this.longitude,
    required this.count,
    required this.groups,
    this.label,
  });

  final double latitude;
  final double longitude;
  final int count;
  final List<MapLocationGroup> groups;
  final String? label;
}

/// Hilfsfunktionen für Karten-Aggregation und Clustering.
class MapAggregationHelper {
  MapAggregationHelper._();

  static List<CountryStats> aggregateCountries(List<MediaItemModel> items) {
    final map = <String, List<MediaItemModel>>{};
    for (final item in items) {
      final country = item.countryName?.trim();
      if (country == null || country.isEmpty) continue;
      map.putIfAbsent(country, () => []).add(item);
    }

    return map.entries.map((entry) {
      final group = entry.value;
      final latSum = group.fold<double>(0, (s, i) => s + i.latitude!);
      final lonSum = group.fold<double>(0, (s, i) => s + i.longitude!);
      final trips = group.map((i) => i.tripId).whereType<String>().toSet();
      final years =
          group
              .map((i) => i.takenAt?.year ?? i.createdAt?.year)
              .whereType<int>()
              .toSet()
              .toList()
            ..sort();
      final cities = aggregateCities(group, entry.key);

      return CountryStats(
        countryName: entry.key,
        countryCode: group.first.countryCode,
        photoCount: group.length,
        tripCount: trips.length,
        centerLatitude: latSum / group.length,
        centerLongitude: lonSum / group.length,
        years: years,
        topCities: cities.take(5).toList(),
        previewItems: group.take(6).toList(),
      );
    }).toList()..sort((a, b) => b.photoCount.compareTo(a.photoCount));
  }

  static List<CityStats> aggregateCities(
    List<MediaItemModel> items,
    String countryName,
  ) {
    final filtered = items
        .where(
          (i) =>
              i.countryName == countryName &&
              i.city != null &&
              i.city!.trim().isNotEmpty,
        )
        .toList();
    final map = <String, List<MediaItemModel>>{};
    for (final item in filtered) {
      map.putIfAbsent(item.city!.trim(), () => []).add(item);
    }

    return map.entries.map((entry) {
      final group = entry.value;
      final latSum = group.fold<double>(0, (s, i) => s + i.latitude!);
      final lonSum = group.fold<double>(0, (s, i) => s + i.longitude!);
      return CityStats(
        cityName: entry.key,
        photoCount: group.length,
        centerLatitude: latSum / group.length,
        centerLongitude: lonSum / group.length,
      );
    }).toList()..sort((a, b) => b.photoCount.compareTo(a.photoCount));
  }

  static List<MapLocationGroup> groupByCoordinates(
    List<MediaItemModel> items, {
    String? countryName,
    String? cityName,
  }) {
    final filtered = items.where((item) {
      if (item.latitude == null || item.longitude == null) return false;
      if (countryName != null && item.countryName != countryName) return false;
      if (cityName != null && item.city != cityName) return false;
      return true;
    });

    final map = <String, List<MediaItemModel>>{};
    for (final item in filtered) {
      final key = CoordinateKey.fromLatLon(item.latitude!, item.longitude!);
      map.putIfAbsent(key, () => []).add(item);
    }

    return map.entries.map((entry) {
      final group = entry.value;
      final latSum = group.fold<double>(0, (s, i) => s + i.latitude!);
      final lonSum = group.fold<double>(0, (s, i) => s + i.longitude!);
      final first = group.first;
      return MapLocationGroup(
        key: entry.key,
        latitude: latSum / group.length,
        longitude: lonSum / group.length,
        items: group,
        locationName: first.locationName,
        city: first.city,
        countryName: first.countryName,
      );
    }).toList();
  }

  static List<MapMarkerCluster> clusterGroups(
    List<MapLocationGroup> groups,
    double zoom,
  ) {
    final decimals = _decimalsForZoom(zoom);
    final map = <String, List<MapLocationGroup>>{};

    for (final group in groups) {
      final key = CoordinateKey.fromLatLon(
        group.latitude,
        group.longitude,
        decimals: decimals,
      );
      map.putIfAbsent(key, () => []).add(group);
    }

    return map.entries.map((entry) {
      final clusterGroups = entry.value;
      var latSum = 0.0;
      var lonSum = 0.0;
      var count = 0;
      String? label;

      for (final g in clusterGroups) {
        latSum += g.latitude * g.count;
        lonSum += g.longitude * g.count;
        count += g.count;
        label ??= g.displayLabel;
      }

      return MapMarkerCluster(
        latitude: latSum / count,
        longitude: lonSum / count,
        count: count,
        groups: clusterGroups,
        label: label,
      );
    }).toList();
  }

  static int _decimalsForZoom(double zoom) {
    if (zoom < 5) return 0;
    if (zoom < 7) return 1;
    if (zoom < 9) return 2;
    if (zoom < 12) return 3;
    return 4;
  }
}
