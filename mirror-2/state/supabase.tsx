"use client"; // we want to use client-side only because supabase tracks auth clientside
import { createSupabaseBrowserClient } from "@/utils/supabase/client";
import { createApi, fakeBaseQuery } from '@reduxjs/toolkit/query/react';


export const supabaseApi = createApi({
  reducerPath: 'supabaseApi',
  baseQuery: fakeBaseQuery(),
  endpoints: (builder) => ({

    getSingleSpace: builder.query<any, string>({
      queryFn: async (spaceId) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from("spaces")
          .select("*")
          .eq("id", spaceId)
          .single()

        if (error) {
          console.error('sb', error.message);
          return { error: error.message };
        }
        return { data };
      }
    }),

    updateSpace: builder.mutation<any, { spaceId: string, name: string }>({
      queryFn: async ({ spaceId, name }) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from("spaces")
          .update({ name })
          .eq("id", spaceId)
          .single()

        if (error) {
          console.error('sb', error.message);
          return { error: error.message };
        }
        return { data };
      }
    }),

  }),
})

// Export hooks for usage in functional components, which are
// auto-generated based on the defined endpoints
export const { useGetSingleSpaceQuery, useUpdateSpaceMutation } = supabaseApi

