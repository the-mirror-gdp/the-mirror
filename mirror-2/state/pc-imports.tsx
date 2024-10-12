import { createApi, fakeBaseQuery } from '@reduxjs/toolkit/query/react';
import { createSupabaseBrowserClient } from '@/utils/supabase/client';
import { Database } from '@/utils/database.types';
import { createListenerMiddleware, isAnyOf } from '@reduxjs/toolkit';
import { sendAnalyticsEvent } from '@/utils/analytics/analytics';

// Supabase API for pc_imports
export const pcImportsApi = createApi({
  reducerPath: 'pcImportsApi',
  baseQuery: fakeBaseQuery(),
  tagTypes: ['PcImports', 'LIST'],
  endpoints: (builder) => ({
    createPcImport: builder.mutation<any, any>({
      queryFn: async ({ displayName }) => {
        const supabase = createSupabaseBrowserClient();
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) {
          throw new Error('User not found');
        }

        const { data, error } = await supabase
          .from("pc_imports")
          .insert([{
            display_name: displayName,
            owner_user_id: user.id,
          }])
          .select('*')
          .single();

        if (error) {
          return { error: error.message };
        }

        return { data };
      },
      invalidatesTags: [{ type: 'PcImports', id: 'LIST' }],
    }),

    getSinglePcImport: builder.query<any, string>({
      queryFn: async (importId) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from("pc_imports")
          .select("*")
          .eq("id", importId)
          .single();

        if (error) {
          return { error: error.message };
        }
        return { data };
      },
      providesTags: (result, error, id) => [{ type: 'PcImports', id }],
    }),

    updatePcImport: builder.mutation<Database['public']['Tables']['pc_imports']['Row'], { id: string, updateData: Partial<Database['public']['Tables']['pc_imports']['Update']> }>({
      queryFn: async ({ id: importId, updateData }) => {
        const supabase = createSupabaseBrowserClient();
        const { data, error } = await supabase
          .from("pc_imports")
          .update(updateData)
          .eq("id", importId)
          .select("*")
          .single();

        if (error) {
          return { error: error.message };
        }

        return { data };
      },
      invalidatesTags: (result, error, { id: importId }) => [{ type: 'PcImports', id: importId }],
    }),

    deletePcImport: builder.mutation<Database['public']['Tables']['pc_imports']['Row'], string>({
      queryFn: async (importId) => {
        const supabase = createSupabaseBrowserClient();
        const { data, error } = await supabase
          .from("pc_imports")
          .delete()
          .eq("id", importId)
          .single();

        if (error) {
          return { error: error.message };
        }

        return { data };
      },
      invalidatesTags: (result, error, importId) => [{ type: 'PcImports', id: importId }],
    }),
  }),
});

// Middleware for analytics or other side-effects
export const listenerMiddlewarePcImports = createListenerMiddleware();
listenerMiddlewarePcImports.startListening({
  matcher: isAnyOf(
    pcImportsApi.endpoints.createPcImport.matchFulfilled  // Match fulfilled action of the createPcImport mutation
  ),
  effect: async (action, listenerApi) => {
    sendAnalyticsEvent("Create PcImport");
  },
});

// Export the API hooks
export const {
  useGetSinglePcImportQuery,
  useCreatePcImportMutation,
  useUpdatePcImportMutation,
  useDeletePcImportMutation,
} = pcImportsApi;
