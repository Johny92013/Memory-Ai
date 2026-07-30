-- Phase B: media_items erweitern für EXIF-JSON und Galerie-Metadaten

alter table public.media_items
  add column if not exists exif_data jsonb,
  add column if not exists country_name text,
  add column if not exists city text,
  add column if not exists width integer,
  add column if not exists height integer,
  add column if not exists altitude double precision;

-- metadata_status: automatic | manual | incomplete
alter table public.media_items drop constraint if exists media_items_metadata_status_check;
update public.media_items
set metadata_status = 'automatic'
where metadata_status in ('pending', 'complete');
update public.media_items
set metadata_status = 'incomplete'
where metadata_status = 'failed';

alter table public.media_items
  add constraint media_items_metadata_status_check
  check (metadata_status in ('automatic', 'manual', 'incomplete'));

-- location_source: none für Fotos ohne GPS
alter table public.media_items drop constraint if exists media_items_location_source_check;
alter table public.media_items
  add constraint media_items_location_source_check
  check (location_source in ('exif', 'manual', 'trip_location', 'unknown', 'none'));
