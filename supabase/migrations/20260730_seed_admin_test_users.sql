-- Seed admin and test demo users (change passwords before production)
-- Passwords are inserted directly; Supabase Auth dashboard min-length does not apply.

do $$
declare
  admin_id uuid := gen_random_uuid();
  test_id uuid := gen_random_uuid();
begin
  if not exists (select 1 from auth.users where email = 'admin@memoryai.app') then
    insert into auth.users (
      id, instance_id, aud, role, email, encrypted_password,
      email_confirmed_at, last_sign_in_at,
      raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at,
      confirmation_token, email_change, email_change_token_new, recovery_token
    ) values (
      admin_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      'admin@memoryai.app',
      crypt('admin', gen_salt('bf')),
      now(), now(),
      '{"provider":"email","providers":["email"],"app_role":"admin"}'::jsonb,
      '{"first_name":"Admin"}'::jsonb,
      now(), now(),
      '', '', '', ''
    );

    insert into auth.identities (
      id, user_id, identity_data, provider, provider_id,
      last_sign_in_at, created_at, updated_at
    ) values (
      admin_id, admin_id,
      jsonb_build_object(
        'sub', admin_id::text,
        'email', 'admin@memoryai.app',
        'email_verified', true,
        'phone_verified', false
      ),
      'email', admin_id::text,
      now(), now(), now()
    );
  end if;

  if not exists (select 1 from auth.users where email = 'test@memoryai.app') then
    insert into auth.users (
      id, instance_id, aud, role, email, encrypted_password,
      email_confirmed_at, last_sign_in_at,
      raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at,
      confirmation_token, email_change, email_change_token_new, recovery_token
    ) values (
      test_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      'test@memoryai.app',
      crypt('test', gen_salt('bf')),
      now(), now(),
      '{"provider":"email","providers":["email"],"app_role":"user"}'::jsonb,
      '{"first_name":"Test"}'::jsonb,
      now(), now(),
      '', '', '', ''
    );

    insert into auth.identities (
      id, user_id, identity_data, provider, provider_id,
      last_sign_in_at, created_at, updated_at
    ) values (
      test_id, test_id,
      jsonb_build_object(
        'sub', test_id::text,
        'email', 'test@memoryai.app',
        'email_verified', true,
        'phone_verified', false
      ),
      'email', test_id::text,
      now(), now(), now()
    );
  end if;
end $$;

insert into public.profiles (id, email, username, first_name, profile_completed)
select u.id, u.email, 'admin', 'Admin', true
from auth.users u
where u.email = 'admin@memoryai.app'
on conflict (id) do update set
  email = excluded.email,
  username = excluded.username,
  first_name = excluded.first_name,
  profile_completed = true;

insert into public.profiles (id, email, username, first_name, profile_completed)
select u.id, u.email, 'test', 'Test', true
from auth.users u
where u.email = 'test@memoryai.app'
on conflict (id) do update set
  email = excluded.email,
  username = excluded.username,
  first_name = excluded.first_name,
  profile_completed = true;

update auth.users
set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || '{"app_role":"admin"}'::jsonb
where email = 'admin@memoryai.app';

update auth.users
set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || '{"app_role":"user"}'::jsonb
where email = 'test@memoryai.app';
