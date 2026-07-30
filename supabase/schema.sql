-- =============================================================================
-- Family Memories AI – Schema (Tabellen, Enums, Funktionen, Trigger)
-- Idempotent: mehrfach ausführbar (IF NOT EXISTS / DO-Blöcke).
-- Voraussetzung: profiles, families, family_members und private-Helfer existieren.
-- Ausführung: schema.sql → policies.sql → storage_policies.sql
-- =============================================================================

create extension if not exists "pgcrypto";

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to postgres, service_role, authenticated;

-- ---------------------------------------------------------------------------
-- Enum family_role erweitern (owner, member)
-- ---------------------------------------------------------------------------
do $$
begin
  alter type public.family_role add value if not exists 'owner';
exception
  when duplicate_object then null;
  when undefined_object then
    create type public.family_role as enum (
      'owner', 'admin', 'parent', 'child', 'grandparent', 'member'
    );
end;
$$;

do $$
begin
  alter type public.family_role add value if not exists 'member';
exception
  when duplicate_object then null;
end;
$$;

-- ---------------------------------------------------------------------------
-- Bestehende Tabellen erweitern
-- ---------------------------------------------------------------------------
alter table public.profiles
  add column if not exists birth_date date,
  add column if not exists gender text;

alter table public.families
  add column if not exists description text,
  add column if not exists image_path text,
  add column if not exists updated_at timestamptz not null default now();

-- family_members: eindeutige Mitgliedschaft pro Familie
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'family_members_family_id_user_id_key'
      and conrelid = 'public.family_members'::regclass
  ) then
    alter table public.family_members
      add constraint family_members_family_id_user_id_key
      unique (family_id, user_id);
  end if;
exception
  when duplicate_table then null;
end;
$$;

-- ---------------------------------------------------------------------------
-- updated_at-Helfer
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists update_profiles_updated_at on public.profiles;
create trigger update_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists update_families_updated_at on public.families;
create trigger update_families_updated_at
  before update on public.families
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Profil bei neuem Auth-User anlegen (first_name/last_name aus Metadata)
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    email,
    first_name,
    last_name,
    username,
    profile_completed
  )
  values (
    new.id,
    new.email,
    coalesce(
      new.raw_user_meta_data ->> 'first_name',
      new.raw_user_meta_data ->> 'given_name'
    ),
    coalesce(
      new.raw_user_meta_data ->> 'last_name',
      new.raw_user_meta_data ->> 'family_name'
    ),
    null,
    false
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Private Helferfunktionen
-- ---------------------------------------------------------------------------
create or replace function private.ensure_profile(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, first_name, last_name)
  select
    u.id,
    u.email,
    coalesce(
      u.raw_user_meta_data ->> 'first_name',
      u.raw_user_meta_data ->> 'display_name',
      split_part(u.email, '@', 1)
    ),
    u.raw_user_meta_data ->> 'last_name'
  from auth.users u
  where u.id = p_user_id
  on conflict (id) do nothing;
end;
$$;

create or replace function private.is_family_member(p_family_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.family_members fm
    where fm.family_id = p_family_id
      and fm.user_id = (select auth.uid())
  );
$$;

-- owner oder admin
create or replace function private.is_family_manager(p_family_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.family_members fm
    where fm.family_id = p_family_id
      and fm.user_id = (select auth.uid())
      and fm.role in ('owner'::public.family_role, 'admin'::public.family_role)
  );
$$;

-- Alias für bestehende Aufrufer / Policies
create or replace function private.is_family_admin(p_family_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select private.is_family_manager(p_family_id);
$$;

-- owner, admin oder parent – Stammbaum bearbeiten
create or replace function private.can_edit_tree(p_family_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.family_members fm
    where fm.family_id = p_family_id
      and fm.user_id = (select auth.uid())
      and fm.role in (
        'owner'::public.family_role,
        'admin'::public.family_role,
        'parent'::public.family_role
      )
  );
$$;

-- Alias für ältere Skripte
create or replace function private.can_edit_family_tree(p_family_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select private.can_edit_tree(p_family_id);
$$;

-- App-Admin (app_metadata.app_role = admin, nicht user_metadata)
create or replace function private.is_app_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (auth.jwt() -> 'app_metadata' ->> 'app_role') = 'admin',
    false
  );
$$;

revoke all on function private.ensure_profile(uuid) from public, anon, authenticated;
revoke all on function private.is_family_member(uuid) from public, anon;
revoke all on function private.is_family_manager(uuid) from public, anon;
revoke all on function private.is_family_admin(uuid) from public, anon;
revoke all on function private.can_edit_tree(uuid) from public, anon;
revoke all on function private.can_edit_family_tree(uuid) from public, anon;
revoke all on function private.is_app_admin() from public, anon;

grant execute on function private.is_family_member(uuid) to authenticated, service_role;
grant execute on function private.is_family_manager(uuid) to authenticated, service_role;
grant execute on function private.is_family_admin(uuid) to authenticated, service_role;
grant execute on function private.can_edit_tree(uuid) to authenticated, service_role;
grant execute on function private.can_edit_family_tree(uuid) to authenticated, service_role;
grant execute on function private.is_app_admin() to authenticated, service_role;
grant execute on function private.ensure_profile(uuid) to service_role;

-- ---------------------------------------------------------------------------
-- RPCs: Familie erstellen / beitreten
-- ---------------------------------------------------------------------------
drop function if exists public.create_family(text);

create or replace function public.create_family(
  p_name text,
  p_description text default null
)
returns public.families
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user uuid := (select auth.uid());
  v_family public.families;
  v_code text;
begin
  if v_user is null then
    raise exception 'Not authenticated';
  end if;

  if p_name is null or length(trim(p_name)) < 2 then
    raise exception 'Family name too short';
  end if;

  perform private.ensure_profile(v_user);

  v_code := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));

  insert into public.families (name, description, invite_code, created_by)
  values (trim(p_name), nullif(trim(p_description), ''), v_code, v_user)
  returning * into v_family;

  insert into public.family_members (family_id, user_id, role)
  values (v_family.id, v_user, 'owner'::public.family_role);

  return v_family;
