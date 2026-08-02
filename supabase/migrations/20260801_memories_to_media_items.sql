-- Phase 3: Legacy memories → media_items, dann stilllegen als memories_deprecated
-- Additive: keine Storage-Dateien löschen, keine memories-Daten hard-droppen.

-- 1) Nutzdaten nach media_items kopieren (gleiche UUID, nur wenn noch nicht vorhanden)
insert into public.media_items (
  id,
  owner_id,
  family_id,
  media_type,
  storage_path,
  taken_at,
  latitude,
  longitude,
  location_name,
  title,
  description,
  location_source,
  date_source,
  metadata_status,
  created_at,
  updated_at
)
select
  m.id,
  m.created_by,
  m.family_id,
  coalesce(nullif(m.media_type, ''), 'image'),
  m.storage_path,
  m.taken_at,
  m.latitude,
  m.longitude,
  m.location_name,
  m.title,
  m.description,
  case
    when m.latitude is not null and m.longitude is not null then 'exif'
    else 'none'
  end,
  case when m.taken_at is not null then 'exif' else 'unknown' end,
  case
    when m.latitude is null or m.longitude is null then 'incomplete'
    else 'automatic'
  end,
  m.created_at,
  coalesce(m.updated_at, m.created_at, now())
from public.memories m
where not exists (
  select 1 from public.media_items mi where mi.id = m.id
)
and not exists (
  select 1
  from public.media_items mi2
  where mi2.storage_path is not null
    and m.storage_path is not null
    and mi2.storage_path = m.storage_path
);

-- 2) Tabelle stilllegen (nicht droppen)
alter table if exists public.memories rename to memories_deprecated;

-- Index-Namen optional mitziehen (falls vorhanden)
do $$
begin
  if exists (
    select 1 from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'memories_family_id_idx'
  ) then
    alter index public.memories_family_id_idx rename to memories_deprecated_family_id_idx;
  end if;
  if exists (
    select 1 from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'memories_created_by_idx'
  ) then
    alter index public.memories_created_by_idx rename to memories_deprecated_created_by_idx;
  end if;
end $$;

comment on table public.memories_deprecated is
  'Legacy family memories table. Migrated to media_items on 2026-08-01. Do not write. Keep for rollback buffer; drop later after confirmation.';

-- 3) Schreibzugriff für App-Rollen auf Legacy-Tabelle entziehen (Lesen bleibt für Admin/Audit möglich)
revoke insert, update, delete on public.memories_deprecated from authenticated;
revoke insert, update, delete on public.memories_deprecated from anon;
