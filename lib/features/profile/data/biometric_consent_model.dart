import 'package:memory_ai/features/profile/data/biometric_consent_constants.dart';

/// Erweiterte Einwilligungsfelder (auf biometric_consents, nicht profiles).
///
/// Liegt bewusst nicht auf `profiles`, weil Familienmitglieder profiles
/// lesen dürfen – Consent muss owner-only bleiben.
class BiometricConsentModel {
  const BiometricConsentModel({
    required this.userId,
    this.biometricConsentGiven = false,
    this.biometricConsentAt,
    this.biometricConsentVersion,
    this.faceReferenceConsentGiven = false,
    this.faceReferenceConsentAt,
    this.familyMatchingConsentGiven = false,
    this.familyMatchingConsentAt,
  });

  final String userId;
  final bool biometricConsentGiven;
  final DateTime? biometricConsentAt;
  final int? biometricConsentVersion;
  final bool faceReferenceConsentGiven;
  final DateTime? faceReferenceConsentAt;
  final bool familyMatchingConsentGiven;
  final DateTime? familyMatchingConsentAt;

  /// Reine Detection (Bounding Boxes).
  bool get isValidForCurrentVersion =>
      biometricConsentGiven &&
      biometricConsentVersion == kBiometricConsentVersion;

  factory BiometricConsentModel.fromJson(Map<String, dynamic> json) {
    return BiometricConsentModel(
      userId: json['user_id'] as String,
      biometricConsentGiven: json['biometric_consent_given'] as bool? ?? false,
      biometricConsentAt: _parseDateTime(json['biometric_consent_at']),
      biometricConsentVersion: json['biometric_consent_version'] as int?,
      faceReferenceConsentGiven:
          json['face_reference_consent_given'] as bool? ?? false,
      faceReferenceConsentAt: _parseDateTime(json['face_reference_consent_at']),
      familyMatchingConsentGiven:
          json['family_matching_consent_given'] as bool? ?? false,
      familyMatchingConsentAt: _parseDateTime(
        json['family_matching_consent_at'],
      ),
    );
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
