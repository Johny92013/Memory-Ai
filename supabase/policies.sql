-- =============================================================================
-- Family Memories AI – Row Level Security (RLS) Policies
-- Mitglieder sehen nur Daten ihrer Familien; Stammbaum: can_edit_tree;
-- Chat nur für Raummitglieder. Idempotent via DROP POLICY IF EXISTS.
-- Voraussetzung: schema.sql zuerst ausführen.
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
drop policy if exists "App admins can view all profiles" on public.profiles;
drop policy if exists "Users can insert own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;

create policy "App admins can view all profiles"
  on public.profiles for select
  to authenticated
  using (private.is_app_admin());

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
drop policy if exists "App admins can view all families" on public.families;
drop policy if exists "Authenticated users can create families" on public.families;
drop policy if exists "Admins can update their families" on public.families;
drop policy if exists "Owners and admins can update families" on public.families;
drop policy if exists "Managers can update families" on public.families;
drop policy if exists "Owners can delete families" on public.families;

create policy "App admins can view all families"
  on public.families for select
  to authenticated
  using (private.is_app_admin());

create policy "Members can view their families"
  on public.families for select
  to authenticated
  using (private.is_family_member(id));

create policy "Authenticated users can create families"
  on public.families for insert
  to authenticated
  with check ((select auth.uid()) = created_by);

create policy "Managers can update families"
  on public.families for update
  to authenticated
  using (private.is_family_manager(id))
  with check (private.is_family_manager(id));

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
drop policy if exists "App admins can view all family members" on public.family_members;
drop policy if exists "Users can join a family as themselves" on public.family_members;
drop policy if exists "Admins can update member roles" on public.family_members;
drop policy if exists "Managers can update member roles" on public.family_members;
drop policy if exists "Members can leave or admins can remove" on public.family_members;
drop policy if exists "Members can leave or managers can remove" on public.family_members;

create policy "App admins can view all family members"
  on public.family_members for select
  to authenticated
  using (private.is_app_admin());

create policy "Members can view family members"
  on public.family_members for select
  to authenticated
  using (private.is_family_member(family_id));

create policy "Users can join a family as themselves"
  on public.family_members for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Managers can update member roles"
  on public.family_members for update
  to authenticated
  using (private.is_family_manager(family_id))
  with check (private.is_family_manager(family_id));

create policy "Members can leave or managers can remove"
  on public.family_members for delete
  to authenticated
  using (
    (select auth.uid()) = user_id
    or private.is_family_manager(family_id)
  );

-- ---------------------------------------------------------------------------
-- family_invitations
-- ---------------------------------------------------------------------------
drop policy if exists "Members can view invitations" on public.family_invitations;
drop policy if exists "Admins can create invitations" on public.family_invitations;
drop policy if exists "Managers can create invitations" on public.family_invitations;
drop policy if exists "Admins can update invitations" on public.family_invitations;
drop policy if exists "Managers can update invitations" on public.family_invitations;
drop policy if exists "Admins can delete invitations" on public.family_invitations;
drop policy if exists "Managers can delete invitations" on public.family_invitations;

create policy "Members can view invitations"
  on public.family_invitations for select
  to authenticated
  using (private.is_family_member(family_id));

create policy "Managers can create invitations"
  on public.family_invitations for insert
  to authenticated
  with check (
    private.is_family_manager(family_id)
    and (select auth.uid()) = invited_by
    and role not in ('owner'::public.family_role, 'admin'::public.family_role)
  );

create policy "Managers can update invitations"
  on public.family_invitations for update
  to authenticated
  using (private.is_family_manager(family_id))
  with check (private.is_family_manager(family_id));

create policy "Managers can delete invitations"
  on public.family_invitations for delete
  to authenticated
  using (private.is_family_manager(family_id));

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
  with check (private.can_edit_tree(family_id));

create policy "Editors can update tree people"
  on public.family_tree_people for update
  to authenticated
  using (private.can_edit_tree(family_id))
  with check (private.can_edit_tree(family_id));

create policy "Editors can delete tree people"
  on public.family_tree_people for delete
  to authenticated
  using (private.can_edit_tree(family_id));

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
  with check (private.can_edit_tree(family_id));

