create table entities (
  id uuid NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  enabled boolean NOT NULL DEFAULT true,
  scene_id uuid REFERENCES scenes ON DELETE CASCADE NOT NULL, -- delete entity if scene is deleted
  position float8[] NOT NULL DEFAULT ARRAY[0, 0, 0], -- storing position as an array of 3 floats
  scale float8[] NOT NULL DEFAULT ARRAY[1, 1, 1], -- storing scale as an array of 3 floats
  rotation float8[] NOT NULL DEFAULT ARRAY[0, 0, 0], -- storing rotation as an array of 3 floats
  tags text[] DEFAULT ARRAY[]::text[], -- storing tags as an empty array of text 
  parent_id uuid REFERENCES entities ON DELETE CASCADE, -- reference to parent entity, allows hierarchical structure
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT name_length CHECK (char_length(name) >= 0)
);

  -- add RLS
alter table entities
  enable row level security;

-- Policy for space owners
create policy "Owners can view their own entities" 
on entities
for select 
using (
  exists (
    select 1 from spaces
    join scenes on scenes.space_id = spaces.id
    where scenes.id = entities.scene_id
    and spaces.owner_user_id = auth.uid()
  )
);

-- Policy for selecting entities
create policy "Users can create their own entities" 
on entities
for insert 
with check (
  exists (
    select 1 from spaces
    join scenes on scenes.space_id = spaces.id
    where scenes.id = entities.scene_id
    and spaces.owner_user_id = auth.uid()
  )
);

-- Policy for updating entities
create policy "Users can update their own entities" 
on entities
for update 
using (
  exists (
    select 1 from spaces
    join scenes on scenes.space_id = spaces.id
    where scenes.id = entities.scene_id
    and spaces.owner_user_id = auth.uid()
  )
);

-- Policy for deleting entities
create policy "Users can delete their own entities" 
on entities
for delete 
using (
  exists (
    select 1 from spaces
    join scenes on scenes.space_id = spaces.id
    where scenes.id = entities.scene_id
    and spaces.owner_user_id = auth.uid()
  )
);
