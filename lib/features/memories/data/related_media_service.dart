import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/memories/data/media_link_model.dart';
import 'package:memory_ai/features/memories/data/media_link_repository.dart';
import 'package:memory_ai/features/memories/data/media_repository.dart';
import 'package:memory_ai/features/memories/data/people_repository.dart';
import 'package:memory_ai/features/memories/data/related_media_matcher.dart';

/// Findet und speichert Verknüpfungsvorschläge (Ort / Zeit / bestätigte Personen).
class RelatedMediaService {
  RelatedMediaService({
    MediaRepository? mediaRepository,
    PeopleRepository? peopleRepository,
    MediaLinkRepository? linkRepository,
  }) : _mediaRepo = mediaRepository ?? MediaRepository(),
       _peopleRepo = peopleRepository ?? PeopleRepository(),
       _linkRepo = linkRepository ?? MediaLinkRepository();

  final MediaRepository _mediaRepo;
  final PeopleRepository _peopleRepo;
  final MediaLinkRepository _linkRepo;

  /// Scope: own | family | all (nur RLS-sichtbare Medien).
  Future<List<RelatedMediaCandidate>> suggestForMedia(
    String mediaId, {
    String scope = 'own',
    String? familyId,
  }) async {
    final source = await _mediaRepo.getMediaItem(mediaId);
    if (source == null) return [];

    final others = await _mediaRepo.listAccessibleMedia(
      scope: scope,
      familyId: familyId ?? source.familyId,
      limit: 200,
    );

    final peopleMap = <String, Set<String>>{};
    final ids = [source.id, ...others.map((m) => m.id)];
    for (final id in ids) {
      final people = await _peopleRepo.listPeopleForMedia(id);
      peopleMap[id] = people.map((p) => p.id).toSet();
    }

    return RelatedMediaMatcher.findCandidates(
      source: source,
      others: others,
      peopleByMediaId: peopleMap,
    );
  }

  Future<List<MediaLinkModel>> persistSuggestions(
    List<RelatedMediaCandidate> candidates, {
    int maxPersist = 20,
  }) async {
    final saved = <MediaLinkModel>[];
    for (final c in candidates.take(maxPersist)) {
      try {
        saved.add(await _linkRepo.upsertSuggestion(c));
      } catch (_) {
        // Duplikat / RLS – überspringen
      }
    }
    return saved;
  }

  Future<List<MediaLinkModel>> listSuggestions(String mediaId) {
    return _linkRepo.listForMedia(mediaId, status: 'suggested');
  }

  Future<List<MediaLinkModel>> listConfirmed(String mediaId) {
    return _linkRepo.listForMedia(mediaId, status: 'confirmed');
  }

  Future<void> confirm(String linkId) =>
      _linkRepo.updateStatus(linkId: linkId, status: 'confirmed');

  Future<void> reject(String linkId) =>
      _linkRepo.updateStatus(linkId: linkId, status: 'rejected');

  /// Lädt verknüpfte Medienmodelle (nur RLS-sichtbare).
  Future<List<MediaItemModel>> loadLinkedMediaItems(
    String mediaId, {
    String status = 'confirmed',
  }) async {
    final links = await _linkRepo.listForMedia(mediaId, status: status);
    final relatedIds = <String>{};
    for (final link in links) {
      relatedIds.add(
        link.sourceMediaId == mediaId
            ? link.relatedMediaId
            : link.sourceMediaId,
      );
    }
    if (relatedIds.isEmpty) return [];

    final items = <MediaItemModel>[];
    for (final id in relatedIds) {
      final item = await _mediaRepo.getAccessibleMediaItem(id);
      if (item != null) items.add(item);
    }
    return items;
  }
}
