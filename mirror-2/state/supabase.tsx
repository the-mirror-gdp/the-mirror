"use client"; // we want to use client-side only because supabase tracks auth clientside
import { createSupabaseBrowserClient } from "@/utils/supabase/client";
import { createApi, fakeBaseQuery } from '@reduxjs/toolkit/query/react';

export const supabaseApi = createApi({
  reducerPath: 'supabaseApi',
  baseQuery: fakeBaseQuery(),
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
            name: "New Space",
            creator_user_id: user?.id,
            owner_user_id: user.id
          }])

        if (error) {
          return { error: error.message };
        }
        return { data };
      }
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
      }
    }),

    updateSpace: builder.mutation<any, { spaceId: string, updateData: Record<string, any> }>({
      queryFn: async ({ spaceId, updateData }) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from("spaces")
          .update(updateData)
          .eq("id", spaceId)
          .single()

        if (error) {
          return { error: error.message };
        }
        return { data };
      }
    }),

  }),
})

// Export hooks for usage in functional components, which are
// auto-generated based on the defined endpoints
export const { useGetSingleSpaceQuery, useUpdateSpaceMutation, useCreateSpaceMutation } = supabaseApi