end;
$$;

create or replace function public.join_family(
  p_invite_code text,
  p_role public.family_role default 'member'::public.family_role
)
returns public.families
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user uuid := (select auth.uid());
  v_family public.families;
  v_role public.family_role := coalesce(p_role, 'member'::public.family_role);
begin
  if v_user is null then
    raise exception 'Not authenticated';
  end if;

  perform private.ensure_profile(v_user);

  select * into v_family
  from public.families
  where invite_code = upper(trim(p_invite_code));

  if not found then
    raise exception 'Invalid invite code';
  end if;

  -- owner/admin dürfen nicht per Einladungscode vergeben werden
  if v_role in (
    'owner'::public.family_role,
    'admin'::public.family_role
  ) then
    v_role := 'member'::public.family_role;
  end if;

  insert into public.family_members (family_id, user_id, role)
  values (v_family.id, v_user, v_role)
  on conflict (family_id, user_id) do update
    set role = excluded.role;

  return v_family;
end;
$$;

revoke all on function public.create_family(text, text) from public, anon;
revoke all on function public.join_family(text, public.family_role) from public, anon;
grant execute on function public.create_family(text, text) to authenticated;
grant execute on function public.join_family(text, public.family_role) to authenticated;

-- ---------------------------------------------------------------------------
-- family_invitations
-- ---------------------------------------------------------------------------
create table if not exists public.family_invitations (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families (id) on delete cascade,
  email text,
  invite_code text not null default upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10)),
  role public.family_role not null default 'member'::public.family_role,
  invited_by uuid not null references auth.users (id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'revoked', 'expired')),
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  constraint family_invitations_invite_code_key unique (invite_code)
);

create index if not exists family_invitations_family_id_idx
  on public.family_invitations (family_id);
create index if not exists family_invitations_email_idx
  on public.family_invitations (lower(email))
  where email is not null;
