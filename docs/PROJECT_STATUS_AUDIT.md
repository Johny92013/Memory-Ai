# MemoryAI – Projektstatus-Audit

**Datum:** 2026-07-30  
**Auditor:** Cursor Agent (automatische Tests + Code-/Supabase-Prüfung)  
**Projekt:** MemoryAI / Family Memories (`memory_ai`)

---

## 1. Kurzfazit

Phase A–D (Auth, Upload, Geocoding, Karte, Reisen, Timeline) sind im Code und in der Remote-DB weitgehend vorhanden. Die App startet auf Chrome, Supabase initialisiert sich, `flutter analyze` ist clean, **84 Unit-/Widget-Tests grün**.

Kritische Abweichungen: **kein Git-Repository** im Workspace; Hauptnavigation weicht vom Travel-Pivot-Ziel ab (Chat statt Reisen/Profil in der Bottom-Nav); Medien-Detail und Alben/Chat sind Platzhalter; Legacy-Doppelstrukturen (`memories` vs `media_items`); Security-Advisor-Warnungen (search_path, SECURITY DEFINER für anon).

**Empfohlener nächster Cursor-Auftrag:** Medien-Detailansicht (Ansehen, Metadaten bearbeiten, Löschen) – schließt den zentralen Foto-Kernzyklus.

---

## 2. Aktueller Git-Branch und Git-Status

| Prüfung | Ergebnis |
|---------|----------|
| `.git` vorhanden | **Nein** – `Test-Path .git` = false; `git` meldet „not a git repository“ |
| Branch | **nicht ermittelbar** (kein Git) |
| Uncommitted Changes | **nicht ermittelbar** |
| Docs-Hinweis | `docs/FINAL_PHASE_A_D_REPORT.md` nennt Branch `feature/travel-pivot` – lokal nicht verifizierbar |

**Risiko:** Versionskontrolle fehlt im Arbeitsverzeichnis. Vor weiteren Features `git init` / Repo wiederherstellen.

**Format-Fix in diesem Audit:** `dart format` hat `test/family_invite_route_test.dart` einmal formatiert (Exit-Code 1 beim `--set-exit-if-changed`-Lauf; danach 0).

---

## 3. Erkannte Projektstruktur

```
lib/
  app/          Theme, Router, Farben (AppColors + HomeDashboardColors)
  core/         Supabase, Signed URLs, Location, Errors, Auth-Role
  features/     auth, profile, family, family_tree, memories, map,
                trips, timeline, home, chat, admin, settings
  shared/       UI-Widgets (Button, Card, Boarding-Pass, …)
supabase/
  migrations/   Travel-Pivot + Family-Basis (remote angewendet)
  schema.sql, policies.sql, storage_policies.sql
test/           18 Testdateien, 84 Cases
docs/           Phase-A–D-Reports, Design-System
```

**Stack:** Flutter 3.44.1 · Dart 3.12.1 · supabase_flutter · go_router · flutter_map · google_fonts · exif · image · flutter_dotenv

**Env (nur Key-Namen):** `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` · `.env` in `.gitignore` · `.env` zusätzlich als Flutter-Asset in `pubspec.yaml`

**Supabase Remote:** Projekt `bgxijzdycxntctoeeitb` (eu-central-1, ACTIVE_HEALTHY)  
RLS auf allen geprüften Public-Tabellen aktiv. Datenstand (Stichprobe): profiles 3, media_items 5, trips 4, people 3, memories 3 (Legacy).

---

## 4. Funktionsmatrix

