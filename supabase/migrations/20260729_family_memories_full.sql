-- =============================================================================
-- Family Memories AI - Vollmigration (Schema + RLS + Storage)
-- Datum: 2026-07-29
-- Idempotent und kompatibel mit bestehendem profiles/families/family_members.
-- Zum Anwenden via Supabase MCP oder SQL-Editor.
-- =============================================================================

-- =============================================================================
-- Family Memories AI – Schema (Tabellen, Enums, Funktionen, Trigger)
-- Idempotent: mehrfach ausführbar (IF NOT EXISTS / DO-Blöcke).
-- Voraussetzung: profiles, families, family_members und private-Helfer existieren.
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

-- Profile-Trigger (falls noch nicht vorhanden)
drop trigger if exists update_profiles_updated_at on public.profiles;
create trigger update_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists update_families_updated_at on public.families;
create trigger update_families_updated_at
  before update on public.families
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Profil bei neuerem Auth-User anlegen
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
    new.raw_user_meta_data ->> 'first_name',
    new.raw_user_meta_data ->> 'last_name',
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
  insert into public.profiles (id, email, first_name)
  select
    u.id,
    u.email,
    coalesce(
      u.raw_user_meta_data ->> 'first_name',
      u.raw_user_meta_data ->> 'display_name',
      split_part(u.email, '@', 1)
    )
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

create or replace function private.is_family_admin(p_family_id uuid)
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

create or replace function private.can_edit_family_tree(p_family_id uuid)
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

revoke all on function private.ensure_profile(uuid) from public, anon, authenticated;
revoke all on function private.is_family_member(uuid) from public, anon;
revoke all on function private.is_family_admin(uuid) from public, anon;
revoke all on function private.can_edit_family_tree(uuid) from public, anon;

grant execute on function private.is_family_member(uuid) to authenticated, service_role;
grant execute on function private.is_family_admin(uuid) to authenticated, service_role;
grant execute on function private.can_edit_family_tree(uuid) to authenticated, service_role;
grant execute on function private.ensure_profile(uuid) to service_role;

-- ---------------------------------------------------------------------------
-- RPCs: Familie erstellen / beitreten
-- ---------------------------------------------------------------------------
create or replace function public.create_family(p_name text)
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

  insert into public.families (name, invite_code, created_by)
  values (trim(p_name), v_code, v_user)
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

  -- Privilegienrollen beim Beitritt nicht erlauben
  if v_role in (
    'owner'::public.family_role,
    'admin'::public.family_role
  ) then
    v_role := 'member'::public.family_role;
  end if;

  insert into public.family_members (family_id, user_id, role)
  values (v_family.id, v_user, v_role)
  on conflict (family_id, user_id) do nothing;

  return v_family;
end;
$$;

revoke all on function public.create_family(text) from public, anon;
revoke all on function public.join_family(text, public.family_role) from public, anon;
grant execute on function public.create_family(text) to authenticated;
grant execute on function public.join_family(text, public.family_role) to authenticated;

-- ---------------------------------------------------------------------------
-- family_invitations
-- ---------------------------------------------------------------------------
create table if not exists public.family_invitations (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families (id) on delete cascade,
  invited_by uuid not null references auth.users (id) on delete cascade,
  email text,
  invite_code text not null default upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10)),
  role public.family_role not null default 'member'::public.family_role,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'revoked', 'expired')),
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint family_invitations_invite_code_key unique (invite_code)
);

create index if not exists family_invitations_family_id_idx
  on public.family_invitations (family_id);
create index if not exists family_invitations_email_idx
  on public.family_invitations (lower(email));

