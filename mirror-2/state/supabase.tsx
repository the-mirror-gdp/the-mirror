"use client"; // we want to use client-side only because supabase tracks auth clientside
import { generateSpaceName } from "@/actions/name-generator";
import { Database } from "@/utils/database.types";
import { createSupabaseBrowserClient } from "@/utils/supabase/client";
import { createApi, fakeBaseQuery } from '@reduxjs/toolkit/query/react';

export const ASSETS_BUCKET_USERS_FOLDER = 'users' // used for the assets bucket
export const ASSETS_BUCKET_VERSIONED_ASSETS_FOLDER = 'versioned' // generally immutable, used for space_versions (published Spaces/games)
export interface CreateAssetMutation {
  name: string
}

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
    createAsset: builder.mutation<any, { assetData: CreateAssetMutation, file?: File }>({
      queryFn: async ({ assetData, file }) => {
        const supabase = createSupabaseBrowserClient();


        // Get the authenticated user
        const { data: { user }, error: authError } = await supabase.auth.getUser();
        if (!user) {
          return { error: 'User not found' };
        }


        // Variable to store the file path (if file exists)
        let filePath = '';

        // Check if a file is passed for upload
        if (file) {
          // Generate a unique file name for Supabase Storage
          filePath = `${ASSETS_BUCKET_USERS_FOLDER}/${file.name}`;

          // Upload the file to Supabase Storage
          const { error: uploadError } = await supabase.storage
            .from('assets') // Replace with your bucket name
            .upload(filePath, file);

          // Handle file upload error
          if (uploadError) {
            return { error: uploadError.message };
          }
        }

        // Create a thumbnail URL using Supabase transform
        const { data: thumbnailUrl } = supabase.storage.from('assets').getPublicUrl(filePath, {
          transform: {
            width: 150,
            height: 150
          }
        });


        // Add the creator and owner user_id inline
        const assetUploadData: Database['public']['Tables']['assets']['Insert'] = {
          ...assetData,
          creator_user_id: user.id,
          owner_user_id: user.id,
          file_url: `${supabase.storage.from('assets').getPublicUrl(filePath).data.publicUrl}`,
          thumbnail_url: thumbnailUrl.publicUrl
        }

        // Insert the asset in the "assets" table
        const { data, error } = await supabase
          .from("assets")
          .insert([assetUploadData]) // Insert a new row with updateData
          .single(); // Ensure only a single record is returned

        if (error) {
          return { error: error.message };
        }

        return { data };
      }
    }),

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


    getUserMostRecentlyUpdatedAssets: builder.query<any, any>({
      queryFn: async () => {
        const supabase = createSupabaseBrowserClient();
        const { data: { user } } = await supabase.auth.getUser()
        if (!user) {
          throw new Error('User not found')
        }
        const { data, error } = await supabase
          .from("assets")
          .select("*")
          .eq("owner_user_id", user.id)
          .order("updated_at", { ascending: false })

        if (error) {
          return { error: error.message };
        }
        return { data };
      }
    }),


    searchAssets: builder.query<any, { text: string }>({
      queryFn: async ({ text }) => {
        const supabase = createSupabaseBrowserClient();

        // replace spaces with +
        const friendlyText = text?.trim().replaceAll(" ", "&")
        const { data, error } = await supabase
          .rpc("search_assets_by_name_prefix", { 'prefix': friendlyText })

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
  useCreateAssetMutation, useSearchAssetsQuery, useLazySearchAssetsQuery, useGetSingleAssetQuery, useLazyGetUserMostRecentlyUpdatedAssetsQuery, useUpdateAssetMutation
} = supabaseApi

