-- Travel Pivot: private Storage-Buckets + Policies
-- Pfade: owner_id als erstes Segment (UUID)

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  (
    'media-photos',
    'media-photos',
    false,
    20 * 1024 * 1024,
    array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']
  ),
  (
    'media-videos',
    'media-videos',
    false,
    200 * 1024 * 1024,
    array['video/mp4', 'video/quicktime', 'video/webm']
  ),
  (
    'media-thumbnails',
    'media-thumbnails',
    false,
    5 * 1024 * 1024,
    array['image/jpeg', 'image/png', 'image/webp']
  ),
  (
    'generated-videos',
    'generated-videos',
    false,
    500 * 1024 * 1024,
    array['video/mp4', 'video/webm']
  ),
  (
    'people-avatars',
    'people-avatars',
    false,
    5 * 1024 * 1024,
    array['image/jpeg', 'image/png', 'image/webp']
  )
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- media-photos: {owner_id}/{media_item_id}.{ext}
drop policy if exists "Owners can read own media photos" on storage.objects;
drop policy if exists "Owners can upload media photos" on storage.objects;
drop policy if exists "Owners can update media photos" on storage.objects;
drop policy if exists "Owners can delete media photos" on storage.objects;

create policy "Owners can read own media photos"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'media-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Owners can upload media photos"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'media-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Owners can update media photos"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'media-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'media-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Owners can delete media photos"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'media-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- media-videos: {owner_id}/{media_item_id}.{ext}
drop policy if exists "Owners can read own media videos" on storage.objects;
drop policy if exists "Owners can upload media videos" on storage.objects;
drop policy if exists "Owners can update media videos" on storage.objects;
drop policy if exists "Owners can delete media videos" on storage.objects;

create policy "Owners can read own media videos"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'media-videos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Owners can upload media videos"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'media-videos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Owners can update media videos"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'media-videos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'media-videos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Owners can delete media videos"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'media-videos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- media-thumbnails: {owner_id}/{media_item_id}_thumb.{ext}
drop policy if exists "Owners can read own media thumbnails" on storage.objects;
drop policy if exists "Owners can upload media thumbnails" on storage.objects;
drop policy if exists "Owners can update media thumbnails" on storage.objects;
drop policy if exists "Owners can delete media thumbnails" on storage.objects;

create policy "Owners can read own media thumbnails"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'media-thumbnails'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Owners can upload media thumbnails"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'media-thumbnails'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Owners can update media thumbnails"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'media-thumbnails'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'media-thumbnails'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Owners can delete media thumbnails"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'media-thumbnails'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- generated-videos: {owner_id}/{trip_id}/{file_id}.{ext}
drop policy if exists "Owners can read generated videos" on storage.objects;
drop policy if exists "Owners can upload generated videos" on storage.objects;
drop policy if exists "Owners can update generated videos" on storage.objects;
drop policy if exists "Owners can delete generated videos" on storage.objects;

create policy "Owners can read generated videos"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'generated-videos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Owners can upload generated videos"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'generated-videos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Owners can update generated videos"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'generated-videos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'generated-videos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Owners can delete generated videos"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'generated-videos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- people-avatars: {owner_id}/{person_id}.{ext}
drop policy if exists "Owners can read people avatars" on storage.objects;
drop policy if exists "Owners can upload people avatars" on storage.objects;
drop policy if exists "Owners can update people avatars" on storage.objects;
drop policy if exists "Owners can delete people avatars" on storage.objects;

create policy "Owners can read people avatars"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'people-avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Owners can upload people avatars"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'people-avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Owners can update people avatars"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'people-avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'people-avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Owners can delete people avatars"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'people-avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