| Modul | Status | Nachweis |
|-------|--------|----------|
| Authentifizierung | weitgehend funktionsfähig | Code + Router-Guards; Start Welcome OK; Login **manuell** |
| Profil | weitgehend funktionsfähig | Screens/Repo vorhanden; **manuell** |
| Hauptnavigation | weitgehend funktionsfähig | Start · Erinnerungen · + · Karte · Chat (weich vom Travel-Ziel) |
| Familie | weitgehend funktionsfähig | Screens + Tests Invite-Route; E2E **manuell** |
| Stammbaum | weitgehend funktionsfähig | Layout-/Relationship-Tests; UI **manuell** |
| Foto-Upload | weitgehend funktionsfähig | MediaRepository + Queue-Tests; Upload **manuell** |
| Galerie | weitgehend funktionsfähig | Lazy Loading vorhanden; Detail stub |
| EXIF / GPS | weitgehend funktionsfähig | Unit-Tests grün |
| Standort / Geocoding | weitgehend funktionsfähig | Nominatim + 1100 ms Queue getestet |
| Weltkarte | weitgehend funktionsfähig | Code + Start-Log (OSM-Warnung) |
| Reisen | weitgehend funktionsfähig | Detection/Rollen-Tests; UI **manuell** |
| Timeline | weitgehend funktionsfähig | Sorting-Tests; UI **manuell** |
| Alben | nur UI-Gerüst / Stub | `listAlbums` → `[]` |
| Personen auf Bildern | nur Datenmodell vorhanden | Tabelle `people`, keine Feature-UI |
| Chat | nur UI-Gerüst | „Phase 6“-Stub |
| Videos / FFmpeg | noch nicht umgesetzt | Bucket vorbereitet |
| KI | noch nicht umgesetzt | – |
| Medien-Detail | nur UI-Gerüst | „Phase 4“-Text |

---

## 5. Automatisch ausgeführte Tests

| Befehl | Ausgeführt | Ergebnis | Details |
|--------|------------|----------|---------|
| `dart format --set-exit-if-changed .` | ja | **fehlgeschlagen (Exit 1)** | 1 Datei formatiert: `test/family_invite_route_test.dart` – **gering** |
| `dart format .` (Nachlauf) | ja | erfolgreich | 0 Änderungen |
| `flutter pub get` | ja | erfolgreich | 9 outdated Hints (nicht blockierend) |
| `flutter analyze` | ja | erfolgreich | No issues found |
| `flutter test` | ja | erfolgreich | **84** Tests bestanden, 0 fehlgeschlagen |
| `flutter devices` | ja | erfolgreich | Windows, Chrome, Edge (kein Android-Emulator) |
| `flutter run -d chrome` | ja | erfolgreich | Welcome-Screen, Supabase init OK |
| `integration_test` | nein | n/a | Ordner fehlt |
| Supabase MCP `list_tables` / `get_advisors` / `list_migrations` | ja | erfolgreich | siehe Abschnitt 10 |

---

## 6. Fehlgeschlagene Tests

- **Nur Format-Check** initial Exit 1 (Auto-Fix durch `dart format`). Keine fehlgeschlagenen Unit-Tests.
- Keine Runtime-Exceptions beim Chrome-Start in der Konsole (außer OSM-Tile-Policy-**Warnung** von flutter_map – mittel, Betriebsempfehlung).

---

## 7. Manuell zu testende Funktionen

1. Registrierung / Login / Logout / Passwort vergessen  
2. Profil vervollständigen und Session-Wiederherstellung  
3. Familie erstellen / Einladung / Beitritt / Stammbaum Zoom-Pan  
4. Foto-Upload (einzeln/mehrfach), EXIF-Korrektur, Fortschritt, Rollback  
5. Galerie: Thumbnails, Signed URLs, Pagination mit echten Daten  
6. Weltkarte: Marker, Cluster, Filter, Länderdetail  
7. Reisen: erstellen, Vorschläge bestätigen, Mitglieder/Rollen  
8. Timeline „Heute vor X Jahren“  
9. Zwei-Konten-Isolation (RLS)  
10. Android-Gerät (hier nicht verfügbar)

---

## 8. Gefundene Fehler / Abweichungen

