import 'package:flutter/material.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';

/// Kombinierbare Kartenfilter (Ort, Zeit, Personen, Typ, Quelle).
class MapFilterState {
  const MapFilterState({
    this.locationQuery,
    this.city,
    this.region,
    this.country,
    this.continent,
    this.dateFrom,
    this.dateTo,
    this.years = const {},
    this.month,
    this.yearForMonth,
    this.quarters = const {},
    this.personIds = const {},
    this.onlyMe = false,
    this.unknownPeopleOnly = false,
    this.withoutPeople = false,
    this.mediaType,
    this.source = MapMediaSource.all,
  });

  final String? locationQuery;
  final String? city;
  final String? region;
  final String? country;
  final String? continent;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final Set<int> years;
  final int? month;
  final int? yearForMonth;

  /// Jahre, in denen Quartale greifen: key = year, value = Q1-Q4
  final Set<QuarterFilter> quarters;
  final Set<String> personIds;
  final bool onlyMe;
  final bool unknownPeopleOnly;
  final bool withoutPeople;
  final String? mediaType; // image | video | null=all
  final MapMediaSource source;

  bool get isEmpty =>
      (locationQuery == null || locationQuery!.trim().isEmpty) &&
      (city == null || city!.isEmpty) &&
      (region == null || region!.isEmpty) &&
      (country == null || country!.isEmpty) &&
      (continent == null || continent!.isEmpty) &&
      dateFrom == null &&
      dateTo == null &&
      years.isEmpty &&
      month == null &&
      quarters.isEmpty &&
      personIds.isEmpty &&
      !onlyMe &&
      !unknownPeopleOnly &&
      !withoutPeople &&
      mediaType == null &&
      source == MapMediaSource.all;

  MapFilterState copyWith({
    String? locationQuery,
    String? city,
    String? region,
    String? country,
    String? continent,
    DateTime? dateFrom,
    DateTime? dateTo,
    Set<int>? years,
    int? month,
    int? yearForMonth,
    Set<QuarterFilter>? quarters,
    Set<String>? personIds,
    bool? onlyMe,
    bool? unknownPeopleOnly,
    bool? withoutPeople,
    String? mediaType,
    MapMediaSource? source,
    bool clearLocationQuery = false,
    bool clearCity = false,
    bool clearRegion = false,
    bool clearCountry = false,
    bool clearContinent = false,
    bool clearDateFrom = false,
    bool clearDateTo = false,
    bool clearMonth = false,
    bool clearMediaType = false,
  }) {
    return MapFilterState(
      locationQuery: clearLocationQuery
          ? null
          : (locationQuery ?? this.locationQuery),
      city: clearCity ? null : (city ?? this.city),
      region: clearRegion ? null : (region ?? this.region),
      country: clearCountry ? null : (country ?? this.country),
      continent: clearContinent ? null : (continent ?? this.continent),
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      years: years ?? this.years,
      month: clearMonth ? null : (month ?? this.month),
      yearForMonth: yearForMonth ?? this.yearForMonth,
      quarters: quarters ?? this.quarters,
      personIds: personIds ?? this.personIds,
      onlyMe: onlyMe ?? this.onlyMe,
      unknownPeopleOnly: unknownPeopleOnly ?? this.unknownPeopleOnly,
      withoutPeople: withoutPeople ?? this.withoutPeople,
      mediaType: clearMediaType ? null : (mediaType ?? this.mediaType),
      source: source ?? this.source,
    );
  }

