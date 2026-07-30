import 'package:flutter_test/flutter_test.dart';
import 'package:memory_ai/features/people/data/face_embedding_engine.dart';
import 'package:memory_ai/features/profile/data/biometric_consent_constants.dart';
import 'package:memory_ai/features/profile/data/biometric_consent_model.dart';
import 'package:memory_ai/features/profile/data/face_recognition_data_store.dart';

/// Guard-Logik analog zu hasFaceRecognitionConsent.
bool evaluateFaceRecognitionConsent({
  required String? currentUserId,
  required String requestedUserId,
  required BiometricConsentModel? consent,
  int requiredVersion = kBiometricConsentVersion,
}) {
  if (currentUserId == null || currentUserId != requestedUserId) {
    return false;
  }
  if (consent == null) return false;
  return consent.biometricConsentGiven &&
      consent.biometricConsentVersion == requiredVersion;
}

bool evaluateFaceReferenceConsent({
  required String? currentUserId,
  required String requestedUserId,
  required BiometricConsentModel? consent,
}) {
  if (currentUserId == null || currentUserId != requestedUserId) {
    return false;
  }
  return consent?.faceReferenceConsentGiven == true;
}

bool evaluateFamilyMatchingConsent({
  required String? currentUserId,
  required String requestedUserId,
  required BiometricConsentModel? consent,
}) {
  if (currentUserId == null || currentUserId != requestedUserId) {
    return false;
  }
  return consent?.familyMatchingConsentGiven == true;
}

/// Welche Mitglieder dürfen für Familienabgleich herangezogen werden?
List<String> eligibleFamilyMatchUserIds({
  required bool uploaderHasFamilyConsent,
  required Set<String> confirmedFamilyMemberIds,
  required Set<String> membersWithFamilyConsent,
  required Set<String> openInvitationUserIds,
  required Set<String> blockedOrRemovedUserIds,
  required Set<String> strangerUserIds,
}) {
  if (!uploaderHasFamilyConsent) return const [];
  final result = <String>[];
  for (final id in confirmedFamilyMemberIds) {
    if (openInvitationUserIds.contains(id)) continue;
    if (blockedOrRemovedUserIds.contains(id)) continue;
    if (strangerUserIds.contains(id)) continue;
    if (!membersWithFamilyConsent.contains(id)) continue;
    result.add(id);
  }
  return result;
}

/// Darf ein Vorschlag erneut angelegt werden?
bool shouldCreateSuggestion({
  required String? existingStatus,
  required bool forceNewAnalysis,
}) {
  if (existingStatus == 'rejected' && !forceNewAnalysis) return false;
  if (existingStatus == 'confirmed') return false;
  return true;
}

/// Welche Daten löscht welcher Widerruf?
Set<String> dataDeletedOnRevoke(String consentKind) {
  switch (consentKind) {
    case 'biometric':
      return {'media_face_detections'};
    case 'face_reference':
      return {'face_reference_embeddings', 'self_suggestions'};
    case 'family_matching':
      return {'family_suggestions'};
    default:
      return {};
  }
}

