create table scenes (
  id uuid not null primary key,
  space_id uuid references spaces on delete cascade not null, -- delete the scene if space is deleted
  name text not null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint name_length check (char_length(name) >= 0)
  );

  -- add RLS
alter table scenes
  enable row level security;

-- Policy for space owners
create policy "Owners can view their own scenes" 
on scenes
for select 
using (
  exists (
    select 1 from spaces
    where spaces.id = scenes.space_id
    and spaces.owner_user_id = auth.uid()
  )
);

-- Policy for selecting scenes
create policy "Users can create their own scenes" 
on scenes
for insert 
with check (
  exists (
    select 1 from spaces
    where spaces.id = scenes.space_id
    and spaces.owner_user_id = auth.uid()
  )
);

-- Policy for updating scenes
create policy "Users can update their own scenes" 
on scenes
for update 
using (
  exists (
    select 1 from spaces
    where spaces.id = scenes.space_id
    and spaces.owner_user_id = auth.uid()
  )
);

-- Policy for deleting scenes
create policy "Users can delete their own scenes" 
on scenes
for delete 
using (
  exists (
    select 1 from spaces
    where spaces.id = scenes.space_id
    and spaces.owner_user_id = auth.uid()
  )
);
