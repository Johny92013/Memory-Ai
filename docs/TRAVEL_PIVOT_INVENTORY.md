# Travel Pivot – Bestandsaufnahme (Schritt 1)

Stand: Branch `feature/travel-pivot`. Keine Codeänderung in diesem Schritt – nur Analyse.

## Ordnerstruktur (lib/)

| Bereich | Pfad | Status |
|---------|------|--------|
| App-Shell | `lib/app/` (router, theme, colors) | Wiederverwendbar |
| Core | `lib/core/` (config, services, errors, utils, auth) | Wiederverwendbar |
| Auth | `lib/features/auth/` | Fertig, wiederverwendbar |
| Profil | `lib/features/profile/` | Wiederverwendbar |
| Familie | `lib/features/family/` | Zusatzfunktion, bleibt |
| Stammbaum | `lib/features/family_tree/` | Zusatzfunktion, bleibt |
| Erinnerungen | `lib/features/memories/` | Teilweise Legacy (`memories`-Tabelle); Modelle für `media_items` erweitern |
| Karte | `lib/features/map/` | Wiederverwendbar (Datenquelle später `trip_locations` / `media_items`) |
| Chat | `lib/features/chat/` | Zusatzfunktion, aus Hauptnav raus |
| Home | `lib/features/home/` | Anpassen (Reise-Fokus) |
| Admin | `lib/features/admin/` | Bleibt (App-Admin) |
| Settings | `lib/features/settings/` | Wiederverwendbar |
| Shared UI | `lib/shared/widgets/` | Wiederverwendbar |

## Supabase (bestehend)

**Tabellen (live):** `profiles`, `families`, `family_members`, `family_invitations`, `family_tree_people`, `family_relationships`, `memories`, `albums`, `album_items`, `chat_*`

**Helfer (private):** `is_family_member`, `is_family_manager`, `is_family_admin`, `can_edit_tree`, `is_app_admin`

**Storage (privat):** `avatars`, `family-images`, `family-videos`, `family-tree-images`, `chat-media`

## Wiederverwendbar

- Auth-Flow, Profil, Familie, Stammbaum, Chat-Repositories
- `go_router` + `AuthRefreshListenable`
- Upload-Pipeline (EXIF, Kompression) – später auf `media_items` umstellen
- RLS-Muster (`private.*` security definer)
- `SignedUrlService`, `ImageService`

## Legacy (nicht löschen, schrittweise)

- `public.memories` + `MemoriesRepository.uploadFamilyPhoto` (bleibt bis Medien-Migration)
- `MediaItemModel` / `AlbumModel` (Flutter-Stubs, Phase-4-Platzhalter-Screens)
- `family-images` Bucket (parallel zu `media-photos`)
- Router-Pfade `/memories/*` (Upload bleibt, Galerie folgt)

## Neu in diesem Pivot

- Tabellen: `trips`, `trip_locations`, `trip_members`, `media_items`, `people`, `media_people`; `albums`/`album_items` erweitert
- Buckets: `media-photos`, `media-videos`, `media-thumbnails`, `generated-videos`, `people-avatars`
- Navigation: Start · Reisen · Upload · Karte · Profil
- Keine Familien-Pflicht im Router

## Risiken (vermieden)

- Keine doppelten Auth-/Profil-Repositories
- Bestehende RLS für Familie/Chat nicht entfernt, nur ergänzt
- `memories` bleibt für bestehende Uploads