drop trigger if exists update_family_invitations_updated_at on public.family_invitations;
create trigger update_family_invitations_updated_at
  before update on public.family_invitations
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- family_tree_people (Stammbaum-Personen)
-- ---------------------------------------------------------------------------
create table if not exists public.family_tree_people (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families (id) on delete cascade,
  linked_user_id uuid references auth.users (id) on delete set null,
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

create index if not exists family_tree_people_family_id_idx
  on public.family_tree_people (family_id);
create index if not exists family_tree_people_linked_user_id_idx
  on public.family_tree_people (linked_user_id);

drop trigger if exists update_family_tree_people_updated_at on public.family_tree_people;
create trigger update_family_tree_people_updated_at
  before update on public.family_tree_people
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- family_relationships (+ Spiegel-Helfer)
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

-- Spiegel-Typ: parent <-> child, spouse/sibling/partner/other spiegeln sich selbst
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
  -- Keine Rekursion beim Einfügen des Spiegel-Eintrags
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
create index if not exists memories_taken_at_idx on public.memories (taken_at desc);

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
-- Bestehende Owner-Mitglieder nachziehen (created_by -> owner, falls admin)
-- ---------------------------------------------------------------------------
update public.family_members fm
set role = 'owner'::public.family_role
from public.families f
where f.id = fm.family_id
  and f.created_by = fm.user_id
  and fm.role = 'admin'::public.family_role;


-- =============================================================================
-- Family Memories AI – Row Level Security (RLS) Policies
-- Nutzer sehen nur Daten ihrer Familien; Stammbaum-Schreiben: owner/admin/parent.
-- Idempotent: Policies werden per DROP IF EXISTS neu angelegt.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- RLS aktivieren
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.families enable row level security;
alter table public.family_members enable row level security;
alter table public.family_invitations enable row level security;
alter table public.family_tree_people enable row level security;
alter table public.family_relationships enable row level security;
alter table public.memories enable row level security;
alter table public.albums enable row level security;
alter table public.album_items enable row level security;
alter table public.chat_rooms enable row level security;
alter table public.chat_room_members enable row level security;
alter table public.chat_messages enable row level security;

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------
drop policy if exists "Authenticated users can view profiles" on public.profiles;
drop policy if exists "Users can view own profile" on public.profiles;
drop policy if exists "Users can view family member profiles" on public.profiles;
drop policy if exists "Users can insert own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;

create policy "Users can view own profile"
  on public.profiles for select
  to authenticated
  using ((select auth.uid()) = id);

create policy "Users can view family member profiles"
  on public.profiles for select
  to authenticated
  using (
    exists (
      select 1
      from public.family_members me
      join public.family_members other
        on other.family_id = me.family_id
      where me.user_id = (select auth.uid())
        and other.user_id = profiles.id
    )
  );

create policy "Users can insert own profile"
  on public.profiles for insert
  to authenticated
  with check ((select auth.uid()) = id);

create policy "Users can update own profile"
  on public.profiles for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- ---------------------------------------------------------------------------
-- families
-- ---------------------------------------------------------------------------
drop policy if exists "Members can view their families" on public.families;
drop policy if exists "Authenticated users can create families" on public.families;
drop policy if exists "Admins can update their families" on public.families;
drop policy if exists "Owners and admins can update families" on public.families;
drop policy if exists "Owners can delete families" on public.families;

create policy "Members can view their families"
  on public.families for select
  to authenticated
  using (private.is_family_member(id));

create policy "Authenticated users can create families"
  on public.families for insert
  to authenticated
  with check ((select auth.uid()) = created_by);

create policy "Owners and admins can update families"
  on public.families for update
  to authenticated
  using (private.is_family_admin(id))
  with check (private.is_family_admin(id));

create policy "Owners can delete families"
  on public.families for delete
  to authenticated
  using (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = families.id
        and fm.user_id = (select auth.uid())
        and fm.role = 'owner'::public.family_role
    )
  );

-- ---------------------------------------------------------------------------
-- family_members
-- ---------------------------------------------------------------------------
drop policy if exists "Members can view family members" on public.family_members;
drop policy if exists "Users can join a family as themselves" on public.family_members;
drop policy if exists "Admins can update member roles" on public.family_members;
drop policy if exists "Members can leave or admins can remove" on public.family_members;

create policy "Members can view family members"
  on public.family_members for select
  to authenticated
  using (private.is_family_member(family_id));

create policy "Users can join a family as themselves"
  on public.family_members for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Admins can update member roles"
  on public.family_members for update
  to authenticated
  using (private.is_family_admin(family_id))
  with check (private.is_family_admin(family_id));

create policy "Members can leave or admins can remove"
  on public.family_members for delete
  to authenticated
  using (
    (select auth.uid()) = user_id
    or private.is_family_admin(family_id)
  );

