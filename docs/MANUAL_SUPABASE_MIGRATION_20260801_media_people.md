# Manuelle Supabase-Migration: Personen-Tags & Benachrichtigungen

## Datei

`supabase/migrations/20260801_media_people_tagged_profile.sql`

## Schritte

1. Supabase Dashboard öffnen → SQL Editor
2. Inhalt der Migrationsdatei einfügen und ausführen
3. Prüfen:
   - Spalten `tagged_profile_id`, `tagged_by`, Timestamps auf `media_people`
   - Tabelle `in_app_notifications`
   - Policies „Tagged users…“ und „Tagged users can view tagged media“
   - Funktionen `list_tagged_media_for_me`, `notify_person_tagged`

## Rollback (Hinweise)

```sql
drop function if exists public.notify_person_tagged(uuid, text, text, jsonb);
drop function if exists public.list_tagged_media_for_me(text[]);
drop policy if exists "Tagged users can view tagged media" on public.media_items;
drop function if exists private.can_view_tagged_media(uuid);
drop policy if exists "Tagged users update own tag status" on public.media_people;
drop policy if exists "Tagged users manage own tags" on public.media_people;
drop table if exists public.in_app_notifications;
-- Spalten auf media_people manuell belassen oder droppen (Datenverlust möglich)
```

Nicht automatisch auf Produktion anwenden.
