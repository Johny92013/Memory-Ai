-- Phase C: Reverse-Geocoding-Felder für media_items
alter table public.media_items
  add column if not exists country_code text,
  add column if not exists region_name text;