  List<MapFilterChipData> toChips() {
    final chips = <MapFilterChipData>[];
    if (locationQuery != null && locationQuery!.trim().isNotEmpty) {
      chips.add(MapFilterChipData('q', 'Ort: $locationQuery'));
    }
    if (city != null && city!.isNotEmpty) {
      chips.add(MapFilterChipData('city', 'Stadt: $city'));
    }
    if (region != null && region!.isNotEmpty) {
      chips.add(MapFilterChipData('region', 'Region: $region'));
    }
    if (country != null && country!.isNotEmpty) {
      chips.add(MapFilterChipData('country', 'Land: $country'));
    }
    if (continent != null && continent!.isNotEmpty) {
      chips.add(MapFilterChipData('continent', 'Kontinent: $continent'));
    }
    if (dateFrom != null || dateTo != null) {
      final from = dateFrom?.toIso8601String().substring(0, 10) ?? '…';
      final to = dateTo?.toIso8601String().substring(0, 10) ?? '…';
      chips.add(MapFilterChipData('range', '$from – $to'));
    }
    for (final y in years.toList()..sort()) {
      chips.add(MapFilterChipData('year_$y', '$y'));
    }
    if (month != null && yearForMonth != null) {
      chips.add(MapFilterChipData('month', '$month/$yearForMonth'));
    }
    for (final q in quarters) {
      chips.add(
        MapFilterChipData(
          'q_${q.year}_${q.quarter}',
          'Q${q.quarter} ${q.year}',
        ),
      );
    }
    if (onlyMe) chips.add(const MapFilterChipData('onlyMe', 'Nur ich'));
    if (unknownPeopleOnly) {
      chips.add(
        const MapFilterChipData('unknownPeople', 'Unbekannte Personen'),
      );
    }
    if (withoutPeople) {
      chips.add(const MapFilterChipData('withoutPeople', 'Ohne Personen'));
    }
    if (personIds.isNotEmpty) {
      chips.add(MapFilterChipData('people', '${personIds.length} Personen'));
    }
    if (mediaType == 'image') {
      chips.add(const MapFilterChipData('type', 'Fotos'));
    } else if (mediaType == 'video') {
      chips.add(const MapFilterChipData('type', 'Videos'));
    }
    if (source != MapMediaSource.all) {
      chips.add(MapFilterChipData('source', source.labelDe));
    }
    return chips;
  }

  MapFilterState removeChip(String id) {
    if (id == 'q') return copyWith(clearLocationQuery: true);
    if (id == 'city') return copyWith(clearCity: true);
    if (id == 'region') return copyWith(clearRegion: true);
    if (id == 'country') return copyWith(clearCountry: true);
    if (id == 'continent') return copyWith(clearContinent: true);
    if (id == 'range') {
      return copyWith(clearDateFrom: true, clearDateTo: true);
    }
    if (id.startsWith('year_')) {
      final y = int.tryParse(id.substring(5));
      if (y == null) return this;
      return copyWith(years: {...years}..remove(y));
    }
    if (id == 'month') return copyWith(clearMonth: true, yearForMonth: null);
    if (id.startsWith('q_')) {
      final parts = id.split('_');
      if (parts.length == 3) {
        final y = int.tryParse(parts[1]);
        final q = int.tryParse(parts[2]);
        if (y != null && q != null) {
          return copyWith(quarters: {...quarters}..remove(QuarterFilter(y, q)));
        }
      }
    }
    if (id == 'onlyMe') return copyWith(onlyMe: false);
    if (id == 'unknownPeople') return copyWith(unknownPeopleOnly: false);
    if (id == 'withoutPeople') return copyWith(withoutPeople: false);
    if (id == 'people') return copyWith(personIds: {});
    if (id == 'type') return copyWith(clearMediaType: true);
    if (id == 'source') return copyWith(source: MapMediaSource.all);
    return this;
  }
}

enum MapMediaSource {
  all,
  own,
  family,
  connected;

  String get labelDe {
    switch (this) {
      case MapMediaSource.all:
        return 'Alle Quellen';
      case MapMediaSource.own:
        return 'Eigene';
      case MapMediaSource.family:
        return 'Familie';
      case MapMediaSource.connected:
        return 'Verbunden';
    }
  }
}

class QuarterFilter {
  const QuarterFilter(this.year, this.quarter);

  final int year;
  final int quarter; // 1-4

  @override
  bool operator ==(Object other) =>
      other is QuarterFilter && other.year == year && other.quarter == quarter;

  @override
  int get hashCode => Object.hash(year, quarter);

  bool matches(DateTime date) {
    if (date.year != year) return false;
    final q = ((date.month - 1) ~/ 3) + 1;
    return q == quarter;
  }
}

class MapFilterChipData {
  const MapFilterChipData(this.id, this.label);
  final String id;
  final String label;
}

