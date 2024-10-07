import { createSlice, createEntityAdapter, createAsyncThunk } from '@reduxjs/toolkit';
import { createApi, fakeBaseQuery } from '@reduxjs/toolkit/query/react';
import { createSupabaseBrowserClient } from '@/utils/supabase/client';
import { Database } from '@/utils/database.types';
import { generateSpaceName } from '@/actions/name-generator';

export const TAG_NAME_FOR_GENERAL_ENTITY = 'Spaces'

// Supabase API for spaces
export const spacesApi = createApi({
  reducerPath: 'spacesApi',
  baseQuery: fakeBaseQuery(),
  tagTypes: [TAG_NAME_FOR_GENERAL_ENTITY, 'LIST'],
  endpoints: (builder) => ({
    createSpace: builder.mutation<any, any>({
      queryFn: async () => {
        const supabase = createSupabaseBrowserClient();
        const { data: { user } } = await supabase.auth.getUser()
        if (!user) {
          throw new Error('User not found')
        }
        const { data, error } = await supabase
          .from("spaces")
          .insert([{
            name: await generateSpaceName(),
            creator_user_id: user?.id,
            owner_user_id: user.id
          }])
          .select('*')
          .single()

        if (error) {
          return { error: error.message };
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
 * Helper: includes scenes, entities, assets, etc.
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
          const sceneIds = result.scenes?.map(scene => ({ type: 'Scenes', id: scene.id })) || [];
          const entityIds = result.scenes?.flatMap(scene =>
            scene.entities?.map(entity => ({ type: 'Entities', id: entity.id }))
          ) || [];
          const componentIds = result.scenes?.flatMap(scene =>
            scene.entities?.flatMap(entity =>
              entity.components?.map(component => ({ type: 'Components', id: component.id }))
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


    updateSpace: builder.mutation<Database['public']['Tables']['spaces']['Row'], { spaceId: string, updateData: Partial<Database['public']['Tables']['spaces']['Update']> }>({
      queryFn: async ({ spaceId, updateData }) => {
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
      invalidatesTags: (result, error, { spaceId }) => [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id: spaceId }],
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


// not sure if this is needed since the RTK query API handles things so well
// // Slice for managing space-related state
// const spacesSlice = createSlice({
//   name: 'spaces',
//   initialState: initialSpacesState,
//   reducers: {},
//   extraReducers: (builder) => {
//     builder
//       .addMatcher(spacesApi.endpoints.createSpace.matchFulfilled, (state, action) => {
//         spacesAdapter.addOne(state, action.payload);
//       })
//       .addMatcher(spacesApi.endpoints.getSingleSpace.matchFulfilled, (state, action) => {
//         spacesAdapter.setOne(state, action.payload);
//       })
//       .addMatcher(spacesApi.endpoints.updateSpace.matchFulfilled, (state, action) => {
//         spacesAdapter.updateOne(state, { id: action.payload.id, changes: action.payload });
//       })
//       .addMatcher(spacesApi.endpoints.deleteSpace.matchFulfilled, (state, action) => {
//         debugger; // check spaceId in orginalArgs
//         spacesAdapter.removeOne(state, action.meta.arg.originalArgs);
//       });
//   }
// });



// // Export the slice reducers
// export const spacesReducer = spacesSlice.reducer;

// Export the API hooks
export const {
  useGetSingleSpaceQuery,
  useGetSingleSpaceBuildModeQuery,
  useLazyGetSingleSpaceBuildModeQuery,
  useCreateSpaceMutation,
  useUpdateSpaceMutation,
  useDeleteSpaceMutation,
} = spacesApi;
