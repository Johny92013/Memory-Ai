import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/memories/data/media_link_model.dart';

/// Reine Logik: erkennt mögliche Zusammenhänge ohne Gesichtsabgleich.
abstract final class RelatedMediaMatcher {
  /// Zeitfenster für „ähnliches Aufnahmedatum“ (Stunden).
  static const similarTimeHours = 6;

  /// Max. Distanz in Grad (~111 m bei 0.001°) für gleichen Standort.
  static const locationEpsilonDegrees = 0.001;

  static List<RelatedMediaCandidate> findCandidates({
    required MediaItemModel source,
    required List<MediaItemModel> others,
    required Map<String, Set<String>> peopleByMediaId,
  }) {
    final sourcePeople = peopleByMediaId[source.id] ?? const {};
    final results = <RelatedMediaCandidate>[];

    for (final other in others) {
      if (other.id == source.id) continue;

      final otherPeople = peopleByMediaId[other.id] ?? const {};
      final shared = sourcePeople.intersection(otherPeople).length;
      final sameLoc = _sameLocation(source, other);
      final similarTime = _similarTakenAt(source, other);

      if (!sameLoc && !similarTime && shared == 0) continue;

      final relationType = _relationType(
        sameLoc: sameLoc,
        similarTime: similarTime,
        sharedPeople: shared,
      );
      final confidence = _confidence(
        sameLoc: sameLoc,
        similarTime: similarTime,
        sharedPeople: shared,
      );

      results.add(
        RelatedMediaCandidate(
          sourceMediaId: source.id,
          relatedMediaId: other.id,
          relationType: relationType,
          confidence: confidence,
          sharedPersonCount: shared,
          sameLocation: sameLoc,
          similarTime: similarTime,
        ),
      );
    }

    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results;
  }

  static bool _sameLocation(MediaItemModel a, MediaItemModel b) {
    if (a.latitude != null &&
        a.longitude != null &&
        b.latitude != null &&
        b.longitude != null) {
      final dLat = (a.latitude! - b.latitude!).abs();
      final dLon = (a.longitude! - b.longitude!).abs();
      if (dLat <= locationEpsilonDegrees && dLon <= locationEpsilonDegrees) {
        return true;
      }
    }
    final cityA = a.city?.trim().toLowerCase();
    final cityB = b.city?.trim().toLowerCase();
    final countryA = a.countryName?.trim().toLowerCase();
    final countryB = b.countryName?.trim().toLowerCase();
    if (cityA != null &&
        cityA.isNotEmpty &&
        cityA == cityB &&
        countryA != null &&
        countryA.isNotEmpty &&
        countryA == countryB) {
      return true;
    }
    return false;
  }

  static bool _similarTakenAt(MediaItemModel a, MediaItemModel b) {
    final ta = a.takenAt;
    final tb = b.takenAt;
    if (ta == null || tb == null) return false;
    final diff = ta.difference(tb).abs();
    return diff.inHours <= similarTimeHours;
  }

  static String _relationType({
    required bool sameLoc,
    required bool similarTime,
    required int sharedPeople,
  }) {
    if (sameLoc && similarTime && sharedPeople > 0) return 'same_event';
    if (similarTime && sharedPeople > 0) return 'same_moment';
    if (sameLoc && similarTime) return 'same_event';
    if (sameLoc) return 'same_location';
    if (sharedPeople > 0) return 'same_people';
    return 'same_moment';
  }

  static double _confidence({
    required bool sameLoc,
    required bool similarTime,
    required int sharedPeople,
  }) {
    var score = 0.0;
    if (sameLoc) score += 0.4;
    if (similarTime) score += 0.35;
    if (sharedPeople > 0) score += 0.25 + (sharedPeople - 1) * 0.05;
    return score.clamp(0.0, 1.0);
  }
}
