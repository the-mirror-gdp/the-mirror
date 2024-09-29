-- create enum for avatar type
create type avatar_type as enum (
'ready_player_me'
);

-- Create a table for public user_profiles
create table user_profiles (
  id uuid references auth.users on delete cascade not null primary key,
  updated_at timestamp with time zone,
  display_name text unique not null,
  public_bio text,
  ready_player_me_url_glb text,
  avatar_type public.avatar_type null default 'ready_player_me'::avatar_type,
  constraint display_name_length check (char_length(display_name) >= 3)
);
-- Set up Row Level Security (RLS)
-- See https://supabase.com/docs/guides/auth/row-level-security for more details.
alter table user_profiles
  enable row level security;

create policy "Public user_profiles are viewable by everyone." on user_profiles
  for select using (true);

create policy "Users can insert their own profile." on user_profiles
  for insert with check ((select auth.uid()) = id);

create policy "Users can update own profile." on user_profiles
  for update using ((select auth.uid()) = id);

-- This trigger automatically creates a profile entry when a new user signs up via Supabase Auth.
-- See https://supabase.com/docs/guides/auth/managing-user-data#using-triggers for more details.
create function public.handle_new_user()
returns trigger
set search_path = ''
as $$
begin
  insert into public.user_profiles (id, display_name)
  values (new.id, new.raw_user_meta_data->>'display_name');
  return new;
end;
$$ language plpgsql security definer;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Set up Storage!
insert into storage.buckets (id, name)
  values ('avatars', 'avatars');

-- Set up access controls for storage.
-- See https://supabase.com/docs/guides/storage#policy-examples for more details.
create policy "Avatar images are publicly accessible." on storage.objects
  for select using (bucket_id = 'avatars');

create policy "Anyone can upload an avatar." on storage.objects
  for insert with check (bucket_id = 'avatars');
