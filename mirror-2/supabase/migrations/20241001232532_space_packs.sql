-- space_packs are an IMMUTABLE version of a space, used for exporting/importing, publishing a Space, etc.

create extension pg_jsonschema with schema extensions;

CREATE OR REPLACE FUNCTION generate_unique_id_space_packs()
RETURNS TRIGGER AS $$
DECLARE
    new_id BIGINT;
BEGIN
    LOOP
        new_id := floor(random() * 9007198754740991 + 500000000)::BIGINT;
        -- Check if the generated id already exists
        IF NOT EXISTS (SELECT 1 FROM space_packs WHERE id = new_id) THEN
            NEW.id := new_id;
            EXIT;
        END IF;
    END LOOP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

create table space_packs (
  id BIGINT PRIMARY KEY DEFAULT (floor(random() * 9007198754740991 + 500000000)::BIGINT), -- unique number instead of uuid since spaces also use a number id. set a floor above 500000000. 9007198754740991 is below the MAX_SAFE_INTEGER for js
  space_id BIGINT references spaces not null,
  -- TODO add JSON schema validation
  data jsonb not null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
  );

-- Create the trigger to generate a unique id
CREATE TRIGGER ensure_unique_id
BEFORE INSERT ON space_packs
FOR EACH ROW
WHEN (NEW.id IS NULL)
EXECUTE FUNCTION generate_unique_id_space_packs();

  -- add RLS
alter table space_packs
  enable row level security;

-- Policy for space owners
create policy "Owners can view their own space_packs" 
on space_packs
for select 
using (
  exists (
    select 1 from spaces
    where spaces.id = space_packs.space_id
    and spaces.owner_user_id = auth.uid()
  )
);

-- Policy for selecting space_packs
create policy "Users can create their own space_packs" 
on space_packs
for insert 
with check (
  exists (
    select 1 from spaces
    where spaces.id = space_packs.space_id
    and spaces.owner_user_id = auth.uid()
  )
);

-- Policy for updating space_packs
create policy "Users can update their own space_packs" 
on space_packs
for update 
using (
  exists (
    select 1 from spaces
    where spaces.id = space_packs.space_id
    and spaces.owner_user_id = auth.uid()
  )
);

-- Policy for deleting space_packs
create policy "Users can delete their own space_packs" 
on space_packs
for delete 
using (
  exists (
    select 1 from spaces
    where spaces.id = space_packs.space_id
    and spaces.owner_user_id = auth.uid()
  )
);