-- ---------------------------------------------------------------------------
-- family_invitations
-- ---------------------------------------------------------------------------
drop policy if exists "Members can view invitations" on public.family_invitations;
drop policy if exists "Admins can create invitations" on public.family_invitations;
drop policy if exists "Admins can update invitations" on public.family_invitations;
drop policy if exists "Admins can delete invitations" on public.family_invitations;

create policy "Members can view invitations"
  on public.family_invitations for select
  to authenticated
  using (private.is_family_member(family_id));

create policy "Admins can create invitations"
  on public.family_invitations for insert
  to authenticated
  with check (
    private.is_family_admin(family_id)
    and (select auth.uid()) = invited_by
    and role not in ('owner'::public.family_role, 'admin'::public.family_role)
  );

create policy "Admins can update invitations"
  on public.family_invitations for update
  to authenticated
  using (private.is_family_admin(family_id))
  with check (private.is_family_admin(family_id));

create policy "Admins can delete invitations"
  on public.family_invitations for delete
  to authenticated
  using (private.is_family_admin(family_id));

-- ---------------------------------------------------------------------------
-- family_tree_people
-- ---------------------------------------------------------------------------
drop policy if exists "Members can view tree people" on public.family_tree_people;
drop policy if exists "Editors can insert tree people" on public.family_tree_people;
drop policy if exists "Editors can update tree people" on public.family_tree_people;
drop policy if exists "Editors can delete tree people" on public.family_tree_people;

create policy "Members can view tree people"
  on public.family_tree_people for select
  to authenticated
  using (private.is_family_member(family_id));

create policy "Editors can insert tree people"
  on public.family_tree_people for insert
  to authenticated
  with check (private.can_edit_family_tree(family_id));

create policy "Editors can update tree people"
  on public.family_tree_people for update
  to authenticated
  using (private.can_edit_family_tree(family_id))
  with check (private.can_edit_family_tree(family_id));

create policy "Editors can delete tree people"
  on public.family_tree_people for delete
  to authenticated
  using (private.can_edit_family_tree(family_id));

-- ---------------------------------------------------------------------------
-- family_relationships
-- ---------------------------------------------------------------------------
drop policy if exists "Members can view relationships" on public.family_relationships;
drop policy if exists "Editors can insert relationships" on public.family_relationships;
drop policy if exists "Editors can update relationships" on public.family_relationships;
drop policy if exists "Editors can delete relationships" on public.family_relationships;

create policy "Members can view relationships"
  on public.family_relationships for select
  to authenticated
  using (private.is_family_member(family_id));

create policy "Editors can insert relationships"
  on public.family_relationships for insert
  to authenticated
  with check (private.can_edit_family_tree(family_id));

create policy "Editors can update relationships"
  on public.family_relationships for update
  to authenticated
  using (private.can_edit_family_tree(family_id))
  with check (private.can_edit_family_tree(family_id));

create policy "Editors can delete relationships"
  on public.family_relationships for delete
  to authenticated
  using (private.can_edit_family_tree(family_id));

-- ---------------------------------------------------------------------------
-- memories
-- ---------------------------------------------------------------------------
drop policy if exists "Members can view memories" on public.memories;
drop policy if exists "Members can insert memories" on public.memories;
drop policy if exists "Authors or admins can update memories" on public.memories;
drop policy if exists "Authors or admins can delete memories" on public.memories;

create policy "Members can view memories"
  on public.memories for select
  to authenticated
  using (private.is_family_member(family_id));

create policy "Members can insert memories"
  on public.memories for insert
  to authenticated
  with check (
    private.is_family_member(family_id)
    and (select auth.uid()) = created_by
  );

create policy "Authors or admins can update memories"
  on public.memories for update
  to authenticated
  using (
    (select auth.uid()) = created_by
    or private.is_family_admin(family_id)
  )
  with check (
    (select auth.uid()) = created_by
    or private.is_family_admin(family_id)
  );

create policy "Authors or admins can delete memories"
  on public.memories for delete
  to authenticated
  using (
    (select auth.uid()) = created_by
    or private.is_family_admin(family_id)
  );

-- ---------------------------------------------------------------------------
-- albums
-- ---------------------------------------------------------------------------
drop policy if exists "Members can view albums" on public.albums;
drop policy if exists "Members can insert albums" on public.albums;
drop policy if exists "Authors or admins can update albums" on public.albums;
drop policy if exists "Authors or admins can delete albums" on public.albums;

