-- assets
create table assets (
  id uuid not null primary key default uuid_generate_v4(),
  owner_user_id uuid references auth.users(id) not null, -- owner is different from creator. Assets can be transferred and we want to retain the creator
  creator_user_id uuid references auth.users(id) not null,
  name text not null,
  description text,
  file_url text not null,
  thumbnail_url text not null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
  );

-- add RLS
alter table assets
  enable row level security;
  
  -- Policy for creating assets
create policy "Users can create their own assets" 
on assets
for insert 
with check (
  owner_user_id = auth.uid() 
  and creator_user_id = auth.uid()
);

-- Policy for selecting assets
create policy "Users can view their own assets" 
on assets
for select 
using (
  owner_user_id = auth.uid()
);

-- Policy for updating assets
create policy "Users can update their own assets" 
on assets
for update 
using (owner_user_id = auth.uid());

-- Policy for deleting assets
create policy "Users can delete their own assets" 
on assets
for delete 
using (owner_user_id = auth.uid());


-- set up storage for assets
insert into
  storage.buckets (id, name, public)
values
  ('assets', 'assets', true);


create policy "User can insert their own objects"
on storage.objects
for insert
to authenticated
with check (
    bucket_id = 'assets' and
    owner_id = (select auth.uid()::text)  -- Ensure the owner is the current authenticated user
);

create policy "Anyone can read assets"
on storage.objects
for select
to authenticated
using (
    bucket_id = 'assets'
);

create policy "User can update their own objects"
on storage.objects
for update
to authenticated
using (
    bucket_id = 'assets' and
    owner_id = (select auth.uid()::text)  -- Ensure the user owns the object they want to update
);

create policy "User can delete their own objects"
on storage.objects
for delete
to authenticated
using (
    bucket_id = 'assets' and
    owner_id = (select auth.uid()::text)  -- Ensure the user owns the object they want to delete
);
