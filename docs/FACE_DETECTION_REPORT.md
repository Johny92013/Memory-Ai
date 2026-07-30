# Abschlussbericht: Gesichts-Detection (Prompt 2)

**Datum:** 2026-07-30

## Voraussetzung Prompt 1

Vorhanden und genutzt:
- `hasFaceRecognitionConsent(userId)`
- `BiometricConsentRepository` / `ConsentInfoScreen`
- `FaceRecognitionDataStore` – jetzt mit konkreter Löschung verbunden

## Ergebnis

Nur **Detection** (Gesichtspositionen). Keine Identitätserkennung, keine Embeddings, kein Clustering.

## Migration

| | |
|--|--|
| Datei | `supabase/migrations/20260731_media_face_detections.sql` |
| Remote | angewendet auf `bgxijzdycxntctoeeitb` |
| Tabelle | `public.media_face_detections` |
| RLS | nur `owner_id` (select/insert/update/delete) |

## Erstellte / geänderte Dateien

**Neu**
- `lib/features/memories/data/media_face_detection_model.dart`
- `lib/features/memories/data/face_detector_engine.dart`
- `lib/features/memories/data/ml_kit_face_detector_engine*.dart` (IO + Stub)
- `lib/features/memories/data/media_face_detection_repository.dart`
- `lib/features/memories/data/media_face_detection_service.dart`
- `lib/features/memories/data/face_crop_helper.dart`
- `lib/features/memories/data/person_model.dart`
- `lib/features/memories/data/people_repository.dart`
- `test/media_face_detection_service_test.dart`
- `docs/FACE_DETECTION_REPORT.md` (diese Datei)

**Geändert**
- `pubspec.yaml` – `google_mlkit_face_detection`
- `lib/features/memories/data/media_repository.dart` – Hintergrund-Detection nach Upload
- `lib/features/profile/data/biometric_consent_repository.dart` – Löschung via `MediaFaceDetectionRepository`
- `lib/features/memories/presentation/media_detail_screen.dart` – UI „Erkannte Gesichter“ / manuelle Zuordnung

## Ablauf

1. Upload speichert Foto wie bisher  
2. `unawaited(MediaFaceDetectionService.processAfterUpload(...))`  
3. Guard: ohne Consent → stiller Skip  
4. Mit Consent → ML Kit lokal → relative Bounding Boxes in DB  

## Widerruf

`revokeConsent()` ruft `MediaFaceDetectionRepository.deleteAllForUser` → **DELETE** aller `media_face_detections` des Users.

## Unit-Tests (`media_face_detection_service_test.dart`)

| Fall | Ergebnis |
|------|----------|
| ohne Einwilligung | Engine nicht aufgerufen, keine Inserts |
| mit Einwilligung | Detection + 2 Inserts |
| Widerruf | alle Einträge des Users entfernt |

## Qualität

- `dart format` OK  
- `flutter analyze` – No issues found  
- `flutter test` – **96** bestanden  

## Manuelle Testanleitung

1. **Mit Einwilligung:** Profil → Gesichtserkennung aktivieren → Foto mit mehreren Gesichtern hochladen → Galerie → Foto öffnen → „Erkannte Gesichter“ zeigt Ausschnitte → Tap → Person wählen/anlegen.  
2. **Ohne Einwilligung:** Einwilligung aus → gleiches/neues Foto hochladen → Detail zeigt keinen Detection-Bereich, nur manuelle Personenzuordnung; in Supabase keine neuen `media_face_detections`.  
3. **Widerruf:** Mit vorhandenen Detection-Zeilen Einwilligung deaktivieren → Zeilen in `media_face_detections` für diesen User müssen weg sein.

**Hinweis:** ML Kit läuft auf **Android/iOS**. Auf Web/Desktop ist die Engine ein No-Op (leere Liste); Upload bleibt stabil.
