CREATE OR REPLACE FUNCTION get_entities_with_children(_scene_id uuid)
RETURNS TABLE (
  id uuid,
  name text,
  parent_id uuid,
  children uuid[]
) AS $$
BEGIN
  RETURN QUERY
  WITH RECURSIVE entity_tree AS (
    -- Base case: Select all entities that belong to the scene and have no parent
    SELECT 
      e.id, 
      e.name, 
      e.parent_id,
      ARRAY[]::uuid[] AS children  -- Start with an empty array for children
    FROM 
      entities e
    WHERE 
      e.parent_id IS NULL
      AND e.scene_id = _scene_id  -- Use the function argument _scene_id
    
    UNION ALL
    
    -- Recursive case: Find the children of each entity in the previous level
    SELECT 
      e.id, 
      e.name, 
      e.parent_id,
      et.children || e.id  -- Append the entity ID to the parent's children array
    FROM 
      entities e
    INNER JOIN 
      entity_tree et ON e.parent_id = et.id
    WHERE 
      e.scene_id = _scene_id  -- Use the function argument _scene_id
  )
  SELECT 
    entity_tree.id,  -- Explicitly refer to the CTE's id
    entity_tree.name, 
    entity_tree.parent_id, 
    COALESCE(
      (SELECT ARRAY_AGG(c.id) 
       FROM entities c 
       WHERE c.parent_id = entity_tree.id), 
      '{}'::uuid[]
    ) AS children  -- Aggregate children IDs, return empty array if no children
  FROM 
    entity_tree;
END;
$$ LANGUAGE plpgsql;
