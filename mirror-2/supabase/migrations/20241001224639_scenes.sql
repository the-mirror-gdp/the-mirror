CREATE OR REPLACE FUNCTION generate_unique_id_scenes()
RETURNS TRIGGER AS $$
DECLARE
    new_id BIGINT;
BEGIN
    LOOP
        new_id := floor(random() * 9007198754740991 + 500000000)::BIGINT;
        -- Check if the generated id already exists
        IF NOT EXISTS (SELECT 1 FROM scenes WHERE id = new_id) THEN
            NEW.id := new_id;
            EXIT;
        END IF;
    END LOOP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE EXTENSION IF NOT EXISTS pg_jsonschema WITH SCHEMA extensions;

CREATE TABLE scenes (
  id BIGINT PRIMARY KEY DEFAULT (floor(random() * 9007198754740991 + 500000000)::BIGINT), -- unique number instead of uuid since the game engine wants a number for this. set a floor above 500000000. 9007198754740991 is below the MAX_SAFE_INTEGER for js
  space_id BIGINT REFERENCES spaces ON DELETE CASCADE NOT NULL, -- delete the scene if space is deleted
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  settings JSONB NOT NULL,
  CONSTRAINT name_length CHECK (char_length(name) >= 0)
  -- TODO implement jsonb schema validation once hardened
  --  CHECK (
  --   jsonb_matches_schema(
  --     '{
  --       "type": "object",
  --       "properties": {
  --         "priority_scripts": { "type": "array", "items": {} },
  --         "physics": {
  --           "type": "object",
  --           "properties": {
  --             "gravity": {
  --               "type": "array",
  --               "items": { "type": "number" },
  --               "minItems": 3,
  --               "maxItems": 3
  --             }
  --           },
  --           "required": ["gravity"]
  --         },
  --         "render": {
  --           "type": "object",
  --           "properties": {
  --             "fog_end": { "type": "number" },
  --             "fog_start": { "type": "number" },
  --             "global_ambient": {
  --               "type": "array",
  --               "items": { "type": "number" },
  --               "minItems": 3,
  --               "maxItems": 3
  --             },
  --             "tonemapping": { "type": "number" },
  --             "fog_color": {
  --               "type": "array",
  --               "items": { "type": "number" },
  --               "minItems": 3,
  --               "maxItems": 3
  --             },
  --             "fog": { "type": "string" },
  --             "skybox": { "type": ["string", "null"] },
  --             "fog_density": { "type": "number" },
  --             "gamma_correction": { "type": "number" },
  --             "exposure": { "type": "number" },
  --             "lightmapSizeMultiplier": { "type": "number" },
  --             "lightmapMaxResolution": { "type": "number" },
  --             "lightmapMode": { "type": "number" },
  --             "skyboxIntensity": { "type": "number" },
  --             "skyboxMip": { "type": "number" },
  --             "skyboxRotation": {
  --               "type": "array",
  --               "items": { "type": "number" },
  --               "minItems": 3,
  --               "maxItems": 3
  --             },
  --             "lightmapFilterEnabled": { "type": "boolean" },
  --             "lightmapFilterRange": { "type": "number" },
  --             "lightmapFilterSmoothness": { "type": "number" },
  --             "ambientBake": { "type": "boolean" },
  --             "ambientBakeNumSamples": { "type": "number" },
  --             "ambientBakeSpherePart": { "type": "number" },
  --             "ambientBakeOcclusionBrightness": { "type": "number" },
  --             "ambientBakeOcclusionContrast": { "type": "number" },
  --             "clusteredLightingEnabled": { "type": "boolean" },
  --             "lightingCells": {
  --               "type": "array",
  --               "items": { "type": "number" },
  --               "minItems": 3,
  --               "maxItems": 3
  --             },
  --             "lightingMaxLightsPerCell": { "type": "number" },
  --             "lightingCookieAtlasResolution": { "type": "number" },
  --             "lightingShadowAtlasResolution": { "type": "number" },
  --             "lightingShadowType": { "type": "number" },
  --             "lightingCookiesEnabled": { "type": "boolean" },
  --             "lightingAreaLightsEnabled": { "type": "boolean" },
  --             "lightingShadowsEnabled": { "type": "boolean" },
  --             "skyType": { "type": "string" },
  --             "skyMeshPosition": {
  --               "type": "array",
  --               "items": { "type": "number" },
  --               "minItems": 3,
  --               "maxItems": 3
  --             },
  --             "skyMeshRotation": {
  --               "type": "array",
  --               "items": { "type": "number" },
  --               "minItems": 3,
  --               "maxItems": 3
  --             },
  --             "skyMeshScale": {
  --               "type": "array",
  --               "items": { "type": "number" },
  --               "minItems": 3,
  --               "maxItems": 3
  --             },
  --             "skyCenter": {
  --               "type": "array",
  --               "items": { "type": "number" },
  --               "minItems": 3,
  --               "maxItems": 3
  --             }
  --           },
  --           "required": [
  --             "fog_end", "fog_start", "global_ambient", "tonemapping",
  --             "fog_color", "fog", "skybox", "fog_density", "gamma_correction",
  --             "exposure", "lightmapSizeMultiplier", "lightmapMaxResolution",
  --             "lightmapMode", "skyboxIntensity", "skyboxMip", "skyboxRotation",
  --             "lightmapFilterEnabled", "lightmapFilterRange", "lightmapFilterSmoothness",
  --             "ambientBake", "ambientBakeNumSamples", "ambientBakeSpherePart",
  --             "ambientBakeOcclusionBrightness", "ambientBakeOcclusionContrast",
  --             "clusteredLightingEnabled", "lightingCells", "lightingMaxLightsPerCell",
  --             "lightingCookieAtlasResolution", "lightingShadowAtlasResolution",
  --             "lightingShadowType", "lightingCookiesEnabled", "lightingAreaLightsEnabled",
  --             "lightingShadowsEnabled", "skyType", "skyMeshPosition", "skyMeshRotation",
  --             "skyMeshScale", "skyCenter"
  --           ]
  --         }
  --       },
  --       "required": ["priority_scripts", "physics", "render"]
  --     }',
  --     settings
  --   )
  -- )
);


-- Create the trigger to generate a unique id
CREATE TRIGGER ensure_unique_id
BEFORE INSERT ON scenes
FOR EACH ROW
WHEN (NEW.id IS NULL)
EXECUTE FUNCTION generate_unique_id_scenes();

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
