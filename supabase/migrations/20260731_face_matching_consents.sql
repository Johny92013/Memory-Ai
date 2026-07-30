-- Getrennte Matching-Einwilligungen + Referenz-Embeddings + media_people.status
-- Hinweis: Felder liegen auf biometric_consents (Owner-only), NICHT auf profiles
-- (Familienmitglieder dürfen profiles SELECT – Consent muss privat bleiben).

alter table public.biometric_consents
  add column if not exists face_reference_consent_given boolean not null default false,
  add column if not exists face_reference_consent_at timestamptz,
  add column if not exists family_matching_consent_given boolean not null default false,
  add column if not exists family_matching_consent_at timestamptz;

create table if not exists public.face_reference_embeddings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  embedding jsonb not null,
  created_at timestamptz not null default now()
);

create index if not exists face_reference_embeddings_user_idx
  on public.face_reference_embeddings (user_id);

alter table public.face_reference_embeddings enable row level security;

drop policy if exists "Users manage own face references" on public.face_reference_embeddings;
create policy "Users manage own face references"
  on public.face_reference_embeddings for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

revoke all on table public.face_reference_embeddings from anon;
grant select, insert, update, delete on table public.face_reference_embeddings to authenticated;

alter table public.media_face_detections
  add column if not exists embedding jsonb;

alter table public.media_people
  add column if not exists status text not null default 'confirmed';

alter table public.media_people drop constraint if exists media_people_status_check;
alter table public.media_people
  add constraint media_people_status_check
  check (status in ('suggested', 'confirmed', 'rejected'));

alter table public.media_people drop constraint if exists media_people_source_check;
alter table public.media_people
  add constraint media_people_source_check
  check (source in ('manual', 'face_ai', 'suggestion', 'face_recognition'));

create or replace function public.family_members_with_matching_consent()
returns table(member_user_id uuid)
language sql security definer set search_path = public stable as $$
  select distinct fm.user_id
  from public.family_members me
  join public.family_members fm on fm.family_id = me.family_id
  join public.biometric_consents bc on bc.user_id = fm.user_id
  where me.user_id = (select auth.uid())
    and fm.user_id <> (select auth.uid())
    and bc.family_matching_consent_given = true
    and exists (
      select 1 from public.biometric_consents mine
      where mine.user_id = (select auth.uid())
        and mine.family_matching_consent_given = true
    );
$$;

create or replace function public.get_family_face_reference_embeddings()
returns table(member_user_id uuid, embedding jsonb)
language sql security definer set search_path = public stable as $$
  select fre.user_id, fre.embedding
  from public.face_reference_embeddings fre
  where fre.user_id in (select member_user_id from public.family_members_with_matching_consent())
    and exists (
      select 1 from public.biometric_consents mine
      where mine.user_id = (select auth.uid())
        and mine.family_matching_consent_given = true
    );
$$;

revoke all on function public.family_members_with_matching_consent() from public;
grant execute on function public.family_members_with_matching_consent() to authenticated;
revoke all on function public.get_family_face_reference_embeddings() from public;
grant execute on function public.get_family_face_reference_embeddings() to authenticated;
