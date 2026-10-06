create schema if not exists private;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 80),
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

revoke all on public.profiles from anon, authenticated;
grant select, update (name, photo_url, updated_at) on public.profiles to authenticated;

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

create table public.knock_patterns (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id text not null,
  position bigint not null default (extract(epoch from clock_timestamp()) * 1000000)::bigint,
  caller_name text not null check (char_length(caller_name) between 1 and 80),
  knock_count smallint not null check (knock_count between 2 and 8),
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

create table public.call_records (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  caller_name text not null,
  started_at timestamptz not null,
  answered boolean not null,
  talk_time_seconds integer not null default 0 check (talk_time_seconds >= 0)
);

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
