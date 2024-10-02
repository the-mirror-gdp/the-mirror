-- create enum for avatar type
create type avatar_type as enum (
'ready_player_me'
);

-- Create a table for public user_profiles
create table user_profiles (
  id uuid references auth.users on delete cascade not null primary key default uuid_generate_v4(),
  display_name text unique not null,
  public_bio text,
  ready_player_me_url_glb text,
  avatar_type public.avatar_type null default 'ready_player_me'::avatar_type,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint display_name_length check (char_length(display_name) >= 3)
);
-- Set up Row Level Security (RLS)
alter table user_profiles
  enable row level security;

create policy "Public user_profiles are viewable by everyone." on user_profiles
  for select using (true);

create policy "Users can create their own profile." on user_profiles
  for insert with check ((select auth.uid()) = id);

create policy "Users can update own profile." on user_profiles
  for update using ((select auth.uid()) = id);

-- Set up Storage!
insert into storage.buckets (id, name)
  values ('user_profile_images', 'user_profile_images');

-- Set up access controls for storage.
-- See https://supabase.com/docs/guides/storage#policy-examples for more details.
create policy "User profiles images are publicly accessible." on storage.objects
  for select using (bucket_id = 'user_profile_images');

create policy "Authed users can upload a profile image." on storage.objects
  for insert to authenticated with check (bucket_id = 'user_profile_images');
