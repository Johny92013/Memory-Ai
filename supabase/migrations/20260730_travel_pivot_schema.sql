-- Travel Pivot: trips, media_items, people, erweiterte albums
-- Idempotent. Bestehende memories/family-Struktur bleibt.

-- ---------------------------------------------------------------------------
-- trips
-- ---------------------------------------------------------------------------
create table if not exists public.trips (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  family_id uuid references public.families (id) on delete set null,
  title text not null,
  description text,
  status text not null default 'planning'
    check (status in ('planning', 'active', 'completed', 'archived')),
  start_date date,
  end_date date,
  cover_media_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists trips_owner_id_idx on public.trips (owner_id);
create index if not exists trips_family_id_idx on public.trips (family_id)
  where family_id is not null;
create index if not exists trips_status_idx on public.trips (status);

drop trigger if exists update_trips_updated_at on public.trips;
create trigger update_trips_updated_at
  before update on public.trips
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- trip_members
-- ---------------------------------------------------------------------------
create table if not exists public.trip_members (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null default 'viewer'
    check (role in ('owner', 'editor', 'viewer')),
  invitation_status text not null default 'pending'
    check (invitation_status in ('pending', 'accepted', 'declined', 'revoked')),
  invited_by uuid references auth.users (id) on delete set null,
  joined_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint trip_members_trip_user_key unique (trip_id, user_id)
);

create index if not exists trip_members_trip_id_idx on public.trip_members (trip_id);
create index if not exists trip_members_user_id_idx on public.trip_members (user_id);

drop trigger if exists update_trip_members_updated_at on public.trip_members;
create trigger update_trip_members_updated_at
  before update on public.trip_members
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- trip_locations
-- ---------------------------------------------------------------------------
create table if not exists public.trip_locations (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips (id) on delete cascade,
  name text not null,
  latitude double precision,
  longitude double precision,
  location_source text not null default 'manual'
    check (location_source in ('manual', 'exif', 'search', 'map_pick')),
  visited_at timestamptz,
  order_index integer not null default 0,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists trip_locations_trip_id_idx on public.trip_locations (trip_id);

drop trigger if exists update_trip_locations_updated_at on public.trip_locations;
create trigger update_trip_locations_updated_at
  before update on public.trip_locations
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- media_items
-- ---------------------------------------------------------------------------
create table if not exists public.media_items (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  trip_id uuid references public.trips (id) on delete set null,
  family_id uuid references public.families (id) on delete set null,
  trip_location_id uuid references public.trip_locations (id) on delete set null,
  media_type text not null default 'image'
    check (media_type in ('image', 'video', 'audio', 'note')),
  storage_path text,
  thumbnail_path text,
  mime_type text,
  file_size_bytes bigint,
  taken_at timestamptz,
  latitude double precision,
  longitude double precision,
  location_name text,
  location_source text not null default 'unknown'
    check (location_source in ('exif', 'manual', 'trip_location', 'unknown')),
  metadata_status text not null default 'pending'
    check (metadata_status in ('pending', 'complete', 'failed')),
  title text,
  description text,
  duration_seconds integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists media_items_owner_id_idx on public.media_items (owner_id);
create index if not exists media_items_trip_id_idx on public.media_items (trip_id)
  where trip_id is not null;
create index if not exists media_items_family_id_idx on public.media_items (family_id)
  where family_id is not null;
create index if not exists media_items_taken_at_idx on public.media_items (owner_id, taken_at desc nulls last);

drop trigger if exists update_media_items_updated_at on public.media_items;
create trigger update_media_items_updated_at
  before update on public.media_items
  for each row execute function public.set_updated_at();

-- FK cover_media_id nach media_items
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'trips_cover_media_id_fkey'
  ) then
    alter table public.trips
      add constraint trips_cover_media_id_fkey
      foreign key (cover_media_id) references public.media_items (id) on delete set null;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- people
-- ---------------------------------------------------------------------------
create table if not exists public.people (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  avatar_path text,
  linked_tree_person_id uuid references public.family_tree_people (id) on delete set null,
  detection_source text not null default 'manual'
    check (detection_source in ('manual', 'face_ai', 'import')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists people_owner_id_idx on public.people (owner_id);
create index if not exists people_linked_tree_person_id_idx on public.people (linked_tree_person_id)
  where linked_tree_person_id is not null;

drop trigger if exists update_people_updated_at on public.people;
create trigger update_people_updated_at
  before update on public.people
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- media_people
-- ---------------------------------------------------------------------------
create table if not exists public.media_people (
  id uuid primary key default gen_random_uuid(),
  media_item_id uuid not null references public.media_items (id) on delete cascade,
  person_id uuid not null references public.people (id) on delete cascade,
  source text not null default 'manual'
    check (source in ('manual', 'face_ai', 'suggestion')),
  confidence double precision,
  created_at timestamptz not null default now(),
  constraint media_people_media_person_key unique (media_item_id, person_id)
);

create index if not exists media_people_media_item_id_idx on public.media_people (media_item_id);
create index if not exists media_people_person_id_idx on public.media_people (person_id);

-- ---------------------------------------------------------------------------
-- albums erweitern (bestehende Tabelle)
-- ---------------------------------------------------------------------------
alter table public.albums
  add column if not exists owner_id uuid references auth.users (id) on delete cascade,
  add column if not exists trip_id uuid references public.trips (id) on delete set null,
  add column if not exists album_type text not null default 'manual';

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'albums_album_type_check'
  ) then
    alter table public.albums
      add constraint albums_album_type_check
      check (album_type in ('manual', 'auto_date', 'auto_location', 'auto_trip', 'smart'));
  end if;
end $$;

-- family_id optional für Solo-Nutzer
alter table public.albums alter column family_id drop not null;

update public.albums
set owner_id = created_by
where owner_id is null;

-- ---------------------------------------------------------------------------
-- album_items erweitern
-- ---------------------------------------------------------------------------
alter table public.album_items
  add column if not exists media_item_id uuid references public.media_items (id) on delete cascade;

create index if not exists album_items_media_item_id_idx on public.album_items (media_item_id)
  where media_item_id is not null;

-- ---------------------------------------------------------------------------
-- Trip-Helferfunktionen
-- ---------------------------------------------------------------------------
create or replace function private.is_trip_member(p_trip_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.trips t
    where t.id = p_trip_id
      and t.owner_id = (select auth.uid())
  )
  or exists (
    select 1
    from public.trip_members tm
    where tm.trip_id = p_trip_id
      and tm.user_id = (select auth.uid())
      and tm.invitation_status = 'accepted'
  );
$$;

create or replace function private.has_trip_role(p_trip_id uuid, p_roles text[])
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.trips t
    where t.id = p_trip_id
      and t.owner_id = (select auth.uid())
      and 'owner' = any(p_roles)
  )
  or exists (
    select 1
    from public.trip_members tm
    where tm.trip_id = p_trip_id
      and tm.user_id = (select auth.uid())
      and tm.invitation_status = 'accepted'
      and tm.role = any(p_roles)
  );
$$;

create or replace function private.can_edit_trip(p_trip_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select private.has_trip_role(p_trip_id, array['owner', 'editor']);
$$;

create or replace function private.can_upload_to_trip(p_trip_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select private.can_edit_trip(p_trip_id);
$$;

revoke all on function private.is_trip_member(uuid) from public, anon;
revoke all on function private.has_trip_role(uuid, text[]) from public, anon;
revoke all on function private.can_edit_trip(uuid) from public, anon;
revoke all on function private.can_upload_to_trip(uuid) from public, anon;

grant execute on function private.is_trip_member(uuid) to authenticated, service_role;
grant execute on function private.has_trip_role(uuid, text[]) to authenticated, service_role;
grant execute on function private.can_edit_trip(uuid) to authenticated, service_role;
grant execute on function private.can_upload_to_trip(uuid) to authenticated, service_role;

-- Owner als trip_member beim Erstellen
create or replace function public.ensure_trip_owner_member()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.trip_members (trip_id, user_id, role, invitation_status, joined_at)
  values (new.id, new.owner_id, 'owner', 'accepted', now())
  on conflict (trip_id, user_id) do update
    set role = 'owner',
        invitation_status = 'accepted',
        joined_at = coalesce(trip_members.joined_at, now());
  return new;
end;
$$;

drop trigger if exists trg_ensure_trip_owner_member on public.trips;
create trigger trg_ensure_trip_owner_member
  after insert on public.trips
  for each row execute function public.ensure_trip_owner_member();
