-- Travel Pivot: RLS für trips, media_items, people, trip_*

alter table public.trips enable row level security;
alter table public.trip_members enable row level security;
alter table public.trip_locations enable row level security;
alter table public.media_items enable row level security;
alter table public.people enable row level security;
alter table public.media_people enable row level security;

-- trips
drop policy if exists "Owners can manage their trips" on public.trips;
drop policy if exists "Trip members can view trips" on public.trips;
drop policy if exists "Family members can view shared trips" on public.trips;

create policy "Owners can manage their trips"
  on public.trips for all
  to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create policy "Trip members can view trips"
  on public.trips for select
  to authenticated
  using (private.is_trip_member(id));

create policy "Family members can view shared trips"
  on public.trips for select
  to authenticated
  using (
    family_id is not null
    and private.is_family_member(family_id)
  );

-- trip_members
drop policy if exists "Trip members can view membership" on public.trip_members;
drop policy if exists "Trip owners can manage membership" on public.trip_members;

create policy "Trip members can view membership"
  on public.trip_members for select
  to authenticated
  using (private.is_trip_member(trip_id));

create policy "Trip owners can manage membership"
  on public.trip_members for all
  to authenticated
  using (private.has_trip_role(trip_id, array['owner']))
  with check (private.has_trip_role(trip_id, array['owner']));

-- trip_locations
drop policy if exists "Trip members can view locations" on public.trip_locations;
drop policy if exists "Trip editors can manage locations" on public.trip_locations;

create policy "Trip members can view locations"
  on public.trip_locations for select
  to authenticated
  using (private.is_trip_member(trip_id));

create policy "Trip editors can manage locations"
  on public.trip_locations for all
  to authenticated
  using (private.can_edit_trip(trip_id))
  with check (private.can_edit_trip(trip_id));

-- media_items: owner > trip > family (zusätzlich)
drop policy if exists "Owners full access on media_items" on public.media_items;
drop policy if exists "Trip members can view trip media" on public.media_items;
drop policy if exists "Family members can view shared media" on public.media_items;
drop policy if exists "Owners and trip editors can insert media" on public.media_items;
drop policy if exists "Owners and trip editors can update media" on public.media_items;
drop policy if exists "Owners and trip editors can delete media" on public.media_items;
drop policy if exists "App admins can view all media_items" on public.media_items;

create policy "Owners full access on media_items"
  on public.media_items for all
  to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create policy "Trip members can view trip media"
  on public.media_items for select
  to authenticated
  using (
    trip_id is not null
    and private.is_trip_member(trip_id)
  );

create policy "Family members can view shared media"
  on public.media_items for select
  to authenticated
  using (
    family_id is not null
    and private.is_family_member(family_id)
  );

create policy "Owners and trip editors can insert media"
  on public.media_items for insert
  to authenticated
  with check (
    owner_id = (select auth.uid())
    and (
      trip_id is null
      or private.can_upload_to_trip(trip_id)
    )
  );

create policy "Owners and trip editors can update media"
  on public.media_items for update
  to authenticated
  using (
    owner_id = (select auth.uid())
    or (
      trip_id is not null
      and private.can_edit_trip(trip_id)
    )
  )
  with check (
    owner_id = (select auth.uid())
    or (
      trip_id is not null
      and private.can_edit_trip(trip_id)
    )
  );

create policy "Owners and trip editors can delete media"
  on public.media_items for delete
  to authenticated
  using (
    owner_id = (select auth.uid())
    or (
      trip_id is not null
      and private.can_edit_trip(trip_id)
    )
  );

create policy "App admins can view all media_items"
  on public.media_items for select
  to authenticated
  using (private.is_app_admin());

-- people
drop policy if exists "Owners manage own people" on public.people;
drop policy if exists "App admins can view all people" on public.people;

create policy "Owners manage own people"
  on public.people for all
  to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create policy "App admins can view all people"
  on public.people for select
  to authenticated
  using (private.is_app_admin());

-- media_people (Zugriff über media_item)
drop policy if exists "Media access governs media_people" on public.media_people;

create policy "Media access governs media_people"
  on public.media_people for all
  to authenticated
  using (
    exists (
      select 1 from public.media_items m
      where m.id = media_people.media_item_id
        and (
          m.owner_id = (select auth.uid())
          or (m.trip_id is not null and private.is_trip_member(m.trip_id))
          or (m.family_id is not null and private.is_family_member(m.family_id))
        )
    )
  )
  with check (
    exists (
      select 1 from public.media_items m
      where m.id = media_people.media_item_id
        and (
          m.owner_id = (select auth.uid())
          or (m.trip_id is not null and private.can_edit_trip(m.trip_id))
        )
    )
  );

-- albums: owner + trip + family erweitern (bestehende Policies bleiben)
drop policy if exists "Owners can manage own albums" on public.albums;
drop policy if exists "Trip members can view trip albums" on public.albums;

create policy "Owners can manage own albums"
  on public.albums for all
  to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create policy "Trip members can view trip albums"
  on public.albums for select
  to authenticated
  using (
    trip_id is not null
    and private.is_trip_member(trip_id)
  );
