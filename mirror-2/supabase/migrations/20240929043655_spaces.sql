CREATE OR REPLACE FUNCTION generate_unique_id_spaces()
RETURNS TRIGGER AS $$
DECLARE
    new_id BIGINT;
BEGIN
    LOOP
        new_id := floor(random() * 9007198754740991 + 500000000)::BIGINT;
        -- Check if the generated id already exists
        IF NOT EXISTS (SELECT 1 FROM spaces WHERE id = new_id) THEN
            NEW.id := new_id;
            EXIT;
        END IF;
    END LOOP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

create table spaces (
  id BIGINT PRIMARY KEY DEFAULT (floor(random() * 9007198754740991 + 500000000)::BIGINT), -- unique number instead of uuid since the game engine wants a number for this. set a floor above 500000000. 9007198754740991 is below the MAX_SAFE_INTEGER for js
  name text not null,
  description text,
  public_page_image_urls text[] default '{}',
  owner_user_id uuid references auth.users(id) not null,  -- owner is different from creator. Spaces can be transferred and we want to retain the creator
  creator_user_id uuid references auth.users(id) not null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint name_length check (char_length(name) >= 3)
  );

-- Create the trigger to generate a unique id
CREATE TRIGGER ensure_unique_id
BEFORE INSERT ON spaces
FOR EACH ROW
WHEN (NEW.id IS NULL)
EXECUTE FUNCTION generate_unique_id_spaces();


  -- add RLS
alter table spaces
  enable row level security;


-- Policy for creating spaces
create policy "Users can create their own spaces" 
on spaces
for insert 
with check (
  owner_user_id = auth.uid() 
  and creator_user_id = auth.uid()
);

-- Policy for selecting spaces
create policy "Users can view their own spaces" 
on spaces
for select 
using (
  owner_user_id = auth.uid()
);

-- Policy for updating spaces
create policy "Users can update their own spaces" 
on spaces
for update 
using (owner_user_id = auth.uid());

-- Policy for deleting spaces
create policy "Users can delete their own spaces" 
on spaces
for delete 
using (owner_user_id = auth.uid());
