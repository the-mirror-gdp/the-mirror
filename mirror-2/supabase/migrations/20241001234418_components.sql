CREATE TYPE component_key AS ENUM (
    'script',
    'render',
    'collision',
    'rigidbody',
    'camera',
    'light',
    'anim',
    'sprite',
    'screen',
    'element',
    'button',
    'particlesystem',
    'gsplat',
    'audiolistener',
    'sound',
    'scrollbar',
    'scrollview',
    'layoutgroup',
    'layoutchild'
);

CREATE TABLE components (
  id UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  entity_id UUID REFERENCES entities(id) ON DELETE CASCADE NOT NULL, -- delete the component if entity is deleted
  component_key component_key NOT NULL,
  attributes JSONB DEFAULT '{}'::jsonb,  -- New column with default empty JSON object
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
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
