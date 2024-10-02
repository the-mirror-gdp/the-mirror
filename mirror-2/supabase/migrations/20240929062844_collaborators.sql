
-- Create the space_user_collaborators table
create table space_user_collaborators (
  id uuid not null primary key default uuid_generate_v4(),
  space_id uuid references spaces(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  created_at timestamp with time zone not null default now(),
  constraint unique_space_user unique(space_id, user_id)
);

-- Enable RLS for space_user_collaborators
alter table space_user_collaborators
  enable row level security;

-- Only space owners can add collaborators
create policy "Only space owners can add collaborators" 
on space_user_collaborators
for insert 
with check (
  exists (
    select 1 from spaces 
    where spaces.id = space_id 
    and spaces.creator_user_id = auth.uid()
  )
);

-- Policy for selecting space_user_collaborators
create policy "Users can view where they are a collaborator" 
on space_user_collaborators
for select 
using (user_id = auth.uid());


-- Policy for collaborators to view spaces
create policy "Collaborators can view spaces" 
on spaces
for select 
using (
  exists (
    select 1 from space_user_collaborators 
    where space_user_collaborators.space_id = spaces.id 
    and space_user_collaborators.user_id = auth.uid()
  )
);