void main() {
  group('BiometricConsentModel', () {
    test('fromJson parst alle drei Einwilligungen', () {
      final model = BiometricConsentModel.fromJson({
        'user_id': 'u1',
        'biometric_consent_given': true,
        'biometric_consent_at': '2026-07-30T12:00:00.000Z',
        'biometric_consent_version': 1,
        'face_reference_consent_given': true,
        'face_reference_consent_at': '2026-07-30T13:00:00.000Z',
        'family_matching_consent_given': false,
        'family_matching_consent_at': null,
      });
      expect(model.userId, 'u1');
      expect(model.biometricConsentGiven, isTrue);
      expect(model.faceReferenceConsentGiven, isTrue);
      expect(model.familyMatchingConsentGiven, isFalse);
      expect(model.isValidForCurrentVersion, isTrue);
    });

    test('isValidForCurrentVersion false bei alter Version', () {
      const model = BiometricConsentModel(
        userId: 'u1',
        biometricConsentGiven: true,
        biometricConsentVersion: 0,
      );
      expect(model.isValidForCurrentVersion, isFalse);
    });
  });

  group('hasFaceRecognitionConsent (Guard-Logik)', () {
    test('Negativ: kein eingeloggter Nutzer', () {
      expect(
        evaluateFaceRecognitionConsent(
          currentUserId: null,
          requestedUserId: 'u1',
          consent: const BiometricConsentModel(
            userId: 'u1',
            biometricConsentGiven: true,
            biometricConsentVersion: kBiometricConsentVersion,
          ),
        ),
        isFalse,
      );
    });

    test('Positiv: gültige Detection-Einwilligung', () {
      expect(
        evaluateFaceRecognitionConsent(
          currentUserId: 'u1',
          requestedUserId: 'u1',
          consent: const BiometricConsentModel(
            userId: 'u1',
            biometricConsentGiven: true,
            biometricConsentVersion: kBiometricConsentVersion,
          ),
        ),
        isTrue,
      );
    });
  });

  group('getrennte Matching-Guards', () {
    test('ohne face_reference_consent kein Selbstabgleich', () {
      expect(
        evaluateFaceReferenceConsent(
          currentUserId: 'u1',
          requestedUserId: 'u1',
          consent: const BiometricConsentModel(
            userId: 'u1',
            biometricConsentGiven: true,
            biometricConsentVersion: kBiometricConsentVersion,
          ),
        ),
        isFalse,
      );
    });

    test(
      'ohne family_matching_consent kein Familienabgleich trotz Detection',
      () {
        expect(
          evaluateFamilyMatchingConsent(
            currentUserId: 'u1',
            requestedUserId: 'u1',
            consent: const BiometricConsentModel(
              userId: 'u1',
              biometricConsentGiven: true,
              biometricConsentVersion: kBiometricConsentVersion,
              faceReferenceConsentGiven: true,
            ),
          ),
          isFalse,
        );
      },
    );

    test(
      'Familienmitglied ohne eigene Einwilligung wird nicht abgeglichen',
      () {
        final eligible = eligibleFamilyMatchUserIds(
          uploaderHasFamilyConsent: true,
          confirmedFamilyMemberIds: {'anna', 'bob'},
          membersWithFamilyConsent: {'anna'},
          openInvitationUserIds: {},
          blockedOrRemovedUserIds: {},
          strangerUserIds: {},
        );
        expect(eligible, ['anna']);
        expect(eligible.contains('bob'), isFalse);
      },
    );

    test('fremde und nicht verbundene Nutzer nie abgeglichen', () {
      final eligible = eligibleFamilyMatchUserIds(
        uploaderHasFamilyConsent: true,
        confirmedFamilyMemberIds: {'anna'},
        membersWithFamilyConsent: {'anna', 'stranger'},
        openInvitationUserIds: {'invitee'},
        blockedOrRemovedUserIds: {'blocked'},
        strangerUserIds: {'stranger'},
      );
      expect(eligible, ['anna']);
      expect(eligible.contains('stranger'), isFalse);
      expect(eligible.contains('invitee'), isFalse);
      expect(eligible.contains('blocked'), isFalse);
    });
  });

  group('Vorschläge bestätigen/ablehnen', () {
    test('abgelehnter Vorschlag erscheint nicht erneut ohne neue Analyse', () {
      expect(
        shouldCreateSuggestion(
          existingStatus: 'rejected',
          forceNewAnalysis: false,
        ),
        isFalse,
      );
      expect(
        shouldCreateSuggestion(
          existingStatus: 'rejected',
          forceNewAnalysis: true,
        ),
        isTrue,
      );
    });

    test('Vorschlag kann bestätigt werden (Statuswechsel erlaubt)', () {
      expect(
        shouldCreateSuggestion(
          existingStatus: 'suggested',
          forceNewAnalysis: false,
        ),
        isTrue,
      );
      expect(
        shouldCreateSuggestion(existingStatus: null, forceNewAnalysis: false),
        isTrue,
      );
    });
  });

  group('Widerruf löscht nur zugehörige Daten', () {
    test('Detection-Widerruf', () {
      expect(dataDeletedOnRevoke('biometric'), {'media_face_detections'});
      expect(
        dataDeletedOnRevoke('biometric').contains('face_reference_embeddings'),
        isFalse,
      );
    });

    test('Referenz-Widerruf', () {
      final deleted = dataDeletedOnRevoke('face_reference');
      expect(deleted.contains('face_reference_embeddings'), isTrue);
      expect(deleted.contains('media_face_detections'), isFalse);
    });

    test('Familien-Widerruf', () {
      final deleted = dataDeletedOnRevoke('family_matching');
      expect(deleted, {'family_suggestions'});
      expect(deleted.contains('face_reference_embeddings'), isFalse);
      expect(deleted.contains('media_face_detections'), isFalse);
    });
  });

  group('FaceEmbeddingMath', () {
    test('cosineSimilarity für identische normalisierte Vektoren ≈ 1', () {
      final a = FaceEmbeddingMath.l2Normalize([1, 2, 3]);
      expect(FaceEmbeddingMath.cosineSimilarity(a, a), closeTo(1.0, 1e-9));
    });
  });

  group('FaceRecognitionDataStore', () {
    test('NoOp löscht ohne Fehler', () async {
      const store = NoOpFaceRecognitionDataStore();
      await store.deleteAllForUser('u1');
    });
  });
}
