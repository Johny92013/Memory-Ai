-- Phase D: contributor-Rolle und erweiterte Trip-RLS

alter table public.trip_members drop constraint if exists trip_members_role_check;
alter table public.trip_members
  add constraint trip_members_role_check
  check (role in ('owner', 'editor', 'contributor', 'viewer'));

create or replace function private.can_contribute_to_trip(p_trip_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select private.has_trip_role(
    p_trip_id,
    array['owner', 'editor', 'contributor']
  );
$$;

create or replace function private.can_upload_to_trip(p_trip_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select private.can_contribute_to_trip(p_trip_id);
$$;

create or replace function private.can_edit_trip_media(
  p_trip_id uuid,
  p_media_owner_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select private.can_edit_trip(p_trip_id)
  or (
    private.has_trip_role(p_trip_id, array['contributor'])
    and p_media_owner_id = (select auth.uid())
  );
$$;

revoke all on function private.can_contribute_to_trip(uuid) from public, anon;
revoke all on function private.can_edit_trip_media(uuid, uuid) from public, anon;
grant execute on function private.can_contribute_to_trip(uuid) to authenticated, service_role;
grant execute on function private.can_edit_trip_media(uuid, uuid) to authenticated, service_role;

-- trips: Editoren dürfen Reise bearbeiten
drop policy if exists "Trip editors can update trips" on public.trips;
create policy "Trip editors can update trips"
  on public.trips for update
  to authenticated
  using (private.can_edit_trip(id))
  with check (private.can_edit_trip(id));

-- media_items: Contributor-Upload + eigene Medien bearbeiten
drop policy if exists "Owners and trip editors can insert media" on public.media_items;
drop policy if exists "Owners and trip editors can update media" on public.media_items;
drop policy if exists "Owners and trip editors can delete media" on public.media_items;

create policy "Trip contributors can insert media"
  on public.media_items for insert
  to authenticated
  with check (
    owner_id = (select auth.uid())
    and (
      trip_id is null
      or private.can_upload_to_trip(trip_id)
    )
  );

create policy "Trip roles can update media"
  on public.media_items for update
  to authenticated
  using (
    owner_id = (select auth.uid())
    or (
      trip_id is not null
      and private.can_edit_trip_media(trip_id, owner_id)
    )
  )
  with check (
    owner_id = (select auth.uid())
    or (
      trip_id is not null
      and private.can_edit_trip_media(trip_id, owner_id)
    )
  );

create policy "Trip roles can delete media"
  on public.media_items for delete
  to authenticated
  using (
    owner_id = (select auth.uid())
    or (
      trip_id is not null
      and private.can_edit_trip_media(trip_id, owner_id)
    )
  );
