# Abschlussbericht: Biometrische Einwilligungsverwaltung

**Datum:** 2026-07-30

## Ergebnis

Einwilligungsverwaltung für gerätebasierte Gesichtserkennung (Art. 9 DSGVO) ist implementiert. Keine Gesichtserkennung selbst.

## Erstellte Dateien

| Datei | Zweck |
|-------|--------|
| `supabase/migrations/20260731_biometric_consent.sql` | Tabelle + Owner-only RLS |
| `lib/features/profile/data/biometric_consent_constants.dart` | `kBiometricConsentVersion = 1` |
| `lib/features/profile/data/biometric_consent_model.dart` | Modell |
| `lib/features/profile/data/biometric_consent_repository.dart` | Persistenz + `hasFaceRecognitionConsent` |
| `lib/features/profile/data/face_recognition_data_store.dart` | Lösch-Interface (NoOp bis Prompt 2) |
| `lib/features/profile/presentation/consent_info_screen.dart` | Info + Checkbox + Bestätigen |
| `test/biometric_consent_test.dart` | Guard-/Modell-Tests |

## Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/profile/presentation/profile_screen.dart` | Bereich „Privatsphäre und Einwilligungen“ |
| `lib/app/app_router.dart` | Route `/profile/consent/face` |

## Migration

- **Remote bereits angewendet** auf Projekt `bgxijzdycxntctoeeitb` (`biometric_consent`).
- Lokale Datei: `supabase/migrations/20260731_biometric_consent.sql`.

**Warum eigene Tabelle `biometric_consents` statt Spalten auf `profiles`?**  
Familienmitglieder dürfen Profile lesen (`Users can view family member profiles`). Spalten auf `profiles` wären damit für andere sichtbar. Die äquivalente Owner-only-Tabelle erfüllt die Vorgabe ohne Datenleck.

Felder: `biometric_consent_given`, `biometric_consent_at`, `biometric_consent_version` (+ `user_id` PK).

## Guard-Tests (`hasFaceRecognitionConsent`-Logik)

| Fall | Ergebnis |
|------|----------|
| Kein Login | negativ (`false`) |
| Fremde `userId` | negativ |
| Keine Einwilligung | negativ |
| Veraltete Version | negativ |
| Gültige Einwilligung + aktuelle Version | **positiv (`true`)** |

## Qualitätschecks

- `dart format` – OK  
- `flutter analyze` – No issues found  
- `flutter test` – alle Tests bestanden (inkl. neuer Consent-Tests)

## Nutzung für Prompt 2+

Vor jeder Gesichtserkennung:

```dart
if (!await hasFaceRecognitionConsent(userId)) {
  // Verarbeitung ablehnen / Consent-Flow öffnen
}
```
