import { createSlice, createEntityAdapter, createAsyncThunk } from '@reduxjs/toolkit';
import { createApi, fakeBaseQuery } from '@reduxjs/toolkit/query/react';
import { createSupabaseBrowserClient } from '@/utils/supabase/client';
import { Database } from '@/utils/database.types';

export const TAG_NAME_FOR_GENERAL_ENTITY = 'Scenes'

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
      queryFn: async ({ name, space_id }) => {
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
    updateScene: builder.mutation<any, { sceneId: string, updateData: Record<string, any> }>({
      queryFn: async ({ sceneId, updateData }) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from("scenes")
          .update(updateData)
          .eq("id", sceneId)
          .single();

        if (error) {
          return { error: error.message };
        }
        return { data };
      },
      invalidatesTags: (result, error, { sceneId }) => [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id: sceneId }], // Invalidate tag for sceneId
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

// not sure if this is needed since the RTK query API handles things so well
// Slice for managing space-related state
// const spacesSlice = createSlice({
//   name: 'spaces',
//   initialState: initialScenesState,
//   reducers: {},
//   extraReducers: (builder) => {
//     builder
//       .addMatcher(scenesApi.endpoints.createScene.matchFulfilled, (state, action) => {
//         scenesAdapter.addOne(state, action.payload);
//       })
//       .addMatcher(scenesApi.endpoints.getSingleScene.matchFulfilled, (state, action) => {
//         scenesAdapter.setOne(state, action.payload);
//       })
//       .addMatcher(scenesApi.endpoints.updateScene.matchFulfilled, (state, action) => {
//         scenesAdapter.updateOne(state, { id: action.payload.id, changes: action.payload });
//       })
//       .addMatcher(scenesApi.endpoints.deleteScene.matchFulfilled, (state, action) => {
//         debugger; // check spaceId in orginalArgs
//         scenesAdapter.removeOne(state, action.meta.arg.originalArgs);
//       });
//   }
// });

// Export the slice reducers
// export const scenesReducer = spacesSlice.reducer;

// Export the API hooks
export const {
  useCreateSceneMutation, useGetAllScenesQuery, useUpdateSceneMutation, useGetSingleSceneQuery, useLazyGetSingleSceneQuery, useDeleteSceneMutation,
} = scenesApi;
