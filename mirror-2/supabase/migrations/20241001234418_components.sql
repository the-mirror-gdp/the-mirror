create table components (
  id uuid not null primary key,
  name text not null,
  entity_id uuid references entities on delete cascade not null, -- delete the component if entity is deleted
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint name_length check (char_length(name) >= 0)
  );

  -- add RLS
alter table components
  enable row level security;

-- Policy for space owners
create policy "Owners can view their own components if they own the space" 
on components
for select 
using (
  exists (
    select 1 from spaces
    join scenes on scenes.space_id = spaces.id
    join entities on entities.scene_id = scenes.id
    where entities.id = components.entity_id
    and spaces.owner_user_id = auth.uid()
  )
);

-- Policy for creating components
create policy "Users can create their own components if they own the space" 
on components
for insert 
with check (
  exists (
    select 1 from spaces
    join scenes on scenes.space_id = spaces.id
    join entities on entities.scene_id = scenes.id
    where entities.id = components.entity_id
    and spaces.owner_user_id = auth.uid()
  )
);

-- Policy for updating components
create policy "Users can update their own components if they own the space" 
on components
for update 
using (
  exists (
    select 1 from spaces
    join scenes on scenes.space_id = spaces.id
    join entities on entities.scene_id = scenes.id
    where entities.id = components.entity_id
    and spaces.owner_user_id = auth.uid()
  )
);

-- Policy for deleting components
create policy "Users can delete their own components if they own the space" 
on components
for delete 
using (
  exists (
    select 1 from spaces
    join scenes on scenes.space_id = spaces.id
    join entities on entities.scene_id = scenes.id
    where entities.id = components.entity_id
    and spaces.owner_user_id = auth.uid()
  )
);