create policy "Members can view albums"
  on public.albums for select
  to authenticated
  using (private.is_family_member(family_id));

create policy "Members can insert albums"
  on public.albums for insert
  to authenticated
  with check (
    private.is_family_member(family_id)
    and (select auth.uid()) = created_by
  );

create policy "Authors or admins can update albums"
  on public.albums for update
  to authenticated
  using (
    (select auth.uid()) = created_by
    or private.is_family_admin(family_id)
  )
  with check (
    (select auth.uid()) = created_by
    or private.is_family_admin(family_id)
  );

create policy "Authors or admins can delete albums"
  on public.albums for delete
  to authenticated
  using (
    (select auth.uid()) = created_by
    or private.is_family_admin(family_id)
  );

-- ---------------------------------------------------------------------------
-- album_items
-- ---------------------------------------------------------------------------
drop policy if exists "Members can view album items" on public.album_items;
drop policy if exists "Members can insert album items" on public.album_items;
drop policy if exists "Members can update album items" on public.album_items;
drop policy if exists "Members can delete album items" on public.album_items;

create policy "Members can view album items"
  on public.album_items for select
  to authenticated
  using (
    exists (
      select 1 from public.albums a
      where a.id = album_items.album_id
        and private.is_family_member(a.family_id)
    )
  );

create policy "Members can insert album items"
  on public.album_items for insert
  to authenticated
  with check (
    exists (
      select 1 from public.albums a
      where a.id = album_items.album_id
        and private.is_family_member(a.family_id)
    )
  );

create policy "Members can update album items"
  on public.album_items for update
  to authenticated
  using (
    exists (
      select 1 from public.albums a
      where a.id = album_items.album_id
        and private.is_family_member(a.family_id)
    )
  )
  with check (
    exists (
      select 1 from public.albums a
      where a.id = album_items.album_id
        and private.is_family_member(a.family_id)
    )
  );

create policy "Members can delete album items"
  on public.album_items for delete
  to authenticated
  using (
    exists (
      select 1 from public.albums a
      where a.id = album_items.album_id
        and (
          private.is_family_member(a.family_id)
          and (
            (select auth.uid()) = album_items.added_by
            or private.is_family_admin(a.family_id)
          )
        )
    )
  );

-- ---------------------------------------------------------------------------
-- chat_rooms
-- ---------------------------------------------------------------------------
drop policy if exists "Members can view chat rooms" on public.chat_rooms;
drop policy if exists "Members can create chat rooms" on public.chat_rooms;
drop policy if exists "Admins can update chat rooms" on public.chat_rooms;
drop policy if exists "Admins can delete chat rooms" on public.chat_rooms;

create policy "Members can view chat rooms"
  on public.chat_rooms for select
  to authenticated
  using (private.is_family_member(family_id));

create policy "Members can create chat rooms"
  on public.chat_rooms for insert
  to authenticated
  with check (
    private.is_family_member(family_id)
    and (select auth.uid()) = created_by
  );

create policy "Admins can update chat rooms"
  on public.chat_rooms for update
  to authenticated
  using (private.is_family_admin(family_id))
  with check (private.is_family_admin(family_id));

create policy "Admins can delete chat rooms"
  on public.chat_rooms for delete
  to authenticated
  using (private.is_family_admin(family_id));

-- ---------------------------------------------------------------------------
-- chat_room_members
-- ---------------------------------------------------------------------------
drop policy if exists "Room members can view memberships" on public.chat_room_members;
drop policy if exists "Family members can join rooms" on public.chat_room_members;
drop policy if exists "Users can leave rooms" on public.chat_room_members;

create policy "Room members can view memberships"
  on public.chat_room_members for select
  to authenticated
  using (
    exists (
      select 1 from public.chat_rooms r
      where r.id = chat_room_members.room_id
        and private.is_family_member(r.family_id)
    )
  );

create policy "Family members can join rooms"
  on public.chat_room_members for insert
  to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1 from public.chat_rooms r
      where r.id = chat_room_members.room_id
        and private.is_family_member(r.family_id)
    )
  );

create policy "Users can leave rooms"
  on public.chat_room_members for delete
  to authenticated
  using (
    (select auth.uid()) = user_id
    or exists (
      select 1 from public.chat_rooms r
      where r.id = chat_room_members.room_id
        and private.is_family_admin(r.family_id)
    )
  );

