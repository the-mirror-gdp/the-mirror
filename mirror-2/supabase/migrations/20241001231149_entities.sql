create table entities (
  id uuid not null primary key default uuid_generate_v4(),
  name text not null,
  enabled boolean not null default true,
  parent_id uuid references entities(id) on delete cascade,
  order_under_parent int,
  scene_id bigint references scenes on delete cascade not null, -- delete entity if scene is deleted
  local_position float8[] not null default array[0, 0, 0], -- storing position as an array of 3 floats
  -- Future: store position (global as PointZ for large querying)
  local_scale float8[] not null default array[1.0, 1.0, 1.0], -- storing scale as an array of 3 floats
  local_rotation float8[] not null default array[0.0, 0.0, 0.0, 1.0],  -- store rotation as a quaternion (x, y, z, w). NOT euler, though euler is mostly used user-facing
  tags text[] default array[]::text[], -- storing tags as an empty array of text 
  components jsonb not null default '{}'::jsonb, -- TODO add jsonb validation once this is hardened
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint name_length check (char_length(name) >= 0),
  constraint order_not_null_if_parent_id_exists check (
    (parent_id is not null and order_under_parent is not null) or parent_id is null
  ),
  constraint parent_id_not_self check (parent_id is distinct from id) -- ensures parent_id is not the same as id
);

create or replace function check_circular_reference()
returns trigger as $$
declare
    current_parent uuid;
begin
    -- Set the current parent to the newly inserted/updated parent_id
    current_parent := new.parent_id;

    -- Traverse up the hierarchy
    while current_parent is not null loop
        -- If at any point, the current parent is the same as the entity's id, we have a cycle
        if current_parent = new.id then
            raise exception 'Circular reference detected: Entity % is an ancestor of itself.', new.id;
        end if;

        -- Move to the next parent in the hierarchy
        select parent_id into current_parent from entities where id = current_parent;
    end loop;

    -- If no circular reference is found, return and allow the insert/update
    return new;
end;
$$ language plpgsql;

create trigger prevent_circular_reference
before insert or update on entities
for each row
execute function check_circular_reference();

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
