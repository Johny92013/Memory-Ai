import 'package:memory_ai/core/errors/app_exception.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/features/memories/data/media_face_detection_repository.dart';
import 'package:memory_ai/features/people/data/face_reference_repository.dart';
import 'package:memory_ai/features/people/data/face_suggestion_store.dart';
import 'package:memory_ai/features/profile/data/biometric_consent_constants.dart';
import 'package:memory_ai/features/profile/data/biometric_consent_model.dart';
import 'package:memory_ai/features/profile/data/face_recognition_data_store.dart';

/// Persistenz und Guards für biometrische Einwilligungen.
class BiometricConsentRepository {
  BiometricConsentRepository({
    FaceRecognitionDataStore? faceDataStore,
    FaceReferenceRepository? faceReferenceStore,
    FaceSuggestionStore? suggestionStore,
  }) : _faceDataStore = faceDataStore ?? MediaFaceDetectionRepository(),
       _faceReferenceStore = faceReferenceStore ?? FaceReferenceRepository(),
       _suggestionStore = suggestionStore ?? FaceSuggestionStore();

  static final _client = SupabaseService.client;

  final FaceRecognitionDataStore _faceDataStore;
  final FaceReferenceRepository _faceReferenceStore;
  final FaceSuggestionStore _suggestionStore;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AppException(message: 'Du bist nicht angemeldet.');
    }
    return id;
  }

  Future<BiometricConsentModel> getMyConsent() async {
    try {
      final userId = _userId;
      final row = await _client
          .from('biometric_consents')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (row == null) {
        return BiometricConsentModel(userId: userId);
      }
      return BiometricConsentModel.fromJson(Map<String, dynamic>.from(row));
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Map<String, dynamic> _baseUpsert(BiometricConsentModel current) {
    return {
      'user_id': current.userId,
      'biometric_consent_given': current.biometricConsentGiven,
      'biometric_consent_at': current.biometricConsentAt?.toIso8601String(),
      'biometric_consent_version': current.biometricConsentVersion,
      'face_reference_consent_given': current.faceReferenceConsentGiven,
      'face_reference_consent_at': current.faceReferenceConsentAt
          ?.toIso8601String(),
      'family_matching_consent_given': current.familyMatchingConsentGiven,
      'family_matching_consent_at': current.familyMatchingConsentAt
          ?.toIso8601String(),
    };
  }

  Future<BiometricConsentModel> _save(Map<String, dynamic> payload) async {
    final now = DateTime.now().toUtc();
    final row = await _client
        .from('biometric_consents')
        .upsert({...payload, 'updated_at': now.toIso8601String()})
        .select()
        .single();
    return BiometricConsentModel.fromJson(Map<String, dynamic>.from(row));
  }

  /// Einwilligung zur reinen Detection (Bounding Boxes).
  Future<BiometricConsentModel> grantConsent({
    int version = kBiometricConsentVersion,
  }) async {
    try {
      final current = await getMyConsent();
      final now = DateTime.now().toUtc();
      final payload = _baseUpsert(current)
        ..['biometric_consent_given'] = true
        ..['biometric_consent_at'] = now.toIso8601String()
        ..['biometric_consent_version'] = version;
      return await _save(payload);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Widerruf Detection: löscht nur Bounding-Box-Daten.
  Future<BiometricConsentModel> revokeConsent() async {
    try {
      final userId = _userId;
      await _faceDataStore.deleteAllForUser(userId);

      final current = await getMyConsent();
      final payload = _baseUpsert(current)
        ..['biometric_consent_given'] = false
        ..['biometric_consent_at'] = null
        ..['biometric_consent_version'] = null;
      return await _save(payload);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<BiometricConsentModel> grantFaceReferenceConsent() async {
    try {
      final current = await getMyConsent();
      final now = DateTime.now().toUtc();
      final payload = _baseUpsert(current)
        ..['face_reference_consent_given'] = true
        ..['face_reference_consent_at'] = now.toIso8601String();
      return await _save(payload);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Widerruf Selbstabgleich: löscht nur Referenz-Embeddings.
  Future<BiometricConsentModel> revokeFaceReferenceConsent() async {
    try {
      final userId = _userId;
      await _faceReferenceStore.deleteAllForUser(userId);
      await _suggestionStore.deleteSelfSuggestionsForOwner(userId);

      final current = await getMyConsent();
      final payload = _baseUpsert(current)
        ..['face_reference_consent_given'] = false
        ..['face_reference_consent_at'] = null;
      return await _save(payload);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<BiometricConsentModel> grantFamilyMatchingConsent() async {
    try {
      final current = await getMyConsent();
      final now = DateTime.now().toUtc();
      final payload = _baseUpsert(current)
        ..['family_matching_consent_given'] = true
        ..['family_matching_consent_at'] = now.toIso8601String();
      return await _save(payload);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Widerruf Familienabgleich: löscht nur offene Familien-Vorschläge.
  Future<BiometricConsentModel> revokeFamilyMatchingConsent() async {
    try {
      final userId = _userId;
      await _suggestionStore.deleteFamilySuggestionsForOwner(userId);

      final current = await getMyConsent();
      final payload = _baseUpsert(current)
        ..['family_matching_consent_given'] = false
        ..['family_matching_consent_at'] = null;
      return await _save(payload);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<bool> hasFaceRecognitionConsent(String userId) async {
    final current = _client.auth.currentUser?.id;
    if (current == null || current != userId) return false;
    try {
      final consent = await getMyConsent();
      return consent.isValidForCurrentVersion;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasFaceReferenceConsent(String userId) async {
    final current = _client.auth.currentUser?.id;
    if (current == null || current != userId) return false;
    try {
      final consent = await getMyConsent();
      return consent.faceReferenceConsentGiven;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasFamilyMatchingConsent(String userId) async {
    final current = _client.auth.currentUser?.id;
    if (current == null || current != userId) return false;
    try {
      final consent = await getMyConsent();
      return consent.familyMatchingConsentGiven;
    } catch (_) {
      return false;
    }
  }
}

Future<bool> hasFaceRecognitionConsent(String userId) {
  return BiometricConsentRepository().hasFaceRecognitionConsent(userId);
}

Future<bool> hasFaceReferenceConsent(String userId) {
  return BiometricConsentRepository().hasFaceReferenceConsent(userId);
}

Future<bool> hasFamilyMatchingConsent(String userId) {
  return BiometricConsentRepository().hasFamilyMatchingConsent(userId);
}