-- ---------------------------------------------------------------------------
-- chat_messages
-- ---------------------------------------------------------------------------
drop policy if exists "Room members can view messages" on public.chat_messages;
drop policy if exists "Room members can send messages" on public.chat_messages;
drop policy if exists "Senders can update own messages" on public.chat_messages;
drop policy if exists "Senders or admins can delete messages" on public.chat_messages;

create policy "Room members can view messages"
  on public.chat_messages for select
  to authenticated
  using (
    private.is_chat_room_member(room_id)
    or exists (
      select 1 from public.chat_rooms r
      where r.id = chat_messages.room_id
        and private.is_family_member(r.family_id)
    )
  );

create policy "Room members can send messages"
  on public.chat_messages for insert
  to authenticated
  with check (
    (select auth.uid()) = sender_id
    and (
      private.is_chat_room_member(room_id)
      or exists (
        select 1 from public.chat_rooms r
        where r.id = chat_messages.room_id
          and private.is_family_member(r.family_id)
      )
    )
  );

create policy "Senders can update own messages"
  on public.chat_messages for update
  to authenticated
  using ((select auth.uid()) = sender_id)
  with check ((select auth.uid()) = sender_id);

create policy "Senders or admins can delete messages"
  on public.chat_messages for delete
  to authenticated
  using (
    (select auth.uid()) = sender_id
    or exists (
      select 1 from public.chat_rooms r
      where r.id = chat_messages.room_id
        and private.is_family_admin(r.family_id)
    )
  );


-- =============================================================================
-- Family Memories AI – Storage Buckets & Policies
-- Private Buckets; Zugriff nur für berechtigte Familienmitglieder.
--
-- Pfadregeln:
--   avatars            → {user_id}/...
--   family-images      → {family_id}/{user_id}/...
--   family-videos      → {family_id}/{user_id}/...
--   family-tree-images → {family_id}/...
--   chat-media         → {family_id}/{room_id}/...
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Private Buckets anlegen
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', false, 5 * 1024 * 1024,
    array['image/jpeg', 'image/png', 'image/webp', 'image/gif']),
  ('family-images', 'family-images', false, 20 * 1024 * 1024,
    array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']),
  ('family-videos', 'family-videos', false, 200 * 1024 * 1024,
    array['video/mp4', 'video/quicktime', 'video/webm']),
  ('family-tree-images', 'family-tree-images', false, 10 * 1024 * 1024,
    array['image/jpeg', 'image/png', 'image/webp']),
  ('chat-media', 'chat-media', false, 50 * 1024 * 1024,
    array['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'video/mp4', 'audio/mpeg', 'audio/mp4'])
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- ---------------------------------------------------------------------------
-- avatars: {user_id}/...
-- ---------------------------------------------------------------------------
drop policy if exists "Users can view own avatar" on storage.objects;
drop policy if exists "Family members can view avatars" on storage.objects;
drop policy if exists "Users can upload own avatar" on storage.objects;
drop policy if exists "Users can update own avatar" on storage.objects;
drop policy if exists "Users can delete own avatar" on storage.objects;

create policy "Users can view own avatar"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Family members can view avatars"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'avatars'
    and exists (
      select 1
      from public.family_members me
      join public.family_members other
        on other.family_id = me.family_id
      where me.user_id = (select auth.uid())
        and other.user_id::text = (storage.foldername(name))[1]
    )
  );

create policy "Users can upload own avatar"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Users can update own avatar"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Users can delete own avatar"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- ---------------------------------------------------------------------------
-- family-images: {family_id}/{user_id}/...
-- ---------------------------------------------------------------------------
drop policy if exists "Members can view family images" on storage.objects;
drop policy if exists "Members can upload family images" on storage.objects;
drop policy if exists "Owners can update family images" on storage.objects;
drop policy if exists "Owners or admins can delete family images" on storage.objects;

create policy "Members can view family images"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'family-images'
    and private.is_family_member(((storage.foldername(name))[1])::uuid)
  );

create policy "Members can upload family images"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'family-images'
    and private.is_family_member(((storage.foldername(name))[1])::uuid)
    and (storage.foldername(name))[2] = (select auth.uid())::text
  );