| # | Schwere | Beschreibung |
|---|---------|--------------|
| 1 | **kritisch (Prozess)** | Kein Git-Repo im Workspace |
| 2 | mittel | Bottom-Nav: Chat statt Reisen/Profil; Dok vs. Code |
| 3 | mittel | Doppelte Medien-Stacks (`memories`/`MediaRepository` vs `media_items`) |
| 4 | mittel | `.env` als Flutter-Asset → landet in Web-Builds |
| 5 | mittel | MediaDetail / Album / Chat nur Platzhalter, aber geroutet |
| 6 | mittel | Security Advisor: mutable `search_path`; anon EXECUTE auf SECURITY DEFINER |
| 7 | mittel | Leaked-Password-Protection in Auth deaktiviert |
| 8 | gering | Zwei Farbsysteme (`AppColors` dunkel + `HomeDashboardColors` hell) |
| 9 | gering | OSM Public-Tile-Usage-Warnung |

---

## 9. Automatisch behobene Fehler

| Datei | Änderung | Begründung |
|-------|----------|------------|
| `test/family_invite_route_test.dart` | `dart format` | Format-Check Exit 1 |

Keine Compile-/Logik-Fixes nötig (`analyze` + `test` grün).

---

## 10. Supabase- und Sicherheitsprüfung

**Migrationen remote (angewendet):** families → family_memories → app_admin → travel_pivot (schema/rls/storage) → media_items B/C → trips_phase_d.

**RLS:** alle gelisteten Public-Tabellen `rls_enabled: true`. Keine pauschalen Read-All-Policies in den Travel-Pivot-Dateien erkannt; Owner-/Trip-/Family-Zugriffe modelliert.

**Storage:** Buckets `media-photos`, `media-videos`, `media-thumbnails`, `generated-videos`, `people-avatars` als `public: false`; Policies an `owner_id`-Pfadsegment.

**Client:** keine `service_role` im Dart-Code gefunden. Signed URLs über `SignedUrlService` mit Cache.

**Advisor (WARN, nicht ERROR):**
- `update_updated_at_column`, `mirror_relationship_type`: search_path mutable  
- anon kann EXECUTE auf `delete_relationship_mirror`, `ensure_trip_owner_member`, `sync_relationship_mirror`  
- authenticated SECURITY DEFINER RPCs (`create_family`, `join_family`, …) – teilweise beabsichtigt, aber härten  
- Auth: Leaked Password Protection aus

**Zwei-Konten-Test:** **nicht durchgeführt** (manuelle Anleitung Abschnitt 17).

---

## 11. Datenschutzrisiken

| Risiko | Stufe |
|--------|-------|
| Private Buckets + Signed URLs | unauffällig bis gering (gutes Muster) |
| `.env` im Asset-Bundle (Web) | **mittel** |
| anon EXECUTE auf SECURITY DEFINER | **mittel–hoch** (Härtung nötig) |
| search_path mutable | mittel |
| Legacy `memories` parallel zu `media_items` | mittel (Verwirrung / falsche Queries) |
| Chat-Stubs ohne Realtime | gering |
| Kein Git → Verlustkontrolle | **hoch** (Prozess) |

---

## 12. Legacy-Dateien und technische Schulden

- `MemoriesRepository` / `MemoryModel` / `UploadMemoryScreen` vs. aktive `MediaRepository`-Pipeline  
- `ImageExifReader` vs. `ExifMetadataService`  
- `HomeDashboardColors` vs. `AppColors` / Design-System  
- Chat-, Album-, MediaDetail-Stubs in der Navigation/Routen  
- Docs beschreiben Nav „Start · Reisen · Upload · Karte · Profil“ – Code anders  

---

## 13. Fortschritt je Modul in Prozent

### A) Technischer Stand des aktuellen Codes

