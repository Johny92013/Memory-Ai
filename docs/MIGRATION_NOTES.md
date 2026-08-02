# Migration Notes

## Phase 4 – Face-Consent-Widerruf (2026-08-01)

**Entscheidung:** Option A – bestehende echte Löschlogik belassen.

Production nutzt bereits:

- `MediaFaceDetectionRepository.deleteAllForUser` → `media_face_detections`
- `FaceReferenceRepository.deleteAllForUser` → `face_reference_embeddings`
- `FaceSuggestionStore` → offene `media_people` mit `source = face_recognition` und `status = suggested`

`NoOpFaceRecognitionDataStore` ist nur Test-/Platzhalter, nicht Production-Default.
Consents liegen auf `biometric_consents` (nicht `profiles`).

---

## Phase 3 – memories → media_items (2026-08-01)

**Entscheidung:** Plan A (Nutzdaten retten, Tabelle stilllegen, kein Hard-Drop)

1. **3 Zeilen** aus `public.memories` nach `public.media_items` kopiert  
   (gleiche UUID `id`, `created_by` → `owner_id`, Storage-Pfade unverändert).
2. Tabelle umbenannt: `memories` → **`memories_deprecated`**
3. Schreibrechte für `authenticated`/`anon` auf der Legacy-Tabelle entzogen.
4. App-Code nutzt `media_items` als alleinigen Medien-Hauptpfad.

| Metrik | Wert |
|--------|------|
| `media_items` | 31 (28 + 3 migriert) |
| `memories_deprecated` | 3 (Archiv / Rollback-Puffer) |
| `public.memories` | existiert nicht mehr |

### Feld-Mapping

| memories | media_items |
|----------|-------------|
| id | id |
| created_by | owner_id |
| family_id | family_id |
| media_type | media_type |
| storage_path | storage_path |
| taken_at | taken_at / date_source |
| latitude, longitude | latitude, longitude / location_source |
| title, description, location_name | gleich |

### Code

- `MemoriesRepository` → `media_items`
- `UploadMemoryScreen` → Redirect auf `/memories/upload`
- `AdminRepository.countMemories` → zählt `media_items`

### Später möglich

`DROP TABLE public.memories_deprecated CASCADE` nach Bestätigung.
