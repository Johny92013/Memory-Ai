import 'package:memory_ai/features/profile/data/biometric_consent_model.dart';
import 'package:memory_ai/features/profile/data/biometric_consent_repository.dart';

/// Fassade für die drei getrennten Gesichtseinwilligungen.
class FaceConsentService {
  FaceConsentService({BiometricConsentRepository? repository})
    : _repo = repository ?? BiometricConsentRepository();

  final BiometricConsentRepository _repo;

  Future<BiometricConsentModel> getMyConsent() => _repo.getMyConsent();

  Future<bool> hasFaceRecognitionConsent(String userId) =>
      _repo.hasFaceRecognitionConsent(userId);

  Future<bool> hasFaceReferenceConsent(String userId) =>
      _repo.hasFaceReferenceConsent(userId);

  Future<bool> hasFamilyMatchingConsent(String userId) =>
      _repo.hasFamilyMatchingConsent(userId);

  Future<BiometricConsentModel> grantDetection() => _repo.grantConsent();

  Future<BiometricConsentModel> revokeDetection() => _repo.revokeConsent();

  Future<BiometricConsentModel> grantFaceReference() =>
      _repo.grantFaceReferenceConsent();

  Future<BiometricConsentModel> revokeFaceReference() =>
      _repo.revokeFaceReferenceConsent();

  Future<BiometricConsentModel> grantFamilyMatching() =>
      _repo.grantFamilyMatchingConsent();

  Future<BiometricConsentModel> revokeFamilyMatching() =>
      _repo.revokeFamilyMatchingConsent();
}
