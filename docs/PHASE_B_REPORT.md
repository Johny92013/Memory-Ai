# Phase B – Foto-Upload & Galerie – Abschlussbericht

Branch: `feature/travel-pivot`  
Datum: 2026-07-30

## 1. Ziel

Produktiver Foto-Upload in `media_items` + private Storage-Buckets (`media-photos`, `media-thumbnails`), EXIF/GPS-Verarbeitung, Mehrfach-Upload mit Warteschlange, Galerie mit Thumbnails. Kein Reverse-Geocoding (Phase C/D).

## 2. Bestandsprüfung (Phase A)

Vor Implementierung geprüft und **nicht doppelt angelegt**:

- Tabellen `media_items`, RLS, Buckets aus `20260730_travel_pivot_*`
- Navigation Start · Reisen · Upload · Karte · Profil
- `SignedUrlService`, `ImageCompressionService`, `MemoryUploadValidator`

## 3. SQL-Migration

| Datei | Inhalt |
|-------|--------|
| `supabase/migrations/20260731_media_items_phase_b.sql` | `exif_data`, `country_name`, `city`, `width`, `height`, `altitude`; `metadata_status` → automatic/manual/incomplete; `location_source` inkl. `none` |

**Remote angewendet:** `media_items_phase_b` auf Projekt `bgxijzdycxntctoeeitb`.

## 4. Flutter – neu

| Pfad | Zweck |
|------|--------|
| `lib/features/memories/data/gps_coordinate_parser.dart` | EXIF-Rational → Dezimal-GPS |
| `lib/features/memories/data/exif_metadata_service.dart` | EXIF lesen, Aufnahmedatum-Priorität |
| `lib/features/memories/data/media_item_model.dart` | Vollständiges `media_items`-Modell |
| `lib/features/memories/data/upload_queue_model.dart` | Warteschlange mit Status pro Datei |
| `lib/features/memories/data/thumbnail_service.dart` | ~400px JPEG-Thumbnails |
| `lib/features/memories/data/media_repository.dart` | Upload mit Storage-Rollback |
| `lib/features/memories/presentation/photo_metadata_screen.dart` | Datum/GPS/Titel bearbeiten |
| `lib/features/memories/presentation/upload_photos_screen.dart` | Mehrfach-Pick, Queue, Upload |
| `lib/features/memories/presentation/media_gallery_screen.dart` | Grid, Lazy Load, Signed URLs |
| `lib/features/memories/presentation/memories_screen.dart` | Galerie-Einstieg |

### Tests

- `test/gps_coordinate_parser_test.dart`
- `test/exif_metadata_service_test.dart`
- `test/media_item_model_test.dart`
- `test/upload_queue_model_test.dart`

## 5. Flutter – geändert

- `lib/app/app_router.dart` – `/memories/upload` → `UploadPhotosScreen`, Route `/media/gallery`
- `lib/core/constants/storage_constants.dart` – Pfad `{owner_id}/{year}/{month}/{media_id}.{ext}`
- `lib/core/services/image_service.dart` – `pickMultipleImages`
- `lib/core/services/signed_url_service.dart` – URLs für Media-Buckets
- `lib/features/home/presentation/home_screen.dart` – „Fotos“ → Galerie

### Upload-Ablauf (implementiert)

1. Bildauswahl (`image_picker`, mehrfach)
2. Lokale Vorschau
3. MIME/Größe via `MemoryUploadValidator`
4. EXIF (DateTimeOriginal, CreateDate, GPS, Orientation, Make, Model, Abmessungen)
5. Aufnahmedatum: DateTimeOriginal → CreateDate → DateModified → manuell → Uploadzeit
6. GPS als Dezimal, `location_source` = `exif` oder `none`
7. Optional `PhotoMetadataScreen` (inkl. „GPS entfernen“)
8. Kompression Ziel ~2 MB (`ImageCompressionService`)
9. Storage `media-photos` + Thumbnail `media-thumbnails`
10. DB-Eintrag `media_items` mit `exif_data` jsonb, `metadata_status`
11. Fortschritt pro Datei und gesamt
12. Bei DB-Fehler: Storage-Dateien wieder löschen

### Nutzerfreundliche Fehlermeldungen

- „Das Foto konnte nicht ausgewählt werden.“
- „Der Upload wurde unterbrochen.“
- „Einige Fotos konnten nicht hochgeladen werden.“

## 6. Manuelle Testanleitung

### 6.1 Screenshot ohne GPS/EXIF

1. App starten, mit `admin` / `admin` anmelden.
2. Tab **Upload** oder Start → **Fotos** → Upload-Button.
3. Screenshot oder WhatsApp-Bild auswählen.
4. **Erwartung:** Kein Absturz; Hinweis „Dieses Foto enthält keine Standortdaten.“; Datum manuell wählbar; Upload erfolgreich.

### 6.2 Foto > 2 MB

1. Große JPEG-Datei (> 2 MB) hochladen.
2. **Erwartung:** Upload erfolgreich; Datei in Storage deutlich kleiner; Galerie zeigt Thumbnail.

### 6.3 Flugmodus / Netzwerkfehler

1. Gerät in Flugmodus oder WLAN trennen.
2. Upload starten.
3. **Erwartung:** Verständliche Meldung (z. B. „Der Upload wurde unterbrochen.“); kein DB-Eintrag ohne Datei; fehlgeschlagene Datei per Retry erneut versuchbar.

### 6.4 Zwei-Konten-Isolation

1. Mit **admin** Fotos hochladen.
2. Abmelden, mit **test** / **test** anmelden.
3. Galerie öffnen.
4. **Erwartung:** Keine Fotos von admin sichtbar.

Alternativ: `scripts/security_isolation_test.ps1` ausführen.

## 7. Sicherheitstest

**Accounts:** A = `admin@memoryai.app`, B = `test@memoryai.app`  
**Skript:** `scripts/security_isolation_test.ps1`

Nach Phase-B-Upload erneut geprüft:

| Prüfung | Ergebnis |
|---------|----------|
| B liest A's `media_items` (privat) | PASS |
| B liest A's `trips` | PASS |
| B liest A's `people` | PASS |
| B ändert A's `media_items` | PASS – Titel unverändert |

## 8. Qualität

| Prüfung | Ergebnis |
|---------|----------|
| `flutter analyze` | No issues found |
| `flutter test` | 43 Tests bestanden (inkl. 4 neue Phase-B-Tests) |
| `dart format .` | formatiert |
| `security_isolation_test.ps1` | PASS (nach Anpassung `metadata_status` → `automatic`) |

## 9. Bewusst nicht in Phase B

- Reverse-Geocoding (`country_name`, `city` leer)
- Reisevorschlag / Trip-Zuordnung automatisch
- Legacy `memories`-Upload (`UploadMemoryScreen`) bleibt im Code, Router nutzt neuen Flow

## 10. Nächste Schritte (Phase C/D)

1. Standort aus GPS (Reverse-Geocoding)
2. Reisevorschlag und Trip-Verknüpfung
3. Trips-Detail mit Medien pro Reise
4. Legacy `memories`-Tabelle deprecaten
