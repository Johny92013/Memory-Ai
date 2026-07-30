-- Gesichts-DETECTION (Position), keine Identitätszuordnung
-- Owner-only RLS; Löschung bei Consent-Widerruf über owner_id

create table if not exists public.media_face_detections (
  id uuid primary key default gen_random_uuid(),
  media_id uuid not null references public.media_items (id) on delete cascade,
  owner_id uuid not null references auth.users (id) on delete cascade,
  bounding_box jsonb not null,
  confidence double precision,
  detected_at timestamptz not null default now(),
  linked_person_id uuid references public.people (id) on delete set null,
  source text not null default 'ml_kit'
    check (source in ('ml_kit', 'manual')),
  constraint media_face_detections_bbox_object check (jsonb_typeof(bounding_box) = 'object')
);

comment on table public.media_face_detections is
  'Lokale Gesichtspositionen (Detection only). Keine Identitäts-Embeddings.';

create index if not exists media_face_detections_media_id_idx
  on public.media_face_detections (media_id);

create index if not exists media_face_detections_owner_id_idx
  on public.media_face_detections (owner_id);

create index if not exists media_face_detections_linked_person_id_idx
  on public.media_face_detections (linked_person_id)
  where linked_person_id is not null;

alter table public.media_face_detections enable row level security;

drop policy if exists "Owners can select face detections" on public.media_face_detections;
drop policy if exists "Owners can insert face detections" on public.media_face_detections;
drop policy if exists "Owners can update face detections" on public.media_face_detections;
drop policy if exists "Owners can delete face detections" on public.media_face_detections;

create policy "Owners can select face detections"
  on public.media_face_detections for select
  to authenticated
  using ((select auth.uid()) = owner_id);

create policy "Owners can insert face detections"
  on public.media_face_detections for insert
  to authenticated
  with check ((select auth.uid()) = owner_id);

create policy "Owners can update face detections"
  on public.media_face_detections for update
  to authenticated
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create policy "Owners can delete face detections"
  on public.media_face_detections for delete
  to authenticated
  using ((select auth.uid()) = owner_id);

revoke all on table public.media_face_detections from anon;
grant select, insert, update, delete on table public.media_face_detections to authenticated;
