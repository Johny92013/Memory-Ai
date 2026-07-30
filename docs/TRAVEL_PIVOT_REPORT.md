# Travel Pivot – Abschlussbericht

Branch: `feature/travel-pivot`  
Datum: 2026-07-30

## 1. Bestandsaufnahme

Vollständige Analyse in [`docs/TRAVEL_PIVOT_INVENTORY.md`](docs/TRAVEL_PIVOT_INVENTORY.md).

**Kurz:** Auth, Profil, Core-Services und Shared UI sind wiederverwendbar. Familie, Stammbaum und Chat bleiben als Zusatzfunktionen. `memories`-Upload ist Legacy bis Umstellung auf `media_items`. Keine Legacy-Dateien gelöscht.

## 2. SQL-Migrationen (erstellt & auf Supabase angewendet)

| Datei | Inhalt |
|-------|--------|
| `supabase/migrations/20260730_travel_pivot_schema.sql` | Tabellen, CHECK-Constraints, Helper, Trigger |
| `supabase/migrations/20260730_travel_pivot_rls.sql` | RLS für alle neuen Tabellen |
| `supabase/migrations/20260730_travel_pivot_storage.sql` | Buckets + Storage-Policies (lokal) |

**Remote angewendet:** `travel_pivot_schema`, `travel_pivot_rls`, `travel_pivot_storage_buckets`, `travel_pivot_storage_policies_photos`

### Neue/erweiterte Tabellen

- `trips`, `trip_members`, `trip_locations`
- `media_items` (owner/trip/family, CHECK auf media_type, metadata_status, location_source)
- `people` (FK `linked_tree_person_id` → `family_tree_people`)
- `media_people` (CHECK source)
- `albums` erweitert (owner_id, trip_id, album_type; family_id optional)
- `album_items` erweitert (media_item_id)

### Helper-Funktionen (private, security definer, search_path=public)

- `is_trip_member`, `has_trip_role`, `can_edit_trip`, `can_upload_to_trip`
- bestehend: `is_family_member`, `is_app_admin`

### media_items RLS-Hierarchie

1. `owner_id` → voller Zugriff  
2. `trip_id` gesetzt → Trip-Mitgliedschaft für Lesen; Editor/Owner für Schreiben  
3. `family_id` gesetzt → zusätzliche Sichtbarkeit für Familienmitglieder (SELECT)  
4. ohne trip_id und family_id → nur Owner

### Storage-Buckets (privat)

`media-photos`, `media-videos`, `media-thumbnails`, `generated-videos`, `people-avatars` (+ bestehend `avatars`)

Pfadkonvention in `lib/core/constants/storage_constants.dart`.

## 3. Flutter-Änderungen

### Neu

- `lib/features/trips/presentation/trips_screen.dart`
- `lib/features/profile/presentation/profile_groups_screen.dart`
- `docs/TRAVEL_PIVOT_INVENTORY.md`
- `scripts/security_isolation_test.ps1`

### Geändert

- `lib/features/home/presentation/main_navigation_screen.dart` – Start · Reisen · Upload · Karte · Profil
- `lib/app/app_router.dart` – keine Familien-Pflicht; Routen `/trips`, `/profile/groups`, `/chat`
- `lib/features/profile/presentation/profile_screen.dart` – Gruppen & Mitglieder, Einstellungen
- `lib/features/home/presentation/home_screen.dart` – Reise-Fokus
- `lib/core/constants/storage_constants.dart` – neue Buckets/Pfade

### Legacy (identifiziert, nicht gelöscht)

- `memories` Tabelle + `MemoriesRepository.uploadFamilyPhoto`
- `family-images` Storage-Bucket
- `MediaItemModel` / `AlbumModel` (alte Flutter-Stubs)
- `/memories/upload` (funktioniert weiter über Legacy-Flow)

## 4. Manuelle Schritte in Supabase (optional)

1. **Storage-Policies:** Restliche Policies aus `20260730_travel_pivot_storage.sql` im SQL-Editor ausführen (videos, thumbnails, generated-videos, people-avatars), falls noch nicht angewendet.
2. **Auth:** Mindest-Passwortlänge nur bei neuen Signups relevant; Demo-User per Migration.
3. **Monitoring:** `get_advisors` in Supabase für RLS/Performance prüfen.

## 5. Sicherheitstest

**Accounts:** A = `admin@memoryai.app`, B = `test@memoryai.app`  
**Skript:** `scripts/security_isolation_test.ps1`

| Prüfung | Ergebnis |
|---------|----------|
| B liest A's `media_items` (privat) | PASS – kein Zugriff |
| B liest A's `trips` | PASS |
| B liest A's `people` | PASS |
| B ändert A's `media_items` | PASS – Titel unverändert |

## 6. Qualität

- `flutter analyze`: **No issues found**
- `dart format .`: 8 Dateien formatiert
- Tests: nicht erneut ausgeführt (keine Test-Änderungen nötig)

## 7. Nächste sinnvolle Schritte

1. Upload-Flow von `memories` auf `media_items` + `media-photos` Bucket
2. Trips-Repository und Reise-Detail-UI
3. Weltkarte an `trip_locations` / `media_items` anbinden
4. Vollständige Storage-Policies für alle neuen Buckets
