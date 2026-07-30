-- Medienverknüpfungen (ohne Gesichtserkennung / ohne Datei-Kopien)
create table if not exists public.media_links (
  id uuid primary key default gen_random_uuid(),
  source_media_id uuid not null references public.media_items(id) on delete cascade,
  related_media_id uuid not null references public.media_items(id) on delete cascade,
  relation_type text not null,
  confidence double precision,
  status text not null default 'suggested',
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  constraint media_links_relation_type_check check (
    relation_type in (
      'same_event',
      'same_moment',
      'duplicate',
      'same_location',
      'same_people',
      'manual'
    )
  ),
  constraint media_links_status_check check (
    status in ('suggested', 'confirmed', 'rejected')
  ),
  constraint media_links_not_self check (source_media_id <> related_media_id),
  constraint media_links_pair_unique unique (source_media_id, related_media_id, relation_type)
);

create index if not exists media_links_source_idx on public.media_links (source_media_id);
create index if not exists media_links_related_idx on public.media_links (related_media_id);
create index if not exists media_links_status_idx on public.media_links (status);

alter table public.media_links enable row level security;

drop policy if exists "Access both media for media_links select" on public.media_links;
drop policy if exists "Creators and media owners manage media_links" on public.media_links;

create policy "Access both media for media_links select"
  on public.media_links for select
  to authenticated
  using (
    exists (
      select 1 from public.media_items s
      where s.id = media_links.source_media_id
        and (
          s.owner_id = (select auth.uid())
          or (s.trip_id is not null and private.is_trip_member(s.trip_id))
          or (s.family_id is not null and private.is_family_member(s.family_id))
        )
    )
    and exists (
      select 1 from public.media_items r
      where r.id = media_links.related_media_id
        and (
          r.owner_id = (select auth.uid())
          or (r.trip_id is not null and private.is_trip_member(r.trip_id))
          or (r.family_id is not null and private.is_family_member(r.family_id))
        )
    )
  );

create policy "Creators and media owners manage media_links"
  on public.media_links for all
  to authenticated
  using (
    created_by = (select auth.uid())
    or exists (
      select 1 from public.media_items s
      where s.id = media_links.source_media_id
        and s.owner_id = (select auth.uid())
    )
  )
  with check (
    created_by = (select auth.uid())
    and exists (
      select 1 from public.media_items s
      where s.id = media_links.source_media_id
        and (
          s.owner_id = (select auth.uid())
          or (s.trip_id is not null and private.can_edit_trip(s.trip_id))
        )
    )
    and exists (
      select 1 from public.media_items r
      where r.id = media_links.related_media_id
        and (
          r.owner_id = (select auth.uid())
          or (r.trip_id is not null and private.is_trip_member(r.trip_id))
          or (r.family_id is not null and private.is_family_member(r.family_id))
        )
    )
  );

grant select, insert, update, delete on public.media_links to authenticated;
