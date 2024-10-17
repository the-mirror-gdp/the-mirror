-- Create the pc_imports table
create table pc_imports (
  id uuid primary key default uuid_generate_v4(),
  owner_user_id uuid references auth.users(id),
  display_name text not null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

-- Policy to allow users to create their own pc-imports
-- create policy "Allow user to create pc-imports"
-- on pc_imports
-- for insert
-- to authenticated
-- with check (
--   auth.uid()::uuid = owner_user_id  -- Ensure the project is created with the correct owner_user_id
-- );

-- -- Policy to allow users to select (view) their own pc-imports
-- create policy "Allow user to select own pc-imports"
-- on pc_imports
-- for select
-- to authenticated
-- using (
--   auth.uid()::uuid = owner_user_id  -- Ensure the user can only select their own pc_imports
-- );

-- -- Policy to allow users to update their own pc-imports
-- create policy "Allow user to update own pc-imports"
-- on pc_imports
-- for update
-- to authenticated
-- using (
--   auth.uid()::uuid = owner_user_id  -- Ensure the user can only update their own pc_imports
-- );

-- -- Policy to allow users to delete their own pc-imports
-- create policy "Allow user to delete own pc-imports"
-- on pc_imports
-- for delete
-- to authenticated
-- using (
--   auth.uid()::uuid = owner_user_id  -- Ensure the user can only delete their own pc_imports
-- );

-- Set up storage bucket for pc-imports
insert into
  storage.buckets (id, name, public)
values
  ('pc-imports', 'pc-imports', true);


create policy "User can insert their own pc-imports"
on storage.objects
for insert
to authenticated
with check (
    bucket_id = 'pc-imports' and
    owner_id = (select auth.uid()::text)  -- Ensure the owner is the current authenticated user
);

create policy "Anyone can read pc-imports"
on storage.objects
for select
to authenticated
using (
    bucket_id = 'pc-imports'
);

create policy "User can update their own pc-imports"
on storage.objects
for update
to authenticated
using (
    bucket_id = 'pc-imports' and
    owner_id = (select auth.uid()::text)  -- Ensure the user owns the object they want to update
);

create policy "User can delete their own pc-imports"
on storage.objects
for delete
to authenticated
using (
    bucket_id = 'pc-imports' and
    owner_id = (select auth.uid()::text)  -- Ensure the user owns the object they want to delete
);


-- Policy to allow authenticated uploads to the /pc-imports/<userId>/<projectId> folder
-- create policy "Allow authenticated uploads for /pc-imports/<userId>/<projectId> folder"
-- on storage.objects
-- for insert
-- to authenticated
-- with check (
--   bucket_id = 'pc-imports' 
--   AND (storage.foldername(name))[1] = auth.uid()::text  -- Ensure userId matches auth.uid()
-- );
