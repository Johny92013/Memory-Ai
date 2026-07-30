import 'package:memory_ai/features/memories/data/people_repository.dart';
import 'package:memory_ai/features/memories/data/person_model.dart';

/// Bestätigen / Ablehnen von Gesichtsvorschlägen.
class FaceSuggestionReview {
  FaceSuggestionReview({PeopleRepository? peopleRepo})
    : _peopleRepo = peopleRepo ?? PeopleRepository();

  final PeopleRepository _peopleRepo;

  Future<void> confirm({required String mediaId, required String personId}) {
    return _peopleRepo.setMediaPersonStatus(
      mediaId: mediaId,
      personId: personId,
      status: 'confirmed',
    );
  }

  Future<void> reject({required String mediaId, required String personId}) {
    return _peopleRepo.setMediaPersonStatus(
      mediaId: mediaId,
      personId: personId,
      status: 'rejected',
    );
  }

  Future<List<PersonModel>> listSuggested(String mediaId) {
    return _peopleRepo.listPeopleForMedia(mediaId, status: 'suggested');
  }

  Future<List<PersonModel>> listConfirmed(String mediaId) {
    return _peopleRepo.listPeopleForMedia(mediaId, status: 'confirmed');
  }
}
