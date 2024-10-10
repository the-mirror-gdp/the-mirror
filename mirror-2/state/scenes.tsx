import { createSlice, createEntityAdapter, createAsyncThunk } from '@reduxjs/toolkit';
import { createApi, fakeBaseQuery } from '@reduxjs/toolkit/query/react';
import { createSupabaseBrowserClient } from '@/utils/supabase/client';
import { entitiesApi } from '@/state/entities';
import { Database } from '@/utils/database.types';

export const TAG_NAME_FOR_GENERAL_ENTITY = 'Scenes'
export type DatabaseScene = Database["public"]["Tables"]["scenes"]["Row"];

// Supabase API for spaces
export const scenesApi = createApi({
  reducerPath: 'scenesApi',
  baseQuery: fakeBaseQuery(),
  tagTypes: [TAG_NAME_FOR_GENERAL_ENTITY, 'LIST'],
  endpoints: (builder) => ({

    /**
     * Scenes
    */
    createScene: builder.mutation<any, { name: string, space_id: string }>({
      queryFn: async ({ name, space_id }, { dispatch }) => {
        const supabase = createSupabaseBrowserClient();
        const { data: { user }, error: authError } = await supabase.auth.getUser();

        if (!user) {
          return { error: 'User not found' };
        }

        if (!space_id) {
          return { error: 'No spaceId provided' };
        }

        const { data, error } = await supabase
          .from("scenes")
          .insert([{
            name,
            space_id,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          }])
          .select('*')
          .single();
        if (error) {
          return { error: error.message };
        }
        // create root entity for this scene if it doesn't exist
        const { data: entityCheck, error: entityCheckError } = await supabase
          .from("entities")
          .select('*')
          .eq("scene_id", data.id)
          .is("parent_id", null)
          .maybeSingle();

        if (entityCheckError) {
          return { error: entityCheckError };
        }

        if (!entityCheck) {
          const { data: createEntityData, error: createEntityError } = await dispatch(
            entitiesApi.endpoints.createEntity.initiate({ name: "Root", scene_id: data.id, isRootEntity: true })
          )
          if (createEntityError) {
            return { error: createEntityError };
          }

          // create blank entity for the root entity bc this is a flow the user will always do, so save them a step.
          const { data: createEntityData2, error: createEntityError2 } = await dispatch(
            entitiesApi.endpoints.createEntity.initiate({ name: "New Entity", scene_id: data.id })
          )
          if (createEntityError2) {
            return { error: createEntityError2 };
          }
        }

        return { data };
      },
      invalidatesTags: [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id: 'LIST' }],
    }),

    /**
     * Get a single Scene by its ID
     */
    getSingleScene: builder.query<any, string>({
      queryFn: async (sceneId) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from("scenes")
          .select("*")
          .eq("id", sceneId)
          .single();

        if (error) {
          return { error: error.message };
        }
        return { data };
      },
      providesTags: (result, error, sceneId) => [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id: sceneId }], // Provide the scene tag based on sceneId
    }),

    /**
     * Get all Scenes for a given space
     */
    getAllScenes: builder.query<any, string>({
      queryFn: async (spaceId) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from("scenes")
          .select("*")
          .eq("space_id", spaceId);

        if (error) {
          return { error: error.message };
        }
        return { data };
      },
      providesTags: (result) =>
        result
          ? [
            ...result.map(({ id }) => ({ type: TAG_NAME_FOR_GENERAL_ENTITY, id })),
            { type: TAG_NAME_FOR_GENERAL_ENTITY, id: 'LIST' },
          ]
          : [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id: 'LIST' }],
    }),

    /**
     * Update a Scene by its ID
     */
    updateScene: builder.mutation<any, { id: string, name?: string }>
      ({
        queryFn: async ({ id: sceneId, name }) => {
          const supabase = createSupabaseBrowserClient();

          const { data, error } = await supabase
            .from("scenes")
            .update({ name })
            .eq("id", sceneId)
            .single();

          if (error) {
            return { error: error.message };
          }
          return { data };
        },
        invalidatesTags: (result, error, { id: sceneId }) => [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id: sceneId }], // Invalidate tag for sceneId
      }),

    /**
     * Delete a Scene by its ID
     */
    deleteScene: builder.mutation<any, string>({
      queryFn: async (sceneId) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from("scenes")
          .delete()
          .eq("id", sceneId)
          .single();

        if (error) {
          return { error: error.message };
        }
        return { data };
      },
      invalidatesTags: (result, error, sceneId) => [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id: sceneId }]
    }),


  }),
});

// Export the API hooks
export const {
  useCreateSceneMutation, useGetAllScenesQuery, useLazyGetAllScenesQuery, useUpdateSceneMutation, useGetSingleSceneQuery, useLazyGetSingleSceneQuery, useDeleteSceneMutation,
} = scenesApi;
