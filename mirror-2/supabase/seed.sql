-- Begin a transaction
begin;

-- Insert users into the auth.users table
insert into auth.users (id, email)
values 
  ('9b0c9dfc-7f5d-4de5-9f3d-159a063c987a', 'user1@example.com'),
  ('b33ea2f6-d0d8-4c9c-87d1-70b1c102a84d', 'user2@example.com');

-- Insert profiles into the user_profiles table
insert into public.user_profiles (id, display_name, public_bio, ready_player_me_url_glb)
values 
  ('9b0c9dfc-7f5d-4de5-9f3d-159a063c987a', 'User One', 'Bio for User One', 'https://example.com/user1.glb'),
  ('b33ea2f6-d0d8-4c9c-87d1-70b1c102a84d', 'User Two', 'Bio for User Two', 'https://example.com/user2.glb');

-- Commit the transaction
commit;
