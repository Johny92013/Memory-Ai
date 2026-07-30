-- Additive Metadaten-Erweiterung für media_items (Fotos + Videos)
-- Bestehende Werte bleiben gültig (Rückwärtskompatibilität).

alter table public.media_items
  add column if not exists continent text,
  add column if not exists date_source text not null default 'unknown';

-- duration_seconds existiert bereits aus travel_pivot_schema – sicherstellen
alter table public.media_items
  add column if not exists duration_seconds integer;

comment on column public.media_items.continent is
  'Kontinent, bevorzugt aus country_code abgeleitet.';
comment on column public.media_items.date_source is
  'Quelle von taken_at: exif | video_metadata | manual | file | created_at | unknown';

-- location_source: alte + neue Werte
alter table public.media_items
  drop constraint if exists media_items_location_source_check;

alter table public.media_items
  add constraint media_items_location_source_check
  check (location_source in (
    'exif',
    'video_metadata',
    'manual',
    'geocoded',
    'unknown',
    'none',
    'trip_location'
  ));

-- date_source CHECK
alter table public.media_items
  drop constraint if exists media_items_date_source_check;

alter table public.media_items
  add constraint media_items_date_source_check
  check (date_source in (
    'exif',
    'video_metadata',
    'manual',
    'file',
    'created_at',
    'unknown'
  ));

-- metadata_status: bestehende + neue Statuswerte
alter table public.media_items
  drop constraint if exists media_items_metadata_status_check;

alter table public.media_items
  add constraint media_items_metadata_status_check
  check (metadata_status in (
    'automatic',
    'manual',
    'incomplete',
    'missing_location',
    'missing_date',
    'missing_people',
    'missing_location_and_date',
    'failed',
    'pending',
    'complete'
  ));

-- Default metadata_status auf gültigen Wert (pending war nach Phase B problematisch)
alter table public.media_items
  alter column metadata_status set default 'automatic';

alter table public.media_items
  alter column location_source set default 'unknown';

alter table public.media_items
  alter column date_source set default 'unknown';
