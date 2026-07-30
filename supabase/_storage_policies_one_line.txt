-- =============================================================================
-- Family Memories AI – Storage Buckets & Policies
--
-- Alle Buckets sind PRIVAT (public = false). Kinderfotos und Familienmedien
-- sind nur für berechtigte Familienmitglieder zugänglich.
--
-- HINWEIS: INSERT INTO storage.buckets erfordert oft die service_role
-- (Supabase SQL Editor → „Run as service role“ oder supabase db execute).
--
-- Pfadkonventionen (erstes Ordnersegment = UUID):
--   avatars            → {user_id}/avatar.webp
--   family-images      → {family_id}/{user_id}/{memory_id}.jpg
--   family-videos      → {family_id}/{user_id}/{memory_id}.mp4
--   family-tree-images → {family_id}/{person_id}.jpg
--   chat-media         → {family_id}/{room_id}/{message_id}.jpg
--
-- Ausführung: Nach schema.sql und policies.sql.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Private Buckets anlegen (idempotent via ON CONFLICT)
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  (
    'avatars',
    'avatars',
    false,
    5 * 1024 * 1024,
    array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
  ),
  (
    'family-images',
    'family-images',
    false,
    20 * 1024 * 1024,
    array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']
  ),
  (
    'family-videos',
    'family-videos',
    false,
    200 * 1024 * 1024,
    array['video/mp4', 'video/quicktime', 'video/webm']
  ),
  (
    'family-tree-images',
    'family-tree-images',
    false,
    10 * 1024 * 1024,
    array['image/jpeg', 'image/png', 'image/webp']
  ),
  (
    'chat-media',
    'chat-media',
    false,
    50 * 1024 * 1024,
    array[
      'image/jpeg', 'image/png', 'image/webp', 'image/gif',
      'video/mp4', 'audio/mpeg', 'audio/mp4', 'audio/webm'
    ]
  )
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- ---------------------------------------------------------------------------
-- avatars: {user_id}/...
-- Eigener Avatar: lesen/schreiben. Familienmitglieder: lesen gegenseitig.
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
-- Lesen: Familienmitglieder | Schreiben: Mitglied im Ordner user_id
-- ---------------------------------------------------------------------------
drop policy if exists "Members can view family images" on storage.objects;
drop policy if exists "Members can upload family images" on storage.objects;
drop policy if exists "Owners can update family images" on storage.objects;
drop policy if exists "Uploaders or managers can update family images" on storage.objects;
drop policy if exists "Owners or admins can delete family images" on storage.objects;
drop policy if exists "Uploaders or managers can delete family images" on storage.objects;

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

create policy "Uploaders or managers can update family images"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'family-images'
    and (
      (storage.foldername(name))[2] = (select auth.uid())::text
      or private.is_family_manager(((storage.foldername(name))[1])::uuid)
    )
  )
  with check (
    bucket_id = 'family-images'
    and (
      (storage.foldername(name))[2] = (select auth.uid())::text
      or private.is_family_manager(((storage.foldername(name))[1])::uuid)
    )
  );

create policy "Uploaders or managers can delete family images"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'family-images'
    and (
      (storage.foldername(name))[2] = (select auth.uid())::text
      or private.is_family_manager(((storage.foldername(name))[1])::uuid)
    )
  );

-- ---------------------------------------------------------------------------
-- family-videos: {family_id}/{user_id}/...
-- ---------------------------------------------------------------------------
drop policy if exists "Members can view family videos" on storage.objects;
drop policy if exists "Members can upload family videos" on storage.objects;
drop policy if exists "Owners can update family videos" on storage.objects;
drop policy if exists "Uploaders or managers can update family videos" on storage.objects;
drop policy if exists "Owners or admins can delete family videos" on storage.objects;
drop policy if exists "Uploaders or managers can delete family videos" on storage.objects;

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

create policy "Uploaders or managers can update family videos"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'family-videos'
    and (
      (storage.foldername(name))[2] = (select auth.uid())::text
      or private.is_family_manager(((storage.foldername(name))[1])::uuid)
    )
  )
  with check (
    bucket_id = 'family-videos'
    and (
      (storage.foldername(name))[2] = (select auth.uid())::text
      or private.is_family_manager(((storage.foldername(name))[1])::uuid)
    )
  );

create policy "Uploaders or managers can delete family videos"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'family-videos'
    and (
      (storage.foldername(name))[2] = (select auth.uid())::text
      or private.is_family_manager(((storage.foldername(name))[1])::uuid)
    )
  );

-- ---------------------------------------------------------------------------
-- family-tree-images: {family_id}/...
-- Lesen: Familienmitglieder | Schreiben: can_edit_tree (owner/admin/parent)
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
    and private.can_edit_tree(((storage.foldername(name))[1])::uuid)
  );

create policy "Editors can update tree images"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'family-tree-images'
    and private.can_edit_tree(((storage.foldername(name))[1])::uuid)
  )
  with check (
    bucket_id = 'family-tree-images'
    and private.can_edit_tree(((storage.foldername(name))[1])::uuid)
  );

create policy "Editors can delete tree images"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'family-tree-images'
    and private.can_edit_tree(((storage.foldername(name))[1])::uuid)
  );

-- ---------------------------------------------------------------------------
-- chat-media: {family_id}/{room_id}/...
-- Lesen/Schreiben: Familienmitglied UND Chat-Raummitglied
-- ---------------------------------------------------------------------------
drop policy if exists "Room members can view chat media" on storage.objects;
drop policy if exists "Room members can upload chat media" on storage.objects;
drop policy if exists "Uploaders can update chat media" on storage.objects;
drop policy if exists "Uploaders or admins can delete chat media" on storage.objects;
drop policy if exists "Uploaders or managers can delete chat media" on storage.objects;

create policy "Room members can view chat media"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'chat-media'
    and private.is_family_member(((storage.foldername(name))[1])::uuid)
    and private.is_chat_room_member(((storage.foldername(name))[2])::uuid)
  );

create policy "Room members can upload chat media"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'chat-media'
    and private.is_family_member(((storage.foldername(name))[1])::uuid)
    and private.is_chat_room_member(((storage.foldername(name))[2])::uuid)
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

create policy "Uploaders or managers can delete chat media"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'chat-media'
    and (
      owner = (select auth.uid())
      or private.is_family_manager(((storage.foldername(name))[1])::uuid)
    )
  );
