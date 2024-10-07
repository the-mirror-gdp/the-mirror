CREATE OR REPLACE FUNCTION get_space_with_children(space_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN (
    SELECT jsonb_build_object(
      'id', s.id,
      'name', s.name,
      'scenes', (
        SELECT COALESCE(jsonb_agg(
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
                    SELECT COALESCE(jsonb_agg(child.id), '[]'::jsonb)
                    FROM entities AS child
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
            )
          )
        ), '[]'::jsonb)
        FROM scenes sc
        WHERE sc.space_id = s.id
      )
    )
    FROM spaces s
    WHERE s.id = space_id
  );
END;
$$;
