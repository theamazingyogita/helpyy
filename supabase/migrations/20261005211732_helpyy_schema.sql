-- helpyy: everything that used to live in SharedPreferences, per user.
--
-- Every table is private to its owner through row level security. New
-- tables are not exposed to the Data API by default (Supabase, April 2026),
-- so each one grants the authenticated role explicitly. anon gets nothing.

create schema if not exists private;

-- Profiles -------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 80),
  -- An https URL in the avatars bucket, or avatar:<seed> for a character.
  photo_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles: owner reads" on public.profiles
  for select to authenticated
  using ((select auth.uid()) = id);

create policy "profiles: owner updates" on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- Older projects grant everything on new tables by default. Start from
-- nothing and grant only what the app uses.
revoke all on public.profiles from anon, authenticated;
grant select, update (name, photo_url, updated_at) on public.profiles to authenticated;

-- Sign up passes the name in user metadata. It is only copied here as the
-- display name and never used for authorization.
create function private.create_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, name)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'name'), ''), 'Friend')
  );
  return new;
end;
$$;

revoke execute on function private.create_profile() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.create_profile();

-- Signals --------------------------------------------------------------------

create table public.knock_patterns (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  -- Made by the app, unique per user.
  id text not null,
  -- Order on the home screen.
  position bigint not null default (extract(epoch from clock_timestamp()) * 1000000)::bigint,
  caller_name text not null check (char_length(caller_name) between 1 and 80),
  knock_count smallint not null check (knock_count between 2 and 8),
  -- Gaps between knocks in milliseconds, null for a plain tap count.
  rhythm integer[],
  delay_seconds smallint not null default 0 check (delay_seconds between 0 and 60),
  created_at timestamptz not null default now(),
  primary key (user_id, id)
);

alter table public.knock_patterns enable row level security;

create policy "knock_patterns: owner reads" on public.knock_patterns
  for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "knock_patterns: owner adds" on public.knock_patterns
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "knock_patterns: owner updates" on public.knock_patterns
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "knock_patterns: owner deletes" on public.knock_patterns
  for delete to authenticated
  using ((select auth.uid()) = user_id);

revoke all on public.knock_patterns from anon, authenticated;
grant select, insert, update, delete on public.knock_patterns to authenticated;

-- Replaces all of the caller's signals in one transaction, so a failure
-- halfway never leaves them with half a list. Runs as the caller, so the
-- policies above still apply.
create function public.replace_knock_patterns(patterns jsonb)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  delete from public.knock_patterns where user_id = (select auth.uid());
  insert into public.knock_patterns
    (user_id, id, position, caller_name, knock_count, rhythm, delay_seconds)
  select
    (select auth.uid()),
    p ->> 'id',
    t.ordinality,
    p ->> 'callerName',
    (p ->> 'knockCount')::smallint,
    case
      when jsonb_typeof(p -> 'rhythm') = 'array'
        then array(select jsonb_array_elements_text(p -> 'rhythm')::integer)
    end,
    coalesce((p ->> 'delaySeconds')::smallint, 0)
  from jsonb_array_elements(patterns) with ordinality as t (p, ordinality);
end;
$$;

revoke execute on function public.replace_knock_patterns(jsonb) from public, anon;
grant execute on function public.replace_knock_patterns(jsonb) to authenticated;

-- Call history ---------------------------------------------------------------

create table public.call_records (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  caller_name text not null,
  started_at timestamptz not null,
  answered boolean not null,
  talk_time_seconds integer not null default 0 check (talk_time_seconds >= 0)
);

-- Serves both the newest first history query and the foreign key.
create index call_records_user_started_idx on public.call_records (user_id, started_at desc);

alter table public.call_records enable row level security;

create policy "call_records: owner reads" on public.call_records
  for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "call_records: owner adds" on public.call_records
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "call_records: owner deletes" on public.call_records
  for delete to authenticated
  using ((select auth.uid()) = user_id);

revoke all on public.call_records from anon, authenticated;
grant select, insert, delete on public.call_records to authenticated;

-- Settings -------------------------------------------------------------------

-- The ringtone is left out on purpose: it is a device ringtone on Android
-- and a bundled tone on iOS, so it stays on the phone.

create table public.user_settings (
  user_id uuid primary key default auth.uid() references auth.users (id) on delete cascade,
  motion_sensitivity text not null default 'medium'
    check (motion_sensitivity in ('low', 'medium', 'high')),
  updated_at timestamptz not null default now()
);

alter table public.user_settings enable row level security;

create policy "user_settings: owner reads" on public.user_settings
  for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "user_settings: owner adds" on public.user_settings
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "user_settings: owner updates" on public.user_settings
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

revoke all on public.user_settings from anon, authenticated;
grant select, insert, update on public.user_settings to authenticated;

-- Profile photos ---------------------------------------------------------------

-- Public so a photo loads from its URL. Each file sits under its owner's id
-- with a fresh name per upload, so URLs cannot be guessed.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 5242880, array['image/jpeg', 'image/png', 'image/heic']);

create policy "avatars: owner uploads" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "avatars: owner reads" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "avatars: owner deletes" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