create index if not exists family_invitations_status_idx
  on public.family_invitations (status)
  where status = 'pending';

-- Alte updated_at-Spalte/Trigger entfernen (nicht im Zielschema)
drop trigger if exists update_family_invitations_updated_at on public.family_invitations;
alter table public.family_invitations drop column if exists updated_at;

-- ---------------------------------------------------------------------------
-- family_tree_people (Stammbaum-Personen)
-- ---------------------------------------------------------------------------
create table if not exists public.family_tree_people (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families (id) on delete cascade,
  linked_profile_id uuid references public.profiles (id) on delete set null,
  first_name text not null,
  last_name text,
  birth_date date,
  death_date date,
  gender text,
  photo_path text,
  notes text,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Migration: linked_user_id → linked_profile_id (falls ältere Spalte existiert)
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'family_tree_people'
      and column_name = 'linked_user_id'
  ) and not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'family_tree_people'
      and column_name = 'linked_profile_id'
  ) then
    alter table public.family_tree_people
      rename column linked_user_id to linked_profile_id;
  elsif exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'family_tree_people'
      and column_name = 'linked_user_id'
  ) then
    update public.family_tree_people
    set linked_profile_id = linked_user_id
    where linked_profile_id is null and linked_user_id is not null;
    alter table public.family_tree_people drop column if exists linked_user_id;
  end if;
end;
$$;

alter table public.family_tree_people
  add column if not exists linked_profile_id uuid references public.profiles (id) on delete set null;

create index if not exists family_tree_people_family_id_idx
  on public.family_tree_people (family_id);
create index if not exists family_tree_people_linked_profile_id_idx
  on public.family_tree_people (linked_profile_id)
  where linked_profile_id is not null;

drop trigger if exists update_family_tree_people_updated_at on public.family_tree_people;
create trigger update_family_tree_people_updated_at
  before update on public.family_tree_people
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- family_relationships
-- ---------------------------------------------------------------------------
create table if not exists public.family_relationships (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families (id) on delete cascade,
  person_a_id uuid not null references public.family_tree_people (id) on delete cascade,
  person_b_id uuid not null references public.family_tree_people (id) on delete cascade,
  relationship_type text not null
    check (relationship_type in (
      'parent', 'child', 'spouse', 'sibling', 'partner', 'other'
    )),
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  constraint family_relationships_no_self check (person_a_id <> person_b_id),
  constraint family_relationships_unique
    unique (family_id, person_a_id, person_b_id, relationship_type)
);

create index if not exists family_relationships_family_id_idx
  on public.family_relationships (family_id);
create index if not exists family_relationships_person_a_idx
  on public.family_relationships (person_a_id);
create index if not exists family_relationships_person_b_idx
  on public.family_relationships (person_b_id);

-- Spiegel-Typ: parent <-> child
create or replace function public.mirror_relationship_type(p_type text)
returns text
language sql
immutable
as $$
  select case p_type
    when 'parent' then 'child'
    when 'child' then 'parent'
    else p_type
  end;
$$;

create or replace function public.sync_relationship_mirror()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mirror text := public.mirror_relationship_type(new.relationship_type);
begin
  if pg_trigger_depth() > 1 then
    return new;
  end if;

  insert into public.family_relationships (
    family_id, person_a_id, person_b_id, relationship_type, created_by
  )
  values (
    new.family_id, new.person_b_id, new.person_a_id, v_mirror, new.created_by
  )
  on conflict (family_id, person_a_id, person_b_id, relationship_type) do nothing;

  return new;
end;
$$;

create or replace function public.delete_relationship_mirror()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mirror text := public.mirror_relationship_type(old.relationship_type);
begin
  if pg_trigger_depth() > 1 then
    return old;
  end if;

  delete from public.family_relationships
  where family_id = old.family_id
    and person_a_id = old.person_b_id
    and person_b_id = old.person_a_id
    and relationship_type = v_mirror;

  return old;
end;
$$;

drop trigger if exists trg_sync_relationship_mirror on public.family_relationships;
create trigger trg_sync_relationship_mirror
  after insert on public.family_relationships
  for each row execute function public.sync_relationship_mirror();

