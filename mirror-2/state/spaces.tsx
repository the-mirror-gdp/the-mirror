import { createApi, fakeBaseQuery } from '@reduxjs/toolkit/query/react';
import { createSupabaseBrowserClient } from '@/utils/supabase/client';
import { Database } from '@/utils/database.types';
import { generateSpaceName } from '@/actions/name-generator';
import { scenesApi, TAG_NAME_FOR_GENERAL_ENTITY as SCENES_TAG_NAME_FOR_GENERAL_ENTITY } from '@/state/scenes';
import { TAG_NAME_FOR_GENERAL_ENTITY as ENTITIES_TAG_NAME_FOR_GENERAL_ENTITY } from '@/state/entities';
import { TAG_NAME_FOR_GENERAL_ENTITY as COMPONENTS_TAG_NAME_FOR_GENERAL_ENTITY } from '@/state/components';

export const TAG_NAME_FOR_GENERAL_ENTITY = 'Spaces'

// Supabase API for spaces
export const spacesApi = createApi({
  reducerPath: 'spacesApi',
  baseQuery: fakeBaseQuery(),
  tagTypes: [TAG_NAME_FOR_GENERAL_ENTITY, SCENES_TAG_NAME_FOR_GENERAL_ENTITY, ENTITIES_TAG_NAME_FOR_GENERAL_ENTITY, 'LIST'],
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
        const result = await dispatch(
          scenesApi.endpoints.createScene.initiate({ name: "Main", space_id: data.id })
        ).unwrap(); // .unwrap() to handle the promise correctly

        if (result.error) {
          return { error: result.error };
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

    /**
 * Helper: includes scenes, entities, assets,, components, etc.
 */
    getSingleSpaceBuildMode: builder.query<any, string>({
      queryFn: async (spaceId) => {
        const supabase = createSupabaseBrowserClient();

        // Nested select with joins for scenes, entities, and components
        const { data, error } = await supabase
          .from("spaces")
          .select(`
                *,
                scenes (
                  *,
                  entities (
                    *,
                    components (*)
                  )
                )
              `)
          .eq("id", spaceId)
          .single();

        if (error) {
          return { error: error.message };
        }

        return { data };
      },
      providesTags: (result, error, spaceId) => {
        if (result) {
          // Extract scene, entity, and component ids for proper tag management
          const sceneIds = result.scenes?.map(scene => ({ type: SCENES_TAG_NAME_FOR_GENERAL_ENTITY, id: scene.id })) || [];
          const entityIds = result.scenes?.flatMap(scene =>
            scene.entities?.map(entity => ({ type: ENTITIES_TAG_NAME_FOR_GENERAL_ENTITY, id: entity.id }))
          ) || [];
          const componentIds = result.scenes?.flatMap(scene =>
            scene.entities?.flatMap(entity =>
              entity.components?.map(component => ({ type: COMPONENTS_TAG_NAME_FOR_GENERAL_ENTITY, id: component.id }))
            )
          ) || [];

          // Return tags for space, scenes, entities, and components
          return [
            { type: TAG_NAME_FOR_GENERAL_ENTITY, id: spaceId },
            ...sceneIds,
            ...entityIds,
            ...componentIds
          ];
        }
        return [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id: spaceId }];
      }
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
  useGetSingleSpaceBuildModeQuery,
  useLazyGetSingleSpaceBuildModeQuery,
  useCreateSpaceMutation,
  useUpdateSpaceMutation,
  useDeleteSpaceMutation,
} = spacesApi;
