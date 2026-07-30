import 'dart:math' as math;

import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/trips/data/trip_model.dart';
import 'package:memory_ai/features/trips/data/trip_suggestion_model.dart';
import 'package:uuid/uuid.dart';

/// Regelbasierte Reiseerkennung – keine KI, nur explizite Vorschläge.
class TripDetectionService {
  TripDetectionService({
    this.maxGapDays = 14,
    this.homeRadiusKm = 50,
    this.minPhotosPerSuggestion = 1,
  });

  /// Große zeitliche Lücke → neue Reise.
  final int maxGapDays;

  /// Heimatumgebung-Radius in km.
  final double homeRadiusKm;

  final int minPhotosPerSuggestion;

  /// Erkennt Reisevorschläge aus noch nicht zugeordneten Medien.
  List<TripSuggestion> detectSuggestions({
    required List<MediaItemModel> media,
    List<TripModel> existingTrips = const [],
  }) {
    final unassigned = media
        .where(
          (m) =>
              m.tripId == null &&
              m.takenAt != null &&
              m.countryName != null &&
              m.countryName!.trim().isNotEmpty,
        )
        .toList();

    if (unassigned.isEmpty) return [];

    final home = _detectHome(unassigned);
    final eligible = unassigned.where((m) {
      if (home == null) return true;
      if (m.countryName != home.country) return true;
      if (m.latitude == null || m.longitude == null) return false;
      return _distanceKm(
            m.latitude!,
            m.longitude!,
            home.latitude,
            home.longitude,
          ) >
          homeRadiusKm;
    }).toList();

    final byCountry = <String, List<MediaItemModel>>{};
    for (final item in eligible) {
      final country = item.countryName!.trim();
      byCountry.putIfAbsent(country, () => []).add(item);
    }

    final suggestions = <TripSuggestion>[];
    for (final entry in byCountry.entries) {
      final items = List<MediaItemModel>.from(entry.value)
        ..sort((a, b) => a.takenAt!.compareTo(b.takenAt!));

      var cluster = <MediaItemModel>[];
      for (final item in items) {
        if (cluster.isEmpty) {
          cluster.add(item);
          continue;
        }
        final last = cluster.last;
        final gapDays = item.takenAt!.difference(last.takenAt!).inDays;
        final sameCluster =
            gapDays <= maxGapDays &&
            _compatibleLocations(last, item, entry.key);
        if (sameCluster) {
          cluster.add(item);
        } else {
          _addSuggestion(suggestions, entry.key, cluster);
          cluster = [item];
        }
      }
      _addSuggestion(suggestions, entry.key, cluster);
    }

    return suggestions
        .where((s) => !_overlapsExistingTrip(s, existingTrips))
        .toList();
  }

  void _addSuggestion(
    List<TripSuggestion> suggestions,
    String country,
    List<MediaItemModel> cluster,
  ) {
    if (cluster.length < minPhotosPerSuggestion) return;
    final start = cluster.first.takenAt!;
    final end = cluster.last.takenAt!;
    final year = start.year;
    suggestions.add(
      TripSuggestion(
        id: const Uuid().v4(),
        countryName: country,
        mediaItems: List.unmodifiable(cluster),
        startDate: start,
        endDate: end,
        suggestedTitle: '$country $year',
      ),
    );
  }

  bool _compatibleLocations(
    MediaItemModel a,
    MediaItemModel b,
    String country,
  ) {
    if (a.countryName?.trim() != country || b.countryName?.trim() != country) {
      return false;
    }
    if (a.latitude == null ||
        a.longitude == null ||
        b.latitude == null ||
        b.longitude == null) {
      return true;
    }
    final dist = _distanceKm(
      a.latitude!,
      a.longitude!,
      b.latitude!,
      b.longitude!,
    );
    return dist < 500;
  }

  bool _overlapsExistingTrip(TripSuggestion suggestion, List<TripModel> trips) {
    for (final trip in trips) {
      if (trip.startDate == null || trip.endDate == null) continue;
      final overlaps =
          !suggestion.endDate.isBefore(trip.startDate!) &&
          !suggestion.startDate.isAfter(trip.endDate!);
      if (overlaps &&
          trip.countries.any(
            (c) => c.toLowerCase() == suggestion.countryName.toLowerCase(),
          )) {
        return true;
      }
    }
    return false;
  }

  _HomePoint? _detectHome(List<MediaItemModel> media) {
    final countryCounts = <String, int>{};
    for (final m in media) {
      final c = m.countryName?.trim();
      if (c != null && c.isNotEmpty) {
        countryCounts[c] = (countryCounts[c] ?? 0) + 1;
      }
    }
    if (countryCounts.isEmpty) return null;

    final homeCountry = countryCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    final withGps = media
        .where(
          (m) =>
              m.countryName == homeCountry &&
              m.latitude != null &&
              m.longitude != null,
        )
        .toList();
    if (withGps.isEmpty) return null;

    final lat =
        withGps.map((m) => m.latitude!).reduce((a, b) => a + b) /
        withGps.length;
    final lon =
        withGps.map((m) => m.longitude!).reduce((a, b) => a + b) /
        withGps.length;
    return _HomePoint(country: homeCountry, latitude: lat, longitude: lon);
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double deg) => deg * math.pi / 180;
}

class _HomePoint {
  const _HomePoint({
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  final String country;
  final double latitude;
  final double longitude;
}
