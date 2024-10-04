"use client"; // we want to use client-side only because supabase tracks auth clientside
import { generateSpaceName } from "@/actions/name-generator";
import { createSupabaseBrowserClient } from "@/utils/supabase/client";
import { createApi, fakeBaseQuery } from '@reduxjs/toolkit/query/react';

export const supabaseApi = createApi({
  reducerPath: 'supabaseApi',
  baseQuery: fakeBaseQuery(),
  endpoints: (builder) => ({

    /**
     * Spaces
     */
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

    /**
     * Assets
     */
    // createAsset: builder.mutation<any, any>({
    //   queryFn: async () => {
    //     const supabase = createSupabaseBrowserClient();
    //     const { data: { user } } = await supabase.auth.getUser()
    //     if (!user) {
    //       throw new Error('User not found')
    //     }
    //     /**
    //      * Upload the file
    //      */


    //     /**
    //      * Add to DB
    //      */
    //     const { data, error } = await supabase
    //       .from("assets")
    //       .insert([{
    //         name: await generateSpaceName(),
    //         creator_user_id: user?.id,
    //         owner_user_id: user.id
    //       }])
    //       .select('*')
    //       .single()

    //     if (error) {
    //       return { error: error.message };
    //     }
    //     return { data };
    //   }
    // }),

    getSingleAsset: builder.query<any, string>({
      queryFn: async (assetId) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from("assets")
          .select("*")
          .eq("id", assetId)
          .single()

        if (error) {
          return { error: error.message };
        }
        return { data };
      }
    }),

    searchAssets: builder.query<any, { text: string }>({
      queryFn: async ({ text }) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from("assets")
          .select("*")
          .eq("name", text)
          .single()

        if (error) {
          return { error: error.message };
        }
        return { data };
      }
    }),

    updateAsset: builder.mutation<any, { assetId: string, updateData: Record<string, any> }>({
      queryFn: async ({ assetId, updateData }) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from("assets")
          .update(updateData)
          .eq("id", assetId)
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
export const {
  /**
   * Spaces
   */
  useGetSingleSpaceQuery, useUpdateSpaceMutation, useCreateSpaceMutation,


  /**
   * Assets
   */
  useSearchAssetsQuery, useLazySearchAssetsQuery, useGetSingleAssetQuery, useUpdateAssetMutation
} = supabaseApi