drop trigger if exists trg_delete_relationship_mirror on public.family_relationships;
create trigger trg_delete_relationship_mirror
  after delete on public.family_relationships
  for each row execute function public.delete_relationship_mirror();

-- ---------------------------------------------------------------------------
-- memories (Erinnerungen / Medien)
-- ---------------------------------------------------------------------------
create table if not exists public.memories (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families (id) on delete cascade,
  created_by uuid not null references auth.users (id) on delete cascade,
  title text,
  description text,
  media_type text not null default 'image'
    check (media_type in ('image', 'video', 'note', 'audio')),
  storage_path text,
  taken_at timestamptz,
  latitude double precision,
  longitude double precision,
  location_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists memories_family_id_idx on public.memories (family_id);
create index if not exists memories_created_by_idx on public.memories (created_by);
create index if not exists memories_taken_at_idx on public.memories (family_id, taken_at desc nulls last);

drop trigger if exists update_memories_updated_at on public.memories;
create trigger update_memories_updated_at
  before update on public.memories
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- albums / album_items
-- ---------------------------------------------------------------------------
create table if not exists public.albums (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families (id) on delete cascade,
  created_by uuid not null references auth.users (id) on delete cascade,
  title text not null,
  description text,
  cover_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists albums_family_id_idx on public.albums (family_id);

drop trigger if exists update_albums_updated_at on public.albums;
create trigger update_albums_updated_at
  before update on public.albums
  for each row execute function public.set_updated_at();

create table if not exists public.album_items (
  id uuid primary key default gen_random_uuid(),
  album_id uuid not null references public.albums (id) on delete cascade,
  memory_id uuid not null references public.memories (id) on delete cascade,
  position integer not null default 0,
  added_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  constraint album_items_unique unique (album_id, memory_id)
);

create index if not exists album_items_album_id_idx on public.album_items (album_id);
create index if not exists album_items_memory_id_idx on public.album_items (memory_id);

-- ---------------------------------------------------------------------------
-- chat_rooms / chat_room_members / chat_messages
-- ---------------------------------------------------------------------------
create table if not exists public.chat_rooms (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families (id) on delete cascade,
  name text not null default 'Familienchat',
  is_group boolean not null default true,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists chat_rooms_family_id_idx on public.chat_rooms (family_id);

drop trigger if exists update_chat_rooms_updated_at on public.chat_rooms;
create trigger update_chat_rooms_updated_at
  before update on public.chat_rooms
  for each row execute function public.set_updated_at();

create table if not exists public.chat_room_members (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.chat_rooms (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  joined_at timestamptz not null default now(),
  constraint chat_room_members_unique unique (room_id, user_id)
);

create index if not exists chat_room_members_room_id_idx
  on public.chat_room_members (room_id);
create index if not exists chat_room_members_user_id_idx
  on public.chat_room_members (user_id);

create or replace function private.is_chat_room_member(p_room_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.chat_room_members crm
    where crm.room_id = p_room_id
      and crm.user_id = (select auth.uid())
  );
$$;

revoke all on function private.is_chat_room_member(uuid) from public, anon;
grant execute on function private.is_chat_room_member(uuid) to authenticated, service_role;

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.chat_rooms (id) on delete cascade,
  sender_id uuid not null references auth.users (id) on delete cascade,
  body text,
  media_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint chat_messages_has_content check (
    body is not null or media_path is not null
  )
);

create index if not exists chat_messages_room_id_created_at_idx
  on public.chat_messages (room_id, created_at desc);

drop trigger if exists update_chat_messages_updated_at on public.chat_messages;
create trigger update_chat_messages_updated_at
  before update on public.chat_messages
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Bestehende Ersteller: admin → owner (Kompatibilität)
-- ---------------------------------------------------------------------------
update public.family_members fm
set role = 'owner'::public.family_role
from public.families f
where f.id = fm.family_id
  and f.created_by = fm.user_id
  and fm.role = 'admin'::public.family_role;
