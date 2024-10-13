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

create table scenes (
  id BIGINT PRIMARY KEY DEFAULT (floor(random() * 9007198754740991 + 500000000)::BIGINT), -- unique number instead of uuid since the game engine wants a number for this. set a floor above 500000000. 9007198754740991 is below the MAX_SAFE_INTEGER for js
  space_id BIGINT references spaces on delete cascade not null, -- delete the scene if space is deleted
  name text not null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint name_length check (char_length(name) >= 0)
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
