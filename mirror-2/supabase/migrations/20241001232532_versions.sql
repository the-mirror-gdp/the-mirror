create table space_versions (
  id uuid not null primary key default uuid_generate_v4(),
  name text not null,
  space_id uuid references spaces on delete cascade not null, -- delete the version if space is deleted
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint name_length check (char_length(name) >= 0)
  );

  -- add RLS
alter table space_versions
  enable row level security;

-- Policy for space owners
create policy "Owners can view their own space_versions" 
on space_versions
for select 
using (
  exists (
    select 1 from spaces
    where spaces.id = space_versions.space_id
    and spaces.owner_user_id = auth.uid()
  )
);

-- Policy for selecting space_versions
create policy "Users can create their own space_versions" 
on space_versions
for insert 
with check (
  exists (
    select 1 from spaces
    where spaces.id = space_versions.space_id
    and spaces.owner_user_id = auth.uid()
  )
);

-- Policy for updating space_versions
create policy "Users can update their own space_versions" 
on space_versions
for update 
using (
  exists (
    select 1 from spaces
    where spaces.id = space_versions.space_id
    and spaces.owner_user_id = auth.uid()
  )
);

-- Policy for deleting space_versions
create policy "Users can delete their own space_versions" 
on space_versions
for delete 
using (
  exists (
    select 1 from spaces
    where spaces.id = space_versions.space_id
    and spaces.owner_user_id = auth.uid()
  )
);
