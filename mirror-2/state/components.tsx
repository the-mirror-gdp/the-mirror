import { createSlice, createEntityAdapter, createAsyncThunk } from '@reduxjs/toolkit';
import { createApi, fakeBaseQuery } from '@reduxjs/toolkit/query/react';
import { createSupabaseBrowserClient } from '@/utils/supabase/client';
import { Database } from '@/utils/database.types';

export const TAG_NAME_FOR_GENERAL_ENTITY = 'Components'
const TABLE_NAME = "components"
export type ComponentKey = Database['public']['Enums']['component_key'];
// Supabase API for spaces
export const componentsApi = createApi({
  reducerPath: 'componentsApi',
  baseQuery: fakeBaseQuery(),
  tagTypes: [TAG_NAME_FOR_GENERAL_ENTITY, 'LIST'],
  endpoints: (builder) => ({
    createComponent: builder.mutation<any, { name: string, entity_id: string, component_key: ComponentKey }>({
      queryFn: async ({ entity_id, component_key }) => {
        const supabase = createSupabaseBrowserClient();
        const { data: { user }, error: authError } = await supabase.auth.getUser();

        if (!user) {
          return { error: 'User not found' };
        }

        if (!entity_id) {
          return { error: 'No entity_id provided' };
        }

        const { data, error } = await supabase
          .from(TABLE_NAME)
          .insert([{
            entity_id,
            component_key,
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

    getAllComponents: builder.query<any, string>({
      queryFn: async (entityId) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from(TABLE_NAME)
          .select("*")
          .eq("entity_id", entityId);

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

    getSingleComponent: builder.query<any, string>({
      queryFn: async (id) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from(TABLE_NAME)
          .select("*")
          .eq("id", id)
          .single();

        if (error) {
          return { error: error.message };
        }
        return { data };
      },
      providesTags: (result, error, id) => [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id }],
    }),

    updateComponent: builder.mutation<any, { id: string, updateData: Record<string, any> }>({
      queryFn: async ({ id, updateData }) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from(TABLE_NAME)
          .update(updateData)
          .eq("id", id)
          .single();

        if (error) {
          return { error: error.message };
        }
        return { data };
      },
      invalidatesTags: (result, error, { id }) => [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id }],
    }),

    deleteComponent: builder.mutation<any, string>({
      queryFn: async (id) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from(TABLE_NAME)
          .delete()
          .eq("id", id)
          .single();

        if (error) {
          return { error: error.message };
        }
        return { data };
      },
      invalidatesTags: (result, error, id) => [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id }]
    }),

  }),
});

// Export the API hooks
export const {
  useCreateComponentMutation, useGetAllComponentsQuery, useUpdateComponentMutation, useGetSingleComponentQuery, useLazyGetAllComponentsQuery, useDeleteComponentMutation
} = componentsApi;
