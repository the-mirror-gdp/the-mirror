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
  tagTypes: ['Assets', 'Spaces', 'Scenes', 'Entities', 'Users'],
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
          .from("assets")
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
            .from("assets")
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
      invalidatesTags: ['Assets']
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
      },
      providesTags: (result, error, assetId) => [{ type: 'Assets', id: assetId }],
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
      },
      providesTags: (result) =>
        result ? result.map(({ id }) => ({ type: 'Assets', id })) : [],
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
      },
      invalidatesTags: (result, error, { assetId }) => [{ type: 'Assets', id: assetId }],
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

    /**
     * Scenes
    */
    createScene: builder.mutation<any, { name: string, space_id: string }>({
      queryFn: async ({ name, space_id }) => {
        const supabase = createSupabaseBrowserClient();
        const { data: { user }, error: authError } = await supabase.auth.getUser();

        if (!user) {
          return { error: 'User not found' };
        }

        const { data, error } = await supabase
          .from("scenes")
          .insert([{
            name,
            space_id,
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
      invalidatesTags: (result, error, { space_id }) => [{ type: 'Scenes', id: space_id }], // Invalidate the tag for the specific space_id
    }),

    /**
     * Get a single Scene by its ID
     */
    getSingleScene: builder.query<any, string>({
      queryFn: async (sceneId) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from("scenes")
          .select("*")
          .eq("id", sceneId)
          .single();

        if (error) {
          return { error: error.message };
        }
        return { data };
      },
      providesTags: (result, error, sceneId) => [{ type: 'Scenes', id: sceneId }], // Provide the scene tag based on sceneId
    }),

    /**
     * Get all Scenes for a given space
     */
    getAllScenes: builder.query<any, string>({
      queryFn: async (spaceId) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from("scenes")
          .select("*")
          .eq("space_id", spaceId);

        if (error) {
          return { error: error.message };
        }
        return { data };
      },
      providesTags: (result, error, spaceId) =>
        result ? [{ type: 'Scenes', id: spaceId }] : [], // Provide tag for spaceId
    }),

    /**
     * Update a Scene by its ID
     */
    updateScene: builder.mutation<any, { sceneId: string, updateData: Record<string, any> }>({
      queryFn: async ({ sceneId, updateData }) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from("scenes")
          .update(updateData)
          .eq("id", sceneId)
          .single();

        if (error) {
          return { error: error.message };
        }
        return { data };
      },
      invalidatesTags: (result, error, { sceneId }) => [{ type: 'Scenes', id: sceneId }], // Invalidate tag for sceneId
    }),

    /**
     * Delete a Scene by its ID
     */
    deleteScene: builder.mutation<any, string>({
      queryFn: async (sceneId) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from("scenes")
          .delete()
          .eq("id", sceneId)
          .single();

        if (error) {
          return { error: error.message };
        }
        return { data };
      },
      invalidatesTags: ['Scenes']
    }),

    /**
     * Entities
     */
    createEntity: builder.mutation<any, { name: string, scene_id: string }>({
      queryFn: async ({ name, scene_id }) => {
        const supabase = createSupabaseBrowserClient();
        const { data: { user }, error: authError } = await supabase.auth.getUser();

        if (!user) {
          return { error: 'User not found' };
        }

        const { data, error } = await supabase
          .from("entities")
          .insert([{
            name,
            scene_id,
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
      invalidatesTags: (result, error, { scene_id }) => [{ type: 'Entities', id: scene_id }], // Invalidate the tag for the specific scene_id
    }),

    getAllEntities: builder.query<any, string>({
      queryFn: async (sceneId) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from("entities")
          .select("*")
          .eq("scene_id", sceneId);

        if (error) {
          return { error: error.message };
        }
        return { data };
      },
      providesTags: (result, error, sceneId) =>
        result ? [{ type: 'Entities', id: sceneId }] : [], // Provide tag for sceneId
    }),

    getSingleEntity: builder.query<any, string>({
      queryFn: async (entityId) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from("entities")
          .select("*")
          .eq("id", entityId)
          .single();

        if (error) {
          return { error: error.message };
        }
        return { data };
      },
      providesTags: (result, error, entityId) => [{ type: 'Entities', id: entityId }], // Provide the entity tag based on entityId
    }),

    updateEntity: builder.mutation<any, { entityId: string, updateData: Record<string, any> }>({
      queryFn: async ({ entityId, updateData }) => {
        const supabase = createSupabaseBrowserClient();

        const { data, error } = await supabase
          .from("entities")
          .update(updateData)
          .eq("id", entityId)
          .single();

        if (error) {
          return { error: error.message };
        }
        return { data };
      },
      invalidatesTags: (result, error, { entityId }) => [{ type: 'Entities', id: entityId }], // Invalidate tag for entityId
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
      invalidatesTags: ['Entities']
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
  useCreateAssetMutation, useSearchAssetsQuery, useLazySearchAssetsQuery, useGetSingleAssetQuery, useLazyGetUserMostRecentlyUpdatedAssetsQuery, useUpdateAssetMutation, useLazyDownloadAssetQuery,

  /**
   * Scenes
   */
  useCreateSceneMutation, useGetAllScenesQuery, useUpdateSceneMutation, useGetSingleSceneQuery, useLazyGetSingleSceneQuery, useDeleteSceneMutation,

  /**
   * Entities
   */
  useCreateEntityMutation, useGetAllEntitiesQuery, useUpdateEntityMutation, useGetSingleEntityQuery, useLazyGetAllEntitiesQuery, useDeleteEntityMutation
} = supabaseApi