```
Fundament / Architektur     ████████████████░░░░  80 %
Auth / Profil               █████████████████░░░  85 %
Navigation                  ██████████████░░░░░░  70 %
Familie                     ███████████████░░░░░  75 %
Stammbaum                   ██████████████░░░░░░  70 %
Foto-Upload                 ████████████████░░░░  80 %
Galerie                     ██████████████░░░░░░  70 %
EXIF / GPS                  █████████████████░░░  85 %
Standort / Geocoding        ████████████████░░░░  80 %
Weltkarte                   ███████████████░░░░░  75 %
Reisen                      ████████████████░░░░  80 %
Timeline                    ███████████████░░░░░  75 %
Alben                       ████░░░░░░░░░░░░░░░░  20 %
Personen auf Bildern        ███░░░░░░░░░░░░░░░░░  15 %
Gemeinsame Reisen/Mitglieder██████████████░░░░░░  70 %
Chat                        ███░░░░░░░░░░░░░░░░░  15 %
Videos / FFmpeg             █░░░░░░░░░░░░░░░░░░░   5 %
KI-Funktionen               ░░░░░░░░░░░░░░░░░░░░   0 %
Datenschutz / RLS           ██████████████░░░░░░  70 %
Tests / QS                  ███████████░░░░░░░░░  55 %
```

### B) Fortschritt bezogen auf die Produktvision (Reise + Familie + Video + KI)

```
Fundament                   ████████████████░░░░  80 %
Auth / Profil               ████████████████░░░░  80 %
Navigation (Zielbild)       ████████████░░░░░░░░  60 %
Familie                     ███████████████░░░░░  75 %
Stammbaum                   ██████████████░░░░░░  70 %
Foto-Upload                 ███████████████░░░░░  75 %
Galerie                     █████████████░░░░░░░  65 %
EXIF / GPS                  ████████████████░░░░  80 %
Standort / Geocoding        ███████████████░░░░░  75 %
Weltkarte                   ██████████████░░░░░░  70 %
Reisen                      ███████████████░░░░░  75 %
Timeline                    ██████████████░░░░░░  70 %
Alben                       ████░░░░░░░░░░░░░░░░  20 %
Personen                    ███░░░░░░░░░░░░░░░░░  15 %
Gemeinsame Reisen           █████████████░░░░░░░  65 %
Chat                        ███░░░░░░░░░░░░░░░░░  15 %
Videos / FFmpeg             █░░░░░░░░░░░░░░░░░░░   5 %
KI                          ░░░░░░░░░░░░░░░░░░░░   0 %
Datenschutz / RLS           █████████████░░░░░░░  65 %
Tests / QS                  ██████████░░░░░░░░░░  50 %
```

---

## 14. Gesamtfortschritt

| Bezug | Schätzung | Begründung |
|-------|-----------|------------|
| **Aktueller MVP** (Foto + Ort + Reise + Timeline) | **~68 %** | Kernpfad im Code, Unit-Tests, DB; Detail/E2E fehlen |
| **Geplante Reise-App** (MVP + Alben + Personen + stabile Detail-UX) | **~48 %** | Alben/Personen/Detail offen |
| **Langfristige Gesamtvision** (+ Chat + Video + KI) | **~32 %** | Chat stub, kein FFmpeg/KI |

---

## 15. Die fünf wichtigsten nächsten Schritte

1. **Git wiederherstellen** und Branch-Strategie fixieren  
2. **Medien-Detail** (Ansehen, Edit, Delete) – Kernzyklus schließen  
3. **Security-Härtung** (anon EXECUTE revoke, search_path, Auth-Password-Leak)  
4. **`.env` aus Assets entfernen** / Build-sichere Config  
5. **Navigation an Reise-Zielbild angleichen** (Reisen sichtbar; Chat sekundär)  

---

## 16. Detaillierte Roadmap

### Sofort beheben

| Prio | Titel | Begründung | Module | Abhängigkeit | Größe | Risiko | Abnahme |
|------|-------|------------|--------|--------------|-------|--------|---------|
| 1 | Git-Repo wiederherstellen | Keine Historie | Workspace | Backup/Remote | klein | hoch wenn Datenverlust | `git status` zeigt Branch |
| 2 | Advisor: anon EXECUTE revoke | SECURITY DEFINER öffentlich | SQL neu (additive Migration) | Supabase | klein | mittel | Advisor ohne anon-EXECUTE-Warnung |
| 3 | `.env` nicht als Asset | Secrets in Web-Build | `pubspec.yaml`, Config | – | klein | mittel | Web-Build ohne `.env` Asset |

