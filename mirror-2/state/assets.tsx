import { createSlice, createEntityAdapter, createAsyncThunk } from '@reduxjs/toolkit';
import { createApi, fakeBaseQuery } from '@reduxjs/toolkit/query/react';
import { createSupabaseBrowserClient } from '@/utils/supabase/client';
import { Database } from '@/utils/database.types';

export const ASSETS_BUCKET_USERS_FOLDER = 'users' // used for the assets bucket
export const ASSETS_BUCKET_VERSIONED_ASSETS_FOLDER = 'versioned' // generally immutable, used for space_versions (published Spaces/games)
const TABLE_NAME = "assets"

export interface CreateAssetMutation {
  name: string
}
export const TAG_NAME_FOR_GENERAL_ENTITY = 'Assets'

// Supabase API for spaces
export const assetsApi = createApi({
  reducerPath: 'assetsApi',
  baseQuery: fakeBaseQuery(),
  tagTypes: [TAG_NAME_FOR_GENERAL_ENTITY, 'LIST'],
  endpoints: (builder) => ({
    createAsset: builder.mutation<any, { assetData: CreateAssetMutation, file?: File }>({
      queryFn: async ({ assetData, file }) => {
        const supabase = createSupabaseBrowserClient();

        // Get the authenticated user
        const { data: { user }, error: authError } = await supabase.auth.getUser();
        if (!user) {
          return { error: 'User not found' };
        }

        // Prepare the data to insert, without file_url and thumbnail_url yet
        const assetInsertData: Database['public']['Tables']['assets']['Insert'] = {
          ...assetData,
          creator_user_id: user.id,
          owner_user_id: user.id,
          file_url: '', // Placeholder, will update after file upload
          thumbnail_url: '', // Placeholder, will update after file upload
        };

        // Insert the asset (without file URL and thumbnail URL for now)
        const { data: insertedAsset, error: insertError }: {
          data: Database['public']['Tables']['assets']['Row'] | null,
          error: any
        } = await supabase
          .from(TABLE_NAME)
          .insert([assetInsertData])
          .select('*')
          .single();

        if (insertError || !insertedAsset) {
          return { error: insertError.message };
        }

        // Variable to store the file path (if file exists)
        let filePath = '';

        // Check if a file is passed for upload
        if (file) {
          // Generate a unique file name for Supabase Storage
          filePath = `${ASSETS_BUCKET_USERS_FOLDER}/${insertedAsset.id}`;

          // Upload the file to Supabase Storage
          const { error: uploadError } = await supabase.storage
            .from('assets') // Replace with your bucket name
            .upload(filePath, file);

          // Handle file upload error
          if (uploadError) {
            return { error: uploadError.message };
          }

          // Get the public URL of the uploaded file
          const { data: fileUrlData } = supabase.storage.from('assets').getPublicUrl(filePath);
          const fileUrl = fileUrlData?.publicUrl;

          // Create a thumbnail URL using Supabase transform (resize)
          const { data: thumbnailUrlData } = supabase.storage.from('assets').getPublicUrl(filePath, {
            transform: {
              width: 150,
              height: 150,
            }
          });
          const thumbnailUrl = thumbnailUrlData?.publicUrl;

          // Update the asset with the file URL and thumbnail URL
          const { error: updateError } = await supabase
            .from(TABLE_NAME)
            .update({
              file_url: fileUrl,
              thumbnail_url: thumbnailUrl,
            })
            .eq('id', insertedAsset.id) // Use the inserted asset's ID for the update
            .single();

          if (updateError) {
            return { error: updateError.message };
          }
        }

        return { data: insertedAsset };
      },
      invalidatesTags: [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id: 'LIST' }],
    }),

    getSingleAsset: builder.query<any, string>({
      queryFn: async (assetId) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from(TABLE_NAME)
          .select("*")
          .eq("id", assetId)
          .single()

        if (error) {
          return { error: error.message };
        }
        return { data };
      },
      providesTags: (result, error, id) => [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id }],
    }),


    getUserMostRecentlyUpdatedAssets: builder.query<any, any>({
      queryFn: async () => {
        const supabase = createSupabaseBrowserClient();
        const { data: { user } } = await supabase.auth.getUser()
        if (!user) {
          throw new Error('User not found')
        }
        const { data, error } = await supabase
          .from(TABLE_NAME)
          .select("*")
          .eq("owner_user_id", user.id)
          .order("updated_at", { ascending: false })

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
    },),


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
      },
      providesTags: (result) =>
        result
          ? [
            ...result.map(({ id }) => ({ type: TAG_NAME_FOR_GENERAL_ENTITY, id })),
            { type: TAG_NAME_FOR_GENERAL_ENTITY, id: 'LIST' },
          ]
          : [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id: 'LIST' }],
    }),

    updateAsset: builder.mutation<any, { assetId: string, updateData: Record<string, any> }>({
      queryFn: async ({ assetId, updateData }) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from(TABLE_NAME)
          .update(updateData)
          .eq("id", assetId)
          .single()

        if (error) {
          return { error: error.message };
        }
        return { data };
      },
      invalidatesTags: (result, error, { assetId }) => [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id: assetId }],
    }),


    downloadAsset: builder.query<any, { assetId: string }>({
      queryFn: async ({ assetId }) => {
        const supabase = createSupabaseBrowserClient();

        // Return the public URL for the file to allow download
        const { data, error } = await supabase.storage
          .from('assets')  // Use your actual bucket name
          .download(`users/${assetId}`);

        if (error) {
          return { error: error.message };
        }
        return { data };
      }
    }),


  }),
});


// Export the API hooks
export const {
  useCreateAssetMutation, useSearchAssetsQuery, useLazySearchAssetsQuery, useGetSingleAssetQuery, useLazyGetUserMostRecentlyUpdatedAssetsQuery, useUpdateAssetMutation, useLazyDownloadAssetQuery,
} = assetsApi;