/// Reine Filterlogik (testbar).
abstract final class MapFilterEngine {
  static List<MediaItemModel> apply({
    required List<MediaItemModel> items,
    required MapFilterState filter,
    required Map<String, Set<String>> peopleByMediaId,
    String? currentUserPersonId,
    Set<String>? connectedMediaIds,
    String? currentUserId,
  }) {
    return items.where((item) {
      if (filter.mediaType != null && item.mediaType != filter.mediaType) {
        return false;
      }

      if (filter.source == MapMediaSource.own &&
          currentUserId != null &&
          item.ownerId != currentUserId) {
        return false;
      }
      if (filter.source == MapMediaSource.family && item.familyId == null) {
        return false;
      }
      if (filter.source == MapMediaSource.connected) {
        final ids = connectedMediaIds ?? {};
        if (!ids.contains(item.id)) return false;
      }

      if (filter.country != null &&
          filter.country!.isNotEmpty &&
          (item.countryName?.toLowerCase() != filter.country!.toLowerCase())) {
        return false;
      }
      if (filter.city != null &&
          filter.city!.isNotEmpty &&
          (item.city?.toLowerCase() != filter.city!.toLowerCase())) {
        return false;
      }
      if (filter.region != null &&
          filter.region!.isNotEmpty &&
          (item.regionName?.toLowerCase() != filter.region!.toLowerCase())) {
        return false;
      }
      if (filter.continent != null &&
          filter.continent!.isNotEmpty &&
          (item.continent?.toLowerCase() != filter.continent!.toLowerCase())) {
        return false;
      }
      if (filter.locationQuery != null &&
          filter.locationQuery!.trim().isNotEmpty) {
        final q = filter.locationQuery!.trim().toLowerCase();
        final hay = [
          item.locationName,
          item.city,
          item.regionName,
          item.countryName,
          item.continent,
        ].whereType<String>().join(' ').toLowerCase();
        if (!hay.contains(q)) return false;
      }

      final date = item.takenAt ?? item.createdAt;
      if (filter.dateFrom != null &&
          (date == null || date.isBefore(filter.dateFrom!))) {
        return false;
      }
      if (filter.dateTo != null &&
          (date == null || date.isAfter(filter.dateTo!))) {
        return false;
      }
      if (filter.years.isNotEmpty &&
          (date == null || !filter.years.contains(date.year))) {
        return false;
      }
      if (filter.month != null && filter.yearForMonth != null) {
        if (date == null ||
            date.month != filter.month ||
            date.year != filter.yearForMonth) {
          return false;
        }
      }
      if (filter.quarters.isNotEmpty) {
        if (date == null || !filter.quarters.any((q) => q.matches(date))) {
          return false;
        }
      }

      final people = peopleByMediaId[item.id] ?? const <String>{};
      if (filter.withoutPeople && people.isNotEmpty) return false;
      if (filter.unknownPeopleOnly && people.isNotEmpty) return false;
      if (filter.onlyMe) {
        if (currentUserPersonId == null ||
            !people.contains(currentUserPersonId)) {
          return false;
        }
      }
      if (filter.personIds.isNotEmpty &&
          filter.personIds.intersection(people).isEmpty) {
        return false;
      }

      return true;
    }).toList();
  }
}

/// Reproduzierbare Jahresfarben.
abstract final class YearColorPalette {
  static const _seed = <int, Color>{
    2022: Color(0xFF3B82F6), // Blau
    2023: Color(0xFF22C55E), // Grün
    2024: Color(0xFFF2A34C), // Orange
    2025: Color(0xFF8B5CF6), // Violett
    2026: Color(0xFFE85D6C), // Rot
  };

  static Color forYear(int year) {
    final known = _seed[year];
    if (known != null) return known;
    // Deterministische HSL-Farbe für weitere Jahre
    final hue = ((year * 47) % 360).toDouble();
    return HSLColor.fromAHSL(1, hue, 0.55, 0.52).toColor();
  }

  /// Hauptfarbe eines Orts: neuestes Jahr.
  static Color forItems(List<MediaItemModel> items) {
    final years = items
        .map((i) => i.takenAt?.year ?? i.createdAt?.year)
        .whereType<int>()
        .toList();
    if (years.isEmpty) return const Color(0xFF9AA5C0);
    years.sort();
    return forYear(years.last);
  }

  static List<int> yearsInItems(List<MediaItemModel> items) {
    return items
        .map((i) => i.takenAt?.year ?? i.createdAt?.year)
        .whereType<int>()
        .toSet()
        .toList()
      ..sort();
  }
}
