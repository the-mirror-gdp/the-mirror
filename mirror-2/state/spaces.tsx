import { createApi, fakeBaseQuery } from '@reduxjs/toolkit/query/react';
import { createSupabaseBrowserClient } from '@/utils/supabase/client';
import { Database } from '@/utils/database.types';
import { generateSpaceName } from '@/actions/name-generator';
import { scenesApi, TAG_NAME_FOR_GENERAL_ENTITY as SCENES_TAG_NAME_FOR_GENERAL_ENTITY } from '@/state/scenes';
import { TAG_NAME_FOR_GENERAL_ENTITY as ENTITIES_TAG_NAME_FOR_GENERAL_ENTITY, entitiesApi } from '@/state/entities';
import { TAG_NAME_FOR_GENERAL_ENTITY as COMPONENTS_TAG_NAME_FOR_GENERAL_ENTITY } from '@/state/components';
import { TAG_NAME_FOR_BUILD_MODE_SPACE_QUERY } from '@/state/shared-cache-tags';

export const TAG_NAME_FOR_GENERAL_ENTITY = 'Spaces'

// Supabase API for spaces
export const spacesApi = createApi({
  reducerPath: 'spacesApi',
  baseQuery: fakeBaseQuery(),
  tagTypes: [TAG_NAME_FOR_GENERAL_ENTITY, SCENES_TAG_NAME_FOR_GENERAL_ENTITY, ENTITIES_TAG_NAME_FOR_GENERAL_ENTITY, TAG_NAME_FOR_BUILD_MODE_SPACE_QUERY, 'LIST'],
  endpoints: (builder) => ({
    createSpace: builder.mutation<any, any>({
      queryFn: async (_, { dispatch }) => {
        const supabase = createSupabaseBrowserClient();
        const { data: { user } } = await supabase.auth.getUser()
        if (!user) {
          throw new Error('User not found')
        }
        const name = await generateSpaceName()
        const { data, error } = await supabase
          .from("spaces")
          .insert([{
            name,
            creator_user_id: user?.id,
            owner_user_id: user.id
          }])
          .select('*')
          .single()

        if (error) {
          return { error: error.message };
        }

        // Now that the space is created, dispatch the `createScene` mutation
        const { data: createSceneData, error: createSceneError } = await dispatch(
          scenesApi.endpoints.createScene.initiate({ name: "Main", space_id: data.id })
        )

        if (createSceneError) {
          return { error: createSceneError };
        }
        // // create root entity
        const { data: createEntityData, error: createEntityError } = await dispatch(
          entitiesApi.endpoints.upsertEntity.initiate({ name: "Root", scene_id: createSceneData.id, isRootEntity: true })
        )

        if (createEntityError) {
          return { error: createEntityError };
        }
        return { data };
      },
      invalidatesTags: [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id: 'LIST' }],
    }),

    getSingleSpace: builder.query<any, string>({
      queryFn: async (spaceId) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from("spaces")
          .select("*")
          .eq("id", spaceId)
          .single()

        if (error) {
          return { error: error.message };
        }
        return { data };
      },
      providesTags: (result, error, id) => [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id }],
    }),

    updateSpace: builder.mutation<Database['public']['Tables']['spaces']['Row'], { id: string, updateData: Partial<Database['public']['Tables']['spaces']['Update']> }>({
      queryFn: async ({ id: spaceId, updateData }) => {
        const supabase = createSupabaseBrowserClient();
        const { data, error } = await supabase
          .from("spaces")
          .update(updateData)
          .eq("id", spaceId)
          .select("*")
          .single();

        if (error) {
          return { error: error.message };
        }

        return { data };
      },
      invalidatesTags: (result, error, { id: spaceId }) => [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id: spaceId }],
    }),

    deleteSpace: builder.mutation<Database['public']['Tables']['spaces']['Row'], string>({
      queryFn: async (spaceId) => {
        const supabase = createSupabaseBrowserClient();
        const { data, error } = await supabase
          .from("spaces")
          .delete()
          .eq("id", spaceId)
          .single();

        if (error) {
          return { error: error.message };
        }

        return { data };
      },
      invalidatesTags: (result, error, spaceId) => [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id: spaceId }],
    }),
  }),
});

// Export the API hooks
export const {
  useGetSingleSpaceQuery,
  useCreateSpaceMutation,
  useUpdateSpaceMutation,
  useDeleteSpaceMutation,
} = spacesApi;