create policy "Editors can update relationships"
  on public.family_relationships for update
  to authenticated
  using (private.can_edit_tree(family_id))
  with check (private.can_edit_tree(family_id));

create policy "Editors can delete relationships"
  on public.family_relationships for delete
  to authenticated
  using (private.can_edit_tree(family_id));

-- ---------------------------------------------------------------------------
-- memories
-- ---------------------------------------------------------------------------
drop policy if exists "Members can view memories" on public.memories;
drop policy if exists "App admins can view all memories" on public.memories;
drop policy if exists "Members can insert memories" on public.memories;
drop policy if exists "Authors or admins can update memories" on public.memories;
drop policy if exists "Authors or managers can update memories" on public.memories;
drop policy if exists "Authors or admins can delete memories" on public.memories;
drop policy if exists "Authors or managers can delete memories" on public.memories;

create policy "App admins can view all memories"
  on public.memories for select
  to authenticated
  using (private.is_app_admin());

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

create policy "Authors or managers can update memories"
  on public.memories for update
  to authenticated
  using (
    (select auth.uid()) = created_by
    or private.is_family_manager(family_id)
  )
  with check (
    (select auth.uid()) = created_by
    or private.is_family_manager(family_id)
  );

create policy "Authors or managers can delete memories"
  on public.memories for delete
  to authenticated
  using (
    (select auth.uid()) = created_by
    or private.is_family_manager(family_id)
  );

-- ---------------------------------------------------------------------------
-- albums
-- ---------------------------------------------------------------------------
drop policy if exists "Members can view albums" on public.albums;
drop policy if exists "Members can insert albums" on public.albums;
drop policy if exists "Authors or admins can update albums" on public.albums;
drop policy if exists "Authors or managers can update albums" on public.albums;
drop policy if exists "Authors or admins can delete albums" on public.albums;
drop policy if exists "Authors or managers can delete albums" on public.albums;

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

create policy "Authors or managers can update albums"
  on public.albums for update
  to authenticated
  using (
    (select auth.uid()) = created_by
    or private.is_family_manager(family_id)
  )
  with check (
    (select auth.uid()) = created_by
    or private.is_family_manager(family_id)
  );

create policy "Authors or managers can delete albums"
  on public.albums for delete
  to authenticated
  using (
    (select auth.uid()) = created_by
    or private.is_family_manager(family_id)
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
            or private.is_family_manager(a.family_id)
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
drop policy if exists "Managers can update chat rooms" on public.chat_rooms;
drop policy if exists "Admins can delete chat rooms" on public.chat_rooms;
drop policy if exists "Managers can delete chat rooms" on public.chat_rooms;

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

create policy "Managers can update chat rooms"
  on public.chat_rooms for update
  to authenticated
  using (private.is_family_manager(family_id))
  with check (private.is_family_manager(family_id));

create policy "Managers can delete chat rooms"
  on public.chat_rooms for delete
  to authenticated
  using (private.is_family_manager(family_id));

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
        and private.is_family_manager(r.family_id)
    )
  );

-- ---------------------------------------------------------------------------
-- chat_messages – nur Raummitglieder
-- ---------------------------------------------------------------------------
drop policy if exists "Room members can view messages" on public.chat_messages;
drop policy if exists "Room members can send messages" on public.chat_messages;
drop policy if exists "Senders can update own messages" on public.chat_messages;
drop policy if exists "Senders or admins can delete messages" on public.chat_messages;
drop policy if exists "Senders or managers can delete messages" on public.chat_messages;

create policy "Room members can view messages"
  on public.chat_messages for select
  to authenticated
  using (private.is_chat_room_member(room_id));

create policy "Room members can send messages"
  on public.chat_messages for insert
  to authenticated
  with check (
    (select auth.uid()) = sender_id
    and private.is_chat_room_member(room_id)
  );

create policy "Senders can update own messages"
  on public.chat_messages for update
  to authenticated
  using ((select auth.uid()) = sender_id)
  with check ((select auth.uid()) = sender_id);

create policy "Senders or managers can delete messages"
  on public.chat_messages for delete
  to authenticated
  using (
    (select auth.uid()) = sender_id
    or exists (
      select 1 from public.chat_rooms r
      where r.id = chat_messages.room_id
        and private.is_family_manager(r.family_id)
    )
  );
