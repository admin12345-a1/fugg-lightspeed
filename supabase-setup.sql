-- Fugglightspeed shared backend setup for Supabase
-- Run the whole script in Supabase Dashboard > SQL Editor.
-- Videos are public to view. Upload, comment, subscribe, and delete actions require an individual signed-in account.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null check (char_length(username) between 3 and 30),
  created_at timestamptz not null default now()
);

create table if not exists public.videos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 120),
  categories text[] not null default '{}',
  storage_path text not null,
  trim_start numeric not null default 0,
  trim_end numeric not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  video_id uuid not null references public.videos(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 500),
  created_at timestamptz not null default now()
);

create table if not exists public.subscriptions (
  subscriber_id uuid not null references auth.users(id) on delete cascade,
  creator_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (subscriber_id, creator_id),
  check (subscriber_id <> creator_id)
);

-- Add missing fields if these tables were created by an earlier prototype setup.
alter table public.profiles add column if not exists username text;
alter table public.profiles add column if not exists created_at timestamptz not null default now();
alter table public.videos add column if not exists categories text[] not null default '{}';
alter table public.videos add column if not exists storage_path text;
alter table public.videos add column if not exists trim_start numeric not null default 0;
alter table public.videos add column if not exists trim_end numeric not null default 0;
alter table public.videos add column if not exists created_at timestamptz not null default now();
alter table public.comments add column if not exists body text;
alter table public.comments add column if not exists created_at timestamptz not null default now();
alter table public.subscriptions add column if not exists created_at timestamptz not null default now();

create unique index if not exists profiles_username_unique_idx on public.profiles (lower(username));
create index if not exists videos_created_at_idx on public.videos (created_at desc);
create index if not exists videos_user_id_idx on public.videos (user_id);
create index if not exists comments_video_created_at_idx on public.comments (video_id, created_at);
create index if not exists subscriptions_creator_id_idx on public.subscriptions (creator_id);

-- Automatically create a public profile when a real Supabase Auth user signs up.
create or replace function public.create_profile_for_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  base_name text;
  chosen_name text;
begin
  base_name := lower(regexp_replace(coalesce(new.raw_user_meta_data ->> 'username', split_part(new.email, '@', 1), 'user'), '[^a-zA-Z0-9_]', '', 'g'));
  base_name := left(base_name, 22);
  if char_length(base_name) < 3 then
    base_name := 'user';
  end if;
  chosen_name := base_name;
  while exists (select 1 from public.profiles p where lower(p.username) = lower(chosen_name)) loop
    chosen_name := left(base_name, 22) || '_' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 6);
  end loop;
  insert into public.profiles (id, username)
  values (new.id, chosen_name)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
after insert on auth.users
for each row execute procedure public.create_profile_for_new_user();

alter table public.profiles enable row level security;
alter table public.videos enable row level security;
alter table public.comments enable row level security;
alter table public.subscriptions enable row level security;

-- Remove policy names used by earlier sample setup snippets, including the overly broad storage upload policy.
drop policy if exists "Profiles viewable" on public.profiles;
drop policy if exists "Profiles are viewable" on public.profiles;
drop policy if exists "Users can insert own profile" on public.profiles;
drop policy if exists "Users create their own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;
drop policy if exists "Profiles public read" on public.profiles;
drop policy if exists "Users update own profile" on public.profiles;
drop policy if exists "Videos viewable" on public.videos;
drop policy if exists "Videos are viewable" on public.videos;
drop policy if exists "Videos public read" on public.videos;
drop policy if exists "Users can insert own videos" on public.videos;
drop policy if exists "Signed-in users post their own videos" on public.videos;
drop policy if exists "Users can update own videos" on public.videos;
drop policy if exists "Owners update their own videos" on public.videos;
drop policy if exists "Users can delete own videos" on public.videos;
drop policy if exists "Owners delete their own videos" on public.videos;
drop policy if exists "Comments viewable" on public.comments;
drop policy if exists "Comments are viewable" on public.comments;
drop policy if exists "Comments public read" on public.comments;
drop policy if exists "Users can insert comments" on public.comments;
drop policy if exists "Signed-in users add comments" on public.comments;
drop policy if exists "Users can delete own comments" on public.comments;
drop policy if exists "Users delete their own comments" on public.comments;
drop policy if exists "Subscriptions viewable" on public.subscriptions;
drop policy if exists "Subscriptions are viewable" on public.subscriptions;
drop policy if exists "Users can insert subscription" on public.subscriptions;
drop policy if exists "Users subscribe as themselves" on public.subscriptions;
drop policy if exists "Users can remove own subscription" on public.subscriptions;
drop policy if exists "Users unsubscribe as themselves" on public.subscriptions;

drop policy if exists "Anyone can view uploaded videos" on storage.objects;
drop policy if exists "Videos can be watched" on storage.objects;
drop policy if exists "Users can upload videos" on storage.objects;
drop policy if exists "Users upload to their own folder" on storage.objects;
drop policy if exists "Users can delete own uploaded videos" on storage.objects;
drop policy if exists "Users delete files in their own folder" on storage.objects;
drop policy if exists "Public can view Fugglightspeed videos" on storage.objects;
drop policy if exists "Authenticated users upload to own folder" on storage.objects;
drop policy if exists "Users delete videos in own folder" on storage.objects;

create policy "Profiles public read" on public.profiles
for select to anon, authenticated using (true);
create policy "Users update own profile" on public.profiles
for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

create policy "Videos public read" on public.videos
for select to anon, authenticated using (true);
create policy "Users insert own videos" on public.videos
for insert to authenticated with check (user_id = auth.uid());
create policy "Users delete own videos" on public.videos
for delete to authenticated using (user_id = auth.uid());

create policy "Comments public read" on public.comments
for select to anon, authenticated using (true);
create policy "Signed in users add own comments" on public.comments
for insert to authenticated with check (user_id = auth.uid());
create policy "Users delete own comments" on public.comments
for delete to authenticated using (user_id = auth.uid());

create policy "Users read subscriptions" on public.subscriptions
for select to authenticated using (subscriber_id = auth.uid() or creator_id = auth.uid());
create policy "Users subscribe as themselves" on public.subscriptions
for insert to authenticated with check (subscriber_id = auth.uid() and creator_id <> auth.uid());
create policy "Users unsubscribe as themselves" on public.subscriptions
for delete to authenticated using (subscriber_id = auth.uid());

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('videos', 'videos', true, 104857600, array['video/mp4','video/webm','video/quicktime','video/ogg','video/x-m4v'])
on conflict (id) do update set public = true, file_size_limit = 104857600;

create policy "Public can view Fugglightspeed videos" on storage.objects
for select to anon, authenticated using (bucket_id = 'videos');
create policy "Authenticated users upload to own folder" on storage.objects
for insert to authenticated with check (bucket_id = 'videos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Users delete videos in own folder" on storage.objects
for delete to authenticated using (bucket_id = 'videos' and (storage.foldername(name))[1] = auth.uid()::text);
