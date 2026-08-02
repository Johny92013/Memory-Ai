-- Additive: media_people Freigabe + In-App-Benachrichtigungen
-- Keine Tabellen löschen. Manuell im Supabase SQL Editor ausführen.

-- ---------------------------------------------------------------------------
-- media_people erweitern
-- ---------------------------------------------------------------------------
alter table public.media_people
  add column if not exists tagged_profile_id uuid references public.profiles (id) on delete set null,
  add column if not exists tagged_by uuid references public.profiles (id) on delete set null,
  add column if not exists confirmed_at timestamptz,
  add column if not exists rejected_at timestamptz,
  add column if not exists added_to_gallery_at timestamptz;

alter table public.media_people drop constraint if exists media_people_status_check;
alter table public.media_people
  add constraint media_people_status_check
  check (status in (
    'suggested',
    'pending_confirmation',
    'confirmed',
    'rejected',
    'accepted_to_gallery',
    'linked_only'
  ));

alter table public.media_people drop constraint if exists media_people_source_check;
alter table public.media_people
  add constraint media_people_source_check
  check (source in (
    'manual',
    'face_ai',
    'suggestion',
    'face_recognition',
    'family_tag',
    'imported'
  ));

create index if not exists media_people_tagged_profile_status_idx
  on public.media_people (tagged_profile_id, status)
  where tagged_profile_id is not null;

-- ---------------------------------------------------------------------------
-- In-App-Benachrichtigungen (kein Push)
-- ---------------------------------------------------------------------------
create table if not exists public.in_app_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  type text not null default 'person_tag',
  title text not null,
  body text not null,
  payload jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists in_app_notifications_user_unread_idx
  on public.in_app_notifications (user_id, created_at desc)
  where read_at is null;

alter table public.in_app_notifications enable row level security;

drop policy if exists "Users manage own notifications" on public.in_app_notifications;
create policy "Users manage own notifications"
  on public.in_app_notifications for all
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

revoke all on table public.in_app_notifications from anon;
grant select, insert, update, delete on table public.in_app_notifications to authenticated;

-- ---------------------------------------------------------------------------
-- Helper: tagged user may see media_items via own non-rejected tag
-- ---------------------------------------------------------------------------
create or replace function private.can_view_tagged_media(p_media_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.media_people mp
    where mp.media_item_id = p_media_id
      and mp.tagged_profile_id = (select auth.uid())
      and mp.status in (
        'suggested',
        'pending_confirmation',
        'confirmed',
        'accepted_to_gallery',
        'linked_only'
      )
  );
$$;

revoke all on function private.can_view_tagged_media(uuid) from public;

drop policy if exists "Tagged users can view tagged media" on public.media_items;
create policy "Tagged users can view tagged media"
  on public.media_items for select
  to authenticated
  using (private.can_view_tagged_media(id));

-- ---------------------------------------------------------------------------
-- media_people: tagged user darf eigene Zuordnungen lesen/updaten
-- ---------------------------------------------------------------------------
drop policy if exists "Tagged users manage own tags" on public.media_people;
create policy "Tagged users manage own tags"
  on public.media_people for select
  to authenticated
  using (tagged_profile_id = (select auth.uid()));

drop policy if exists "Tagged users update own tag status" on public.media_people;
create policy "Tagged users update own tag status"
  on public.media_people for update
  to authenticated
  using (tagged_profile_id = (select auth.uid()))
  with check (tagged_profile_id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- RPC: Inbox „Aufnahmen mit mir“
-- ---------------------------------------------------------------------------
create or replace function public.list_tagged_media_for_me(p_statuses text[] default null)
returns table (
  tag_id uuid,
  media_id uuid,
  status text,
  source text,
  confidence double precision,
  tagged_by uuid,
  tagged_by_name text,
  created_at timestamptz,
  confirmed_at timestamptz,
  rejected_at timestamptz,
  added_to_gallery_at timestamptz,
  media_type text,
  thumbnail_path text,
  storage_path text,
  taken_at timestamptz,
  location_name text,
  city text,
  country_name text,
  trip_id uuid,
  trip_title text,
  family_id uuid,
  family_name text,
  owner_id uuid,
  owner_name text
)
language sql
security definer
set search_path = public
stable
as $$
  select
    mp.id as tag_id,
    m.id as media_id,
    mp.status,
    mp.source,
    mp.confidence,
    mp.tagged_by,
    coalesce(tagger.display_name, tagger.email, 'Unbekannt') as tagged_by_name,
    mp.created_at,
    mp.confirmed_at,
    mp.rejected_at,
    mp.added_to_gallery_at,
    m.media_type,
    m.thumbnail_path,
    m.storage_path,
    m.taken_at,
    m.location_name,
    m.city,
    m.country_name,
    m.trip_id,
    t.title as trip_title,
    m.family_id,
    f.name as family_name,
    m.owner_id,
    coalesce(owner.display_name, owner.email, 'Unbekannt') as owner_name
  from public.media_people mp
  join public.media_items m on m.id = mp.media_item_id
  left join public.profiles tagger on tagger.id = mp.tagged_by
  left join public.profiles owner on owner.id = m.owner_id
  left join public.trips t on t.id = m.trip_id
  left join public.families f on f.id = m.family_id
  where mp.tagged_profile_id = (select auth.uid())
    and (
      p_statuses is null
      or mp.status = any (p_statuses)
    )
  order by mp.created_at desc;
$$;

revoke all on function public.list_tagged_media_for_me(text[]) from public;
grant execute on function public.list_tagged_media_for_me(text[]) to authenticated;

-- Benachrichtigung beim Taggen (vom Client aufrufbar; insert nur für Ziel-User)
create or replace function public.notify_person_tagged(
  p_tagged_profile_id uuid,
  p_title text,
  p_body text,
  p_payload jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  if p_tagged_profile_id is null or p_tagged_profile_id = (select auth.uid()) then
    return null;
  end if;
  insert into public.in_app_notifications (user_id, type, title, body, payload)
  values (p_tagged_profile_id, 'person_tag', p_title, p_body, coalesce(p_payload, '{}'::jsonb))
  returning id into v_id;
  return v_id;
end;
$$;

revoke all on function public.notify_person_tagged(uuid, text, text, jsonb) from public;
grant execute on function public.notify_person_tagged(uuid, text, text, jsonb) to authenticated;
