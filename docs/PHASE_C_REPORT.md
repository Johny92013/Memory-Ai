# Phase C – Reverse-Geocoding & Weltkarte – Abschlussbericht

Branch: `feature/travel-pivot`  
Datum: 2026-07-30

## 1. Ziel

Reverse-Geocoding für GPS-Koordinaten (Nominatim), Hintergrund-Anreicherung von `media_items`, interaktive Weltkarte mit Clustering und Navigation Welt → Land → Stadt → Standort → Fotos.

## 2. Bestandsprüfung (Phase A/B)

- Foto-Upload mit rohen GPS-Koordinaten in `media_items` vorhanden
- `flutter_map` + `latlong2` bereits in `pubspec.yaml`
- `WorldMapScreen` war Stub (nur OSM-Tiles)
- `country_name`/`city` in Phase B angelegt, zunächst leer

## 3. SQL-Migration

| Datei | Inhalt |
|-------|--------|
| `supabase/migrations/20260731_media_items_phase_c.sql` | `country_code`, `region_name` |

**Remote angewendet:** `media_items_phase_c` auf Projekt `bgxijzdycxntctoeeitb`.

## 4. Neu – Location & Geocoding

| Pfad | Zweck |
|------|--------|
| `lib/core/services/location_service.dart` | Koordinaten → Standortdaten |
| `lib/features/map/data/nominatim_service.dart` | Nominatim Reverse API + User-Agent |
| `lib/features/map/data/nominatim_rate_limit_queue.dart` | Warteschlange, ≥1100 ms zwischen Anfragen |
| `lib/features/map/data/location_cache_repository.dart` | Dauerhafter Datei-Cache (gerundete Keys) |
| `lib/features/map/data/coordinate_key.dart` | Rundung / Cache-Schlüssel (4 Dezimalstellen) |
| `lib/features/map/data/location_place_model.dart` | Land, Code, Region, Stadt, Name |
| `lib/features/map/data/media_location_enrichment_service.dart` | Hintergrund-Update `media_items` |
| `lib/features/map/data/map_aggregation_helper.dart` | Länder-/Stadt-Statistik, Clustering |
| `lib/features/map/data/map_repository.dart` | Karten-Daten aus `media_items` |

### Nominatim-Nutzung

- User-Agent: `MemoryAiFamilyApp/1.0 (contact: admin@memoryai.app)`
- Max. 1 Anfrage/s (1100 ms Pause zwischen echten Requests)
- Identische/nahe Koordinaten (4 Dezimalstellen) → eine Anfrage
- Fehler werden abgefangen; Upload bleibt ohne Geocoding erfolgreich

## 5. Neu – Karten-UI

| Pfad | Zweck |
|------|--------|
| `lib/features/map/presentation/world_map_screen.dart` | OSM-Karte, Cluster, Filter, Länderliste |
| `lib/features/map/presentation/country_detail_screen.dart` | Land: Fotos, Reisen, Jahre, Orte |
| `lib/features/map/presentation/location_memories_screen.dart` | Fotos pro Standort/Stadt |
| `lib/features/memories/presentation/assign_location_screen.dart` | Manuelle Ortszuordnung |
| `lib/features/memories/widgets/media_thumbnail_grid.dart` | Wiederverwendetes Foto-Grid |

### Kartenfunktionen

- Marker-Cluster abhängig von Zoomstufe
- Jahresfilter, Medientyp-Filter (Fotos)
- Welt (Länder-Marker) → Land-Detail → Stadt → Standort-Fotos
- Marker-Tap: Standortname, Datum, Vorschau, „Alle Erinnerungen anzeigen“
- Fotos ohne GPS: nicht auf Karte; Galerie mit Filter „Ohne Standort“ + manuelle Zuweisung

## 6. Geändert

- `lib/features/memories/data/media_repository.dart` – GPS-Listen, Location-Update, Hintergrund-Enrichment nach Upload
- `lib/features/memories/data/media_item_model.dart` – `country_code`, `region_name`, `hasGps`
- `lib/features/memories/presentation/media_gallery_screen.dart` – Filter ohne GPS, Ort zuweisen
- `lib/app/app_router.dart` – `/map/country`, erweitert `/map/location`, `/media/assign-location`

## 7. Tests

| Datei | Inhalt |
|-------|--------|
| `test/coordinate_key_test.dart` | Rundung, Cache-Keys |
| `test/nominatim_rate_limit_queue_test.dart` | 1100 ms Pause, Bündelung |

## 8. Manuelle Testanleitung

### 8.1 Nominatim-Cache / Bündelung

1. 10 Fotos mit leicht unterschiedlichen, aber nahen GPS-Koordinaten hochladen (z. B. ±0.00001°).
2. App neu starten oder Karte öffnen (triggert Hintergrund-Enrichment).
3. **Erwartung:** Standortdaten werden ergänzt; dank Cache/Rundung nur **eine** Nominatim-Anfrage pro Koordinaten-Gruppe (Logs/Netzwerk beobachten).

### 8.2 Clustering in einer Stadt

1. Mehrere Fotos am selben Ort hochladen (oder vorhandene nutzen).
2. Tab **Karte** öffnen, in die Stadt hineinzoomen (Zoom ≥ 6).
3. **Erwartung:** Marker clustern mit Zähler-Badge; Tap zeigt Vorschau und „Alle Erinnerungen anzeigen“.

### 8.3 Navigation Welt → Land → Fotos

1. Karte öffnen → Länder-Chips unten oder Länder-Marker (Zoom < 6).
2. Land antippen → `CountryDetailScreen` mit Statistik und häufigen Orten.
3. Stadt antippen → Fotos an diesem Ort.

### 8.4 Foto ohne GPS

1. Galerie → Icon „Ohne Standort“ aktivieren.
2. Foto ohne GPS antippen → Koordinaten eingeben → Speichern.
3. **Erwartung:** Kein Crash; Foto erscheint später auf der Karte (nach Reload/Enrichment).

## 9. Qualität

| Prüfung | Ergebnis |
|---------|----------|
| `flutter analyze` | No issues found |
| `flutter test` | alle Tests bestanden |
| `dart format .` | formatiert |

## 10. Nächste Schritte (Phase D+)

1. Reisevorschlag / automatische Trip-Verknüpfung
2. Karten-Pick für manuelle Ortszuordnung (statt Koordinaten-Eingabe)
3. Offline-Karten-Tiles optional
4. Index auf `country_name` / Geo-Spalten bei großen Datenmengen
