import { createSlice, createEntityAdapter, createAsyncThunk } from '@reduxjs/toolkit';
import { createApi, fakeBaseQuery } from '@reduxjs/toolkit/query/react';
import { createSupabaseBrowserClient } from '@/utils/supabase/client';
import { Database } from '@/utils/database.types';
import { TAG_NAME_FOR_BUILD_MODE_SPACE_QUERY } from '@/state/shared-cache-tags';


export const TAG_NAME_FOR_GENERAL_ENTITY = 'Entities'

// Supabase API for spaces
export const entitiesApi = createApi({
  reducerPath: 'entitiesApi',
  baseQuery: fakeBaseQuery(),
  tagTypes: [TAG_NAME_FOR_GENERAL_ENTITY, 'LIST', TAG_NAME_FOR_BUILD_MODE_SPACE_QUERY],
  endpoints: (builder) => ({
    createEntity: builder.mutation<any, { name: string, scene_id: string, children?: string[], is_root?: boolean, parent_id?: string }>({
      queryFn: async ({ name, scene_id, children, is_root, parent_id }) => {
        const supabase = createSupabaseBrowserClient();
        const { data: { user }, error: authError } = await supabase.auth.getUser();

        if (!user) {
          return { error: 'User not found' };
        }

        if (!scene_id) {
          return { error: 'No scene_id provided' };
        }

        // if no parent_id and not is_root, find the root entity
        if (!parent_id && !is_root) {
          const { data: rootEntity, error: rootEntityError } = await supabase
            .from("entities")
            .select("*")
            .eq("scene_id", scene_id)
            .eq("is_root", true)
            .single();

          if (rootEntityError) {
            return { error: rootEntityError.message };
          }

          parent_id = rootEntity.id;
        }

        const { data, error } = await supabase
          .from("entities")
          .insert([{
            name,
            scene_id,
            is_root,
            children: children || [],
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          }])
          .select('*')
          .single();

        if (error) {
          return { error: error.message };
        }

        // update the parent of the new entity to have it in the children array
        if (!is_root && parent_id) {
          const { data: addChildToEntityData, error: addChildToEntityError } = await supabase
            .rpc('add_child_to_entity', { _parent_id: parent_id, _child_id: data.id });

          if (addChildToEntityError) {
            return { error: addChildToEntityError };
          }
        }
        return { data };
      },
      invalidatesTags: [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id: 'LIST' }],

    }),

    getAllEntities: builder.query<any, string>({
      queryFn: async (sceneId) => {
        const supabase = createSupabaseBrowserClient();

        if (!sceneId) {
          return { error: 'No scene_id provided' };
        }

        const { data, error } = await supabase
          .from("entities")
          .select("*")
          .eq("scene_id", sceneId);

        // const { data, error } = await supabase
        // .rpc('get_entities_with_children', { _scene_id: sceneId }); // _scene_id is the name of the parameter in the function to not clash with column name scene_id

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

    getSingleEntity: builder.query<any, string>({
      queryFn: async (entityId) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from("entities")
          .select("*")
          .eq("id", entityId)
          .single();
        // Call the Postgres function get_entity_with_children
        // const { data, error } = await supabase
        //   .rpc('get_entity_with_children', { entity_id: entityId });


        if (error) {
          return { error: error.message };
        }
        return { data };
      },
      providesTags: (result, error, entityId) => [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id: entityId }], // Provide the entity tag based on entityId
    }),

    updateEntity: builder.mutation<any, { id: string, updateData: Record<string, any> }>({
      queryFn: async ({ id: entityId, updateData }) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from("entities")
          .update(updateData)
          .eq("id", entityId)
          .single();

        if (error) {
          debugger
          return { error: error.message };
        }
        return { data };
      },
      invalidatesTags: (result, error, { id: entityId }) => [
        { type: TAG_NAME_FOR_GENERAL_ENTITY, id: entityId },
        TAG_NAME_FOR_BUILD_MODE_SPACE_QUERY
      ], // Invalidate tag for entityId
    }),


    deleteEntity: builder.mutation<any, string>({
      queryFn: async (entityId) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from("entities")
          .delete()
          .eq("id", entityId)
          .single();

        if (error) {
          return { error: error.message };
        }
        return { data };
      },
      invalidatesTags: (result, error, entityId) => [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id: entityId }]
    }),

  }),
});


// Export the API hooks
export const {
  useCreateEntityMutation, useGetAllEntitiesQuery, useUpdateEntityMutation, useGetSingleEntityQuery, useLazyGetAllEntitiesQuery, useDeleteEntityMutation
} = entitiesApi;
