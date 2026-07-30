-- App-Admin-Rolle über auth.jwt() app_metadata.app_role = 'admin'
-- Nur für SELECT-Policies (read-only Verwaltung).

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

revoke all on function private.is_app_admin() from public, anon;
grant execute on function private.is_app_admin() to authenticated, service_role;

-- profiles
drop policy if exists "App admins can view all profiles" on public.profiles;
create policy "App admins can view all profiles"
  on public.profiles for select
  to authenticated
  using (private.is_app_admin());

-- families
drop policy if exists "App admins can view all families" on public.families;
create policy "App admins can view all families"
  on public.families for select
  to authenticated
  using (private.is_app_admin());

-- family_members
drop policy if exists "App admins can view all family members" on public.family_members;
create policy "App admins can view all family members"
  on public.family_members for select
  to authenticated
  using (private.is_app_admin());

-- memories
drop policy if exists "App admins can view all memories" on public.memories;
create policy "App admins can view all memories"
  on public.memories for select
  to authenticated
  using (private.is_app_admin());
