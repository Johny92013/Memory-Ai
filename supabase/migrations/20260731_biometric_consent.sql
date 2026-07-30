-- Biometrische Einwilligung (Art. 9 DSGVO) – Owner-only Tabelle
-- Getrennt von profiles, weil Familienmitglieder profiles SELECT sehen dürfen.

create table if not exists public.biometric_consents (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  biometric_consent_given boolean not null default false,
  biometric_consent_at timestamptz,
  biometric_consent_version integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.biometric_consents is
  'Einwilligung zur gerätebasierten Gesichtserkennung; nur Eigentümer darf lesen/schreiben.';

comment on column public.biometric_consents.biometric_consent_version is
  'Version des Einwilligungstexts; bei neuer Version muss erneut eingewilligt werden.';

create index if not exists biometric_consents_given_idx
  on public.biometric_consents (biometric_consent_given)
  where biometric_consent_given = true;

alter table public.biometric_consents enable row level security;

drop policy if exists "Users can view own biometric consent" on public.biometric_consents;
drop policy if exists "Users can insert own biometric consent" on public.biometric_consents;
drop policy if exists "Users can update own biometric consent" on public.biometric_consents;
drop policy if exists "Users can delete own biometric consent" on public.biometric_consents;

create policy "Users can view own biometric consent"
  on public.biometric_consents for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can insert own biometric consent"
  on public.biometric_consents for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Users can update own biometric consent"
  on public.biometric_consents for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users can delete own biometric consent"
  on public.biometric_consents for delete
  to authenticated
  using ((select auth.uid()) = user_id);

-- Keine Admin-/Family-SELECT-Policies: Status bleibt privat.
revoke all on table public.biometric_consents from anon;
grant select, insert, update, delete on table public.biometric_consents to authenticated;
