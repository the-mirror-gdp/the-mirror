create table spaces (
  id uuid not null primary key,
  name text not null,
  owner_user_id uuid references auth.users(id) not null,  -- owner is different from creator. Spaces can be transferred and we want to retain the creator
  creator_user_id uuid references auth.users(id) not null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint name_length check (char_length(name) >= 3)
  );

  -- add RLS
alter table spaces
  enable row level security;

-- Policy for space owners
create policy "Owners can view their own spaces" 
on spaces
for select 
using (owner_user_id = auth.uid());

-- Policy for creating spaces
create policy "Users can create their own spaces" 
on spaces
for insert 
with check (owner_user_id = auth.uid());

-- Policy for selecting spaces
create policy "Users can view their own spaces" 
on spaces
for select 
using (
  owner_user_id = auth.uid()
);

-- Policy for updating spaces
create policy "Users can update their own spaces" 
on spaces
for update 
using (owner_user_id = auth.uid());

-- Policy for deleting spaces
create policy "Users can delete their own spaces" 
on spaces
for delete 
using (owner_user_id = auth.uid());

-- assets
create table assets (
  id uuid not null primary key,
  owner_user_id uuid references auth.users(id) not null, -- owner is different from creator. Assets can be transferred and we want to retain the creator
  creator_user_id uuid references auth.users(id) not null,
  name text not null,
  asset_url text not null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
  );

-- add RLS
alter table assets
  enable row level security;

-- set up storage for assets
insert into
  storage.buckets (id, name, public)
values
  ('assets', 'assets', true);
