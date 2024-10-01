"use client"; // we want to use client-side only because supabase tracks auth clientside
import { createSupabaseBrowserClient } from "@/utils/supabase/client";
import { cache } from "react";
import { createApi, fakeBaseQuery } from '@reduxjs/toolkit/query/react'


export const supabaseApi = createApi({
  reducerPath: 'supabaseApi',
  baseQuery: fakeBaseQuery(),
  endpoints: (builder) => ({
    getSingleSpace: builder.query<any, any>({
      queryFn: async (spaceId) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from("spaces")
          .select("*")
          .eq("id", spaceId)
          .single()

        if (error) {
          console.error('sb', error.message);
          console.error(error.message);
          return { error: error.message };
        }
        console.log('sb data', data)
        return { data };
      }
    }),
  }),
})

// Export hooks for usage in functional components, which are
// auto-generated based on the defined endpoints
export const { useGetSingleSpaceQuery } = supabaseApi

