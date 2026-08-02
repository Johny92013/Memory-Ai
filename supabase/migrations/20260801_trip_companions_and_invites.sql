-- Phase 4: Mitreisende ohne Account (companions) + Einladungs-Codes
-- Additive. Bestehende Tabellen werden nicht gelöscht.
-- trip_members.invitation_status bleibt Quelle für E-Mail-/User-Einladungen (pending).

-- ---------------------------------------------------------------------------
-- trip_companions (Mitreisende ohne Login)
-- ---------------------------------------------------------------------------
create table if not exists public.trip_companions (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips (id) on delete cascade,
  display_name text not null,
  notes text,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  constraint trip_companions_display_name_not_blank
    check (char_length(trim(display_name)) > 0)
);

create index if not exists trip_companions_trip_id_idx
  on public.trip_companions (trip_id);

alter table public.trip_companions enable row level security;

drop policy if exists "Trip members can view companions" on public.trip_companions;
drop policy if exists "Trip editors can manage companions" on public.trip_companions;

create policy "Trip members can view companions"
  on public.trip_companions for select
  to authenticated
  using (private.is_trip_member(trip_id));

create policy "Trip editors can manage companions"
  on public.trip_companions for all
  to authenticated
  using (private.can_edit_trip(trip_id))
  with check (private.can_edit_trip(trip_id));

grant select, insert, update, delete on table public.trip_companions to authenticated;

-- ---------------------------------------------------------------------------
-- trip_invites (optionale Share-Codes; Mitgliedschaft weiter über trip_members)
-- ---------------------------------------------------------------------------
create table if not exists public.trip_invites (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips (id) on delete cascade,
  code text not null,
  role text not null default 'viewer'
    check (role in ('editor', 'contributor', 'viewer')),
  created_by uuid references auth.users (id) on delete set null,
  expires_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  constraint trip_invites_code_unique unique (code),
  constraint trip_invites_code_not_blank
    check (char_length(trim(code)) >= 6)
);

create index if not exists trip_invites_trip_id_idx
  on public.trip_invites (trip_id);
create index if not exists trip_invites_code_idx
  on public.trip_invites (code)
  where revoked_at is null;

alter table public.trip_invites enable row level security;

drop policy if exists "Trip members can view invites" on public.trip_invites;
drop policy if exists "Trip owners can manage invites" on public.trip_invites;

create policy "Trip members can view invites"
  on public.trip_invites for select
  to authenticated
  using (private.is_trip_member(trip_id));

create policy "Trip owners can manage invites"
  on public.trip_invites for all
  to authenticated
  using (private.has_trip_role(trip_id, array['owner']))
  with check (private.has_trip_role(trip_id, array['owner']));

grant select, insert, update, delete on table public.trip_invites to authenticated;

-- ---------------------------------------------------------------------------
-- trip_members: eigene pending-Zeilen sehen / annehmen / ablehnen
-- ---------------------------------------------------------------------------
drop policy if exists "Users can view own membership" on public.trip_members;
create policy "Users can view own membership"
  on public.trip_members for select
  to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists "Users can update own pending invite" on public.trip_members;
create policy "Users can update own pending invite"
  on public.trip_members for update
  to authenticated
  using (
    user_id = (select auth.uid())
    and invitation_status = 'pending'
  )
  with check (
    user_id = (select auth.uid())
    and invitation_status in ('accepted', 'declined')
  );

-- Pending-Eingeladene dürfen die Reise sehen (Titel etc.)
drop policy if exists "Pending invitees can view invited trips" on public.trips;
create policy "Pending invitees can view invited trips"
  on public.trips for select
  to authenticated
  using (
    exists (
      select 1
      from public.trip_members tm
      where tm.trip_id = trips.id
        and tm.user_id = (select auth.uid())
        and tm.invitation_status = 'pending'
    )
  );

-- Einladungscode einlösen → trip_members pending (Owner legt Codes an)
create or replace function public.redeem_trip_invite(p_code text)
returns public.trip_members
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := (select auth.uid());
  v_invite public.trip_invites%rowtype;
  v_member public.trip_members%rowtype;
begin
  if v_user is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_invite
  from public.trip_invites
  where upper(trim(code)) = upper(trim(p_code))
    and revoked_at is null
    and (expires_at is null or expires_at > now())
  limit 1;

  if not found then
    raise exception 'Invalid or expired invite code';
  end if;

  insert into public.trip_members (
    trip_id, user_id, role, invitation_status, invited_by
  )
  values (
    v_invite.trip_id,
    v_user,
    v_invite.role,
    'pending',
    v_invite.created_by
  )
  on conflict (trip_id, user_id) do update
    set role = excluded.role,
        invitation_status = case
          when trip_members.invitation_status = 'accepted' then 'accepted'
          else 'pending'
        end,
        invited_by = coalesce(excluded.invited_by, trip_members.invited_by)
  returning * into v_member;

  return v_member;
end;
$$;

revoke all on function public.redeem_trip_invite(text) from public, anon;
grant execute on function public.redeem_trip_invite(text) to authenticated, service_role;
