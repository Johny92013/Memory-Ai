# Manuelle Supabase-Schritte (Phase 1–4 Bugfix)

Führe die SQL-Dateien **nacheinander** im Supabase SQL Editor aus, falls noch nicht angewendet:

1. `supabase/migrations/20260801_media_people_tagged_profile.sql`
2. `supabase/migrations/20260801_trip_companions_and_invites.sql`
3. `supabase/migrations/20260801_tagged_media_storage_read.sql`

Nicht automatisch gegen Produktion ausführen. Keine Tabellen löschen.

## Kurzprüfung nach Migration

```sql
select column_name from information_schema.columns
where table_name = 'media_people'
  and column_name in ('tagged_profile_id','tagged_by','added_to_gallery_at');

select to_regclass('public.in_app_notifications');
select to_regclass('public.trip_companions');
select to_regclass('public.trip_invites');
```
