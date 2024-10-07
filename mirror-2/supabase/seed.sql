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
  file_url TEXT;
  thumbnail_url TEXT;
  space_id uuid;
  scene_id uuid;
  entity_name TEXT;
  entity_id uuid;
  component_name TEXT;
  public_page_image_urls text[];
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

      -- Insert 30 assets for each user, now including creator_user_id, owner_user_id, and thumbnail_url
      FOR j IN 1..30 LOOP
        file_url := format('https://picsum.photos/seed/picsum/800/600', i, j);  -- Use %s for numbers
        thumbnail_url := format('https://picsum.photos/seed/picsum/200/150', i, j);  -- Use %s for thumbnails

        INSERT INTO public.assets
          (id, name, description, file_url, thumbnail_url, creator_user_id, owner_user_id, created_at, updated_at)
        VALUES
          (gen_random_uuid(), format('Asset %s', j), 'This is a placeholder description for the asset.', file_url, thumbnail_url, user_id, user_id, now(), now());  -- Added thumbnail_url and description
      END LOOP;

    END LOOP;

    -- Insert spaces, using user_ids from the array and setting both owner_user_id and creator_user_id
    FOR i IN 1..45 LOOP
      -- Create an array of image URLs for the space's public_page_image_urls
      public_page_image_urls := ARRAY[
        format('https://picsum.photos/seed/picsum/%s/800', i),
        format('https://picsum.photos/seed/picsum/%s/801', i),
        format('https://picsum.photos/seed/picsum/%s/802', i)
      ];

      -- Create a new space
      INSERT INTO public.spaces
        (id, name, description, public_page_image_urls, creator_user_id, owner_user_id, created_at, updated_at)
      VALUES
        (gen_random_uuid(), format('Space %s', i), 'This is a placeholder description for the space.', public_page_image_urls, user_ids[((i - 1) % 15) + 1], user_ids[((i - 1) % 15) + 1], now(), now())  -- Added public_page_image_urls and description
      RETURNING id INTO space_id;  -- Capture the newly created space ID

      -- Insert 3 space_versions for each space
      FOR v IN 1..3 LOOP
        INSERT INTO public.space_versions
          (id, name, space_id, created_at, updated_at)
        VALUES
          (gen_random_uuid(), format('Version %s-%s', i, v), space_id, now(), now());
      END LOOP;

      -- Insert 3 scenes for each space
      FOR j IN 1..3 LOOP
        -- Create a new scene
        INSERT INTO public.scenes
          (id, space_id, name, created_at, updated_at)
        VALUES
          (gen_random_uuid(), space_id, format('Scene %s-%s', i, j), now(), now())
        RETURNING id INTO scene_id;  -- Capture the newly created scene ID

        -- Insert 20 entities for each scene
        FOR k IN 1..20 LOOP
          entity_name := format('Entity %s-%s-%s', i, j, k);  -- Create unique entity names

          -- Insert entity
          INSERT INTO public.entities
            (id, name, scene_id, created_at, updated_at)
          VALUES
            (gen_random_uuid(), entity_name, scene_id, now(), now())
          RETURNING id INTO entity_id;  -- Capture the newly created entity ID

          -- Insert 3 components for each entity, including component_key and attributes
          FOR c IN 1..3 LOOP

            INSERT INTO public.components
              (id, entity_id, component_key, attributes, created_at, updated_at)
            VALUES
              (gen_random_uuid(), entity_id, 'script', '{"attribute": "value"}'::jsonb, now(), now());  -- Add component_key and attributes
          END LOOP;

        END LOOP;

      END LOOP;

    END LOOP;
END $$;
