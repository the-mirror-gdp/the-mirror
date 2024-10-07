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


CREATE OR REPLACE FUNCTION get_entity_with_children(entity_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN (
    SELECT jsonb_build_object(
      'id', e.id,
      'name', e.name,
      'parent_id', e.parent_id,
      'children', (
        SELECT COALESCE(jsonb_agg(
          jsonb_build_object(
            'id', child.id,
            'name', child.name,
            'parent_id', child.parent_id,
            'children', (
              SELECT COALESCE(jsonb_agg(grandchild.id), '[]'::jsonb)
              FROM entities AS grandchild
              WHERE grandchild.parent_id = child.id
            )
          )
        ), '[]'::jsonb)
        FROM entities AS child
        WHERE child.parent_id = e.id
      )
    )
    FROM entities e
    WHERE e.id = entity_id
  );
END;
$$;

-- TODO this is overused and should be optimized, but it's fine for now to get things working 2024-10-07 15:10:28
CREATE OR REPLACE FUNCTION get_hierarchical_space_with_populated_children(_space_id uuid)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    -- Fetch the space along with scenes, entities, components, and children of entities (as full objects)
    SELECT jsonb_build_object(
        'id', s.id,
        'name', s.name,
        'description', s.description,
        'scenes', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'id', sc.id,
                    'name', sc.name,
                    'entities', (
                        SELECT COALESCE(jsonb_agg(
                            jsonb_build_object(
                                'id', e.id,
                                'name', e.name,
                                'parent_id', e.parent_id,
                                'children', (
                                    -- Recursively get the full child entities instead of just the IDs
                                    SELECT COALESCE(jsonb_agg(
                                        jsonb_build_object(
                                            'id', child.id,
                                            'name', child.name,
                                            'parent_id', child.parent_id,
                                            'children', (
                                                SELECT COALESCE(jsonb_agg(
                                                    jsonb_build_object(
                                                        'id', grandchild.id,
                                                        'name', grandchild.name,
                                                        'parent_id', grandchild.parent_id,
                                                        'components', (
                                                            SELECT COALESCE(jsonb_agg(
                                                                jsonb_build_object(
                                                                    'id', gc.id,
                                                                    'component_key', gc.component_key,
                                                                    'attributes', gc.attributes
                                                                )
                                                            ), '[]'::jsonb)
                                                            FROM components gc
                                                            WHERE gc.entity_id = grandchild.id
                                                        )
                                                    )
                                                ), '[]'::jsonb)
                                                FROM entities grandchild
                                                WHERE grandchild.parent_id = child.id
                                            )
                                        )
                                    ), '[]'::jsonb)
                                    FROM entities child
                                    WHERE child.parent_id = e.id
                                ),
                                'components', (
                                    SELECT COALESCE(jsonb_agg(
                                        jsonb_build_object(
                                            'id', c.id,
                                            'component_key', c.component_key,
                                            'attributes', c.attributes
                                        )
                                    ), '[]'::jsonb)
                                    FROM components c
                                    WHERE c.entity_id = e.id
                                )
                            )
                        ), '[]'::jsonb)
                        FROM entities e
                        WHERE e.scene_id = sc.id
                        AND e.parent_id IS NULL -- Only include root-level entities
                    )
                )
            ) 
            FROM scenes sc 
            WHERE sc.space_id = s.id
        )
    )
    INTO result
    FROM spaces s
    WHERE s.id = _space_id;

    RETURN result;
END;
$$ LANGUAGE plpgsql;
