create table spaces (
  id uuid not null primary key default uuid_generate_v4(),
  name text not null,
  owner_user_id uuid references auth.users(id) not null,  -- owner is different from creator. Spaces can be transferred and we want to retain the creator
  creator_user_id uuid references auth.users(id) not null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint name_length check (char_length(name) >= 3)
  );

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
