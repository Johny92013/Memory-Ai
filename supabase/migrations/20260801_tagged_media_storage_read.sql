-- Additive: Storage-Lesezugriff für markierte Nutzer (keine Dateikopie).
-- Manuell im Supabase SQL Editor ausführen.
-- Voraussetzung: 20260801_media_people_tagged_profile.sql bereits angewendet.

-- media-photos
drop policy if exists "Tagged users can read tagged media photos" on storage.objects;
create policy "Tagged users can read tagged media photos"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'media-photos'
    and exists (
      select 1
      from public.media_items m
      join public.media_people mp on mp.media_item_id = m.id
      where m.storage_path = name
        and mp.tagged_profile_id = (select auth.uid())
        and mp.status in (
          'suggested',
          'pending_confirmation',
          'confirmed',
          'accepted_to_gallery',
          'linked_only'
        )
    )
  );

-- media-thumbnails
drop policy if exists "Tagged users can read tagged media thumbnails" on storage.objects;
create policy "Tagged users can read tagged media thumbnails"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'media-thumbnails'
    and exists (
      select 1
      from public.media_items m
      join public.media_people mp on mp.media_item_id = m.id
      where m.thumbnail_path = name
        and mp.tagged_profile_id = (select auth.uid())
        and mp.status in (
          'suggested',
          'pending_confirmation',
          'confirmed',
          'accepted_to_gallery',
          'linked_only'
        )
    )
  );

-- media-videos
drop policy if exists "Tagged users can read tagged media videos" on storage.objects;
create policy "Tagged users can read tagged media videos"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'media-videos'
    and exists (
      select 1
      from public.media_items m
      join public.media_people mp on mp.media_item_id = m.id
      where m.storage_path = name
        and mp.tagged_profile_id = (select auth.uid())
        and mp.status in (
          'suggested',
          'pending_confirmation',
          'confirmed',
          'accepted_to_gallery',
          'linked_only'
        )
    )
  );

-- Rollback-Hinweis:
-- drop policy if exists "Tagged users can read tagged media photos" on storage.objects;
-- drop policy if exists "Tagged users can read tagged media thumbnails" on storage.objects;
-- drop policy if exists "Tagged users can read tagged media videos" on storage.objects;
