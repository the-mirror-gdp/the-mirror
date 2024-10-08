CREATE TABLE entities (
  id uuid NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  enabled boolean NOT NULL DEFAULT true,
  parent_id uuid REFERENCES entities(id) ON DELETE CASCADE,
  order_under_parent int,
  scene_id uuid REFERENCES scenes ON DELETE CASCADE NOT NULL, -- delete entity if scene is deleted
  position float8[] NOT NULL DEFAULT ARRAY[0, 0, 0], -- storing position as an array of 3 floats
  scale float8[] NOT NULL DEFAULT ARRAY[1, 1, 1], -- storing scale as an array of 3 floats
  rotation float8[] NOT NULL DEFAULT ARRAY[0, 0, 0], -- storing rotation as an array of 3 floats
  tags text[] DEFAULT ARRAY[]::text[], -- storing tags as an empty array of text 
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT name_length CHECK (char_length(name) >= 0),
  CONSTRAINT order_not_null_if_parent_id_exists CHECK (
    (parent_id IS NOT NULL AND order_under_parent IS NOT NULL) OR parent_id IS NULL
  ),
  CONSTRAINT parent_id_not_self CHECK (parent_id IS DISTINCT FROM id) -- Ensures parent_id is not the same as id
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

CREATE POLICY "Disallow Root entity deletion"
ON entities
FOR DELETE
USING (
  parent_id = null
);


CREATE OR REPLACE FUNCTION increment_and_resequence_order_under_parent(p_scene_id uuid, p_entity_id uuid)
RETURNS void AS $$
DECLARE
    target_order int;
    target_parent_id uuid;
BEGIN
    -- 1. Find the target entity by entity_id
    SELECT order_under_parent, parent_id
    INTO target_order, target_parent_id
    FROM entities
    WHERE id = p_entity_id;

    -- Check if the entity exists
    IF target_order IS NULL THEN
        RAISE EXCEPTION 'Entity with id % does not exist.', p_entity_id;
    END IF;

    -- 2. Increment order_under_parent for entities with greater order
    UPDATE entities
    SET order_under_parent = order_under_parent + 1
    WHERE scene_id = p_scene_id
      AND parent_id IS NOT DISTINCT FROM target_parent_id
      AND order_under_parent > target_order;

    -- 3. Resequence order_under_parent to eliminate gaps
    WITH ordered_entities AS (
        SELECT id,
               ROW_NUMBER() OVER (ORDER BY order_under_parent) AS new_order
        FROM entities
        WHERE scene_id = p_scene_id
          AND parent_id IS NOT DISTINCT FROM target_parent_id
    )
    UPDATE entities e
    SET order_under_parent = oe.new_order
    FROM ordered_entities oe
    WHERE e.id = oe.id;

    -- Optionally, update the updated_at timestamp
    -- UPDATE entities SET updated_at = NOW() WHERE id = ANY(SELECT id FROM ordered_entities);
END;
$$ LANGUAGE plpgsql;