### Nächster sinnvoller Entwicklungsschritt

| Prio | Titel | Begründung | Module | Abhängigkeit | Größe | Risiko | Abnahme |
|------|-------|------------|--------|--------------|-------|--------|---------|
| 4 | **MediaDetailScreen** | Galerie ohne Detail unvollständig | `media_detail_screen`, MediaRepository | Signed URLs | mittel | gering | Foto öffnen, Metadaten, löschen |
| 5 | Nav-Zielbild Travel | Reisen/Profil erreichbar | `main_navigation_screen` | – | klein | gering | Bottom-Nav: Start/Reisen/Upload/Karte/Profil |

### Danach

| Prio | Titel | Module | Größe |
|------|-------|--------|-------|
| 6 | Alben (CRUD + Cover + aus Reise) | memories/albums | groß |
| 7 | Legacy `memories`-Pfad konsolidieren | MemoriesRepository | mittel |
| 8 | Theme vereinheitlichen | AppColors vs HomeDashboard | mittel |
| 9 | Integrationstests Upload+Galerie | integration_test | mittel |
| 10 | Personen-Tagging UI | people/media_people | groß |

### Spätere Erweiterungen

Chat Realtime · FFmpeg Videos · KI · erweiterte Trip-Kollaboration

---

## 17. Konkrete manuelle Testanleitung

### A) App-Start & Auth
1. `flutter run -d chrome` (oder Android)  
2. Welcome → Registrieren → Profil vervollständigen → `/home`  
3. Logout → Login → Session schließen/neu öffnen  

### B) Foto-Kern
1. Plus → Foto(s) hinzufügen → Metadaten prüfen → Hochladen  
2. Erinnerungen/Galerie: Thumbnail sichtbar, Scroll lädt nach  
3. Detail (sobald gebaut): öffnen, bearbeiten, löschen  

### C) Karte & Reise
1. Karte: Marker bei GPS-Fotos; Filter Jahr  
2. Reisen erstellen → Fotos zuordnen → Vorschläge bestätigen  

### D) Zwei-Konten-Sicherheit
1. Account A lädt Foto hoch, notiert ID  
2. Account B: Query/Galerie darf A-Medien nicht sehen  
3. Optional: Storage-URL von A in Browser als B → 403/leer  

### E) Familie (Regression)
1. Familie erstellen, Code teilen, zweites Konto beitreten  
2. Stammbaum: Person + Beziehung, Gegenbeziehung prüfen  

---

## 18. Noch notwendige Supabase-Schritte

1. Additive Migration: `REVOKE EXECUTE … FROM anon` für Trigger-RPCs; `search_path` fixen  
2. Auth: Leaked Password Protection aktivieren (Dashboard)  
3. Prüfen, ob Storage-Policies Trip-Mitglieder-Lesezugriff brauchen (aktuell oft nur Owner-Pfad)  
4. Keine ungeprüften DROP/REWRITE bestehender RLS  

---

## 19. Bekannte Risiken

- Fehlendes Git  
- Doppelte Datenmodelle  
- Stub-Routen wirken „fertig“, sind es nicht  
- Nominatim/OSM Fair-Use  
- Storage-Policies ggf. zu eng für Trip-Sharing von Dateien  
- Web-Build mit Asset-`.env`  

---

## 20. Abschließende Empfehlung für die nächste Cursor-Phase

**Ein einzelner Auftrag:**

> Implementiere die vollständige **Medien-Detailansicht** für `media_items` (Anzeigen mit Signed URL, Metadaten bearbeiten, manuelle Ortszuordnung verknüpfen, Löschen mit Storage-Rollback). Keine neuen Features (keine Alben/Chat/KI). Danach `flutter analyze` + gezielte Tests. Optional parallel: Git-Repo wiederherstellen und anon-EXECUTE härten.

Damit wird der wichtigste Nutzerpfad **Upload → Galerie → Detail** geschlossen, bevor Alben oder Personen folgen.