create policy "Owners can update family images"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'family-images'
    and (
      (storage.foldername(name))[2] = (select auth.uid())::text
      or private.is_family_admin(((storage.foldername(name))[1])::uuid)
    )
  )
  with check (
    bucket_id = 'family-images'
    and (
      (storage.foldername(name))[2] = (select auth.uid())::text
      or private.is_family_admin(((storage.foldername(name))[1])::uuid)
    )
  );

create policy "Owners or admins can delete family images"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'family-images'
    and (
      (storage.foldername(name))[2] = (select auth.uid())::text
      or private.is_family_admin(((storage.foldername(name))[1])::uuid)
    )
  );

-- ---------------------------------------------------------------------------
-- family-videos: {family_id}/{user_id}/...
-- ---------------------------------------------------------------------------
drop policy if exists "Members can view family videos" on storage.objects;
drop policy if exists "Members can upload family videos" on storage.objects;
drop policy if exists "Owners can update family videos" on storage.objects;
drop policy if exists "Owners or admins can delete family videos" on storage.objects;

create policy "Members can view family videos"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'family-videos'
    and private.is_family_member(((storage.foldername(name))[1])::uuid)
  );

create policy "Members can upload family videos"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'family-videos'
    and private.is_family_member(((storage.foldername(name))[1])::uuid)
    and (storage.foldername(name))[2] = (select auth.uid())::text
  );

create policy "Owners can update family videos"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'family-videos'
    and (
      (storage.foldername(name))[2] = (select auth.uid())::text
      or private.is_family_admin(((storage.foldername(name))[1])::uuid)
    )
  )
  with check (
    bucket_id = 'family-videos'
    and (
      (storage.foldername(name))[2] = (select auth.uid())::text
      or private.is_family_admin(((storage.foldername(name))[1])::uuid)
    )
  );

create policy "Owners or admins can delete family videos"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'family-videos'
    and (
      (storage.foldername(name))[2] = (select auth.uid())::text
      or private.is_family_admin(((storage.foldername(name))[1])::uuid)
    )
  );

-- ---------------------------------------------------------------------------
-- family-tree-images: {family_id}/...
-- Lesen: Familienmitglieder | Schreiben: owner/admin/parent
-- ---------------------------------------------------------------------------
drop policy if exists "Members can view tree images" on storage.objects;
drop policy if exists "Editors can upload tree images" on storage.objects;
drop policy if exists "Editors can update tree images" on storage.objects;
drop policy if exists "Editors can delete tree images" on storage.objects;

create policy "Members can view tree images"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'family-tree-images'
    and private.is_family_member(((storage.foldername(name))[1])::uuid)
  );

create policy "Editors can upload tree images"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'family-tree-images'
    and private.can_edit_family_tree(((storage.foldername(name))[1])::uuid)
  );

create policy "Editors can update tree images"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'family-tree-images'
    and private.can_edit_family_tree(((storage.foldername(name))[1])::uuid)
  )
  with check (
    bucket_id = 'family-tree-images'
    and private.can_edit_family_tree(((storage.foldername(name))[1])::uuid)
  );

create policy "Editors can delete tree images"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'family-tree-images'
    and private.can_edit_family_tree(((storage.foldername(name))[1])::uuid)
  );

-- ---------------------------------------------------------------------------
-- chat-media: {family_id}/{room_id}/...
-- ---------------------------------------------------------------------------
drop policy if exists "Room members can view chat media" on storage.objects;
drop policy if exists "Room members can upload chat media" on storage.objects;
drop policy if exists "Uploaders can update chat media" on storage.objects;
drop policy if exists "Uploaders or admins can delete chat media" on storage.objects;

create policy "Room members can view chat media"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'chat-media'
    and private.is_family_member(((storage.foldername(name))[1])::uuid)
  );

create policy "Room members can upload chat media"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'chat-media'
    and private.is_family_member(((storage.foldername(name))[1])::uuid)
  );

create policy "Uploaders can update chat media"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'chat-media'
    and owner = (select auth.uid())
  )
  with check (
    bucket_id = 'chat-media'
    and private.is_chat_room_member(((storage.foldername(name))[2])::uuid)
  );

create policy "Uploaders or admins can delete chat media"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'chat-media'
    and (
      owner = (select auth.uid())
      or private.is_family_admin(((storage.foldername(name))[1])::uuid)
    )
  );
