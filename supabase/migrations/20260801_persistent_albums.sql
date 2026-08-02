-- Persistente Alben: media_items-Pfad freischalten + Owner-RLS für album_items
-- Additive; keine Datenlöschung.

-- Legacy-FK optional machen (neue Alben nutzen media_item_id)
alter table public.album_items
  alter column memory_id drop not null;

-- Eindeutigkeit für Medien-Pfad
create unique index if not exists album_items_album_media_unique
  on public.album_items (album_id, media_item_id)
  where media_item_id is not null;

-- Cover als Media-Referenz + Layout (clientseitig bisher nur Session)
alter table public.albums
  add column if not exists cover_media_id uuid references public.media_items (id) on delete set null;

alter table public.albums
  add column if not exists layout text not null default 'mixed';

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'albums_layout_check'
  ) then
    alter table public.albums
      add constraint albums_layout_check
      check (layout in ('single', 'doublePage', 'collage', 'mixed'));
  end if;
end $$;

create index if not exists albums_owner_id_idx on public.albums (owner_id)
  where owner_id is not null;
create index if not exists albums_cover_media_id_idx on public.albums (cover_media_id)
  where cover_media_id is not null;

-- Owner darf album_items der eigenen Alben verwalten (Solo/Travel ohne family_id)
drop policy if exists "Owners can manage own album items" on public.album_items;
create policy "Owners can manage own album items"
  on public.album_items for all
  to authenticated
  using (
    exists (
      select 1 from public.albums a
      where a.id = album_items.album_id
        and a.owner_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.albums a
      where a.id = album_items.album_id
        and a.owner_id = (select auth.uid())
    )
  );

-- Trip-Mitglieder dürfen Items von Trip-Alben lesen
drop policy if exists "Trip members can view trip album items" on public.album_items;
create policy "Trip members can view trip album items"
  on public.album_items for select
  to authenticated
  using (
    exists (
      select 1 from public.albums a
      where a.id = album_items.album_id
        and a.trip_id is not null
        and private.is_trip_member(a.trip_id)
    )
  );
