CREATE OR REPLACE FUNCTION public.create_user(
    email text,
    password text
) RETURNS uuid AS $$
  declare
    user_id uuid;
    encrypted_pw text;
BEGIN
  -- Generate a new user UUID and encrypt the password
  user_id := gen_random_uuid();
  encrypted_pw := crypt(password, gen_salt('bf'));
  
  -- Insert into auth.users table
  INSERT INTO auth.users
    (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES
    ('00000000-0000-0000-0000-000000000000', user_id, 'authenticated', 'authenticated', email, encrypted_pw, '2023-05-03 19:41:43.585805+00', '2023-04-22 13:10:03.275387+00', '2023-04-22 13:10:31.458239+00', '{"provider":"email","providers":["email"]}', '{}', '2023-05-03 19:41:43.580424+00', '2023-05-03 19:41:43.585948+00', '', '', '', '');

  -- Insert into auth.identities table
  INSERT INTO auth.identities
    (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, provider_id)
  VALUES
    (gen_random_uuid(), user_id, format('{"sub":"%s","email":"%s"}', user_id::text, email)::jsonb, 'email', '2023-05-03 19:41:43.582456+00', '2023-05-03 19:41:43.582497+00', '2023-05-03 19:41:43.582497+00', user_id);  -- Providing the user_id as provider_id or a different unique value

  RETURN user_id;
END;
$$ LANGUAGE plpgsql;
DO $$
DECLARE
  i INTEGER;
  email TEXT;
  password TEXT := 'password';  -- Default password for all users
  user_ids uuid[] := ARRAY[]::uuid[];  -- Array to store user IDs
  user_id uuid;
  profile_url TEXT;
  asset_url TEXT;
  space_id uuid;
  scene_name TEXT;
BEGIN
    -- Loop to insert 15 users
    FOR i IN 1..15 LOOP
      -- Construct the email dynamically
      email := format('user%s@example.com', i);  -- Use %s for numbers

      -- Call the create_user function with the constructed email and capture user_id
      user_id := public.create_user(email, password);
      user_ids := array_append(user_ids, user_id);  -- Store user_id in array

      -- Optionally, print each email for verification during execution
      RAISE NOTICE 'Created user with email: %, ID: %', email, user_id;

      -- Insert a user profile for the created user
      INSERT INTO public.user_profiles
        (id, display_name, public_bio, ready_player_me_url_glb)
      VALUES
        (user_id, format('User %s', i), format('This is the bio of user %s.', i), format('https://picsum.photos/seed/picsum/300/300', i));

      -- Insert 30 assets for each user, now including creator_user_id
      FOR j IN 1..30 LOOP
        asset_url := format('https://picsum.photos/seed/picsum/800/600', i, j);  -- Use %s for numbers

        INSERT INTO public.assets
          (id, name, asset_url, creator_user_id, created_at, updated_at)
        VALUES
          (gen_random_uuid(), format('Asset %s', j), asset_url, user_id, now(), now());  -- Include creator_user_id
      END LOOP;

    END LOOP;

    -- Insert spaces, using user_ids from the array
    FOR i IN 1..45 LOOP
      -- Create a new space
      INSERT INTO public.spaces
        (id, name, creator_user_id, created_at, updated_at)
      VALUES
        (gen_random_uuid(), format('Space %s', i), user_ids[((i - 1) % 15) + 1], now(), now())
      RETURNING id INTO space_id;  -- Capture the newly created space ID

      -- Insert 3 scenes for each space
      FOR j IN 1..3 LOOP
        scene_name := format('Scene %s-%s', i, j);  -- Create unique scene names

        INSERT INTO public.scenes
          (id, space_id, name, creator_user_id, created_at, updated_at)
        VALUES
          (gen_random_uuid(), space_id, scene_name, user_ids[((i - 1) % 15) + 1], now(), now());  -- Use the same creator as the space
      END LOOP;

    END LOOP;
END $$;
