import { createApi, fakeBaseQuery } from '@reduxjs/toolkit/query/react'
import { createSupabaseBrowserClient } from '@/utils/supabase/client'

import { Database } from '@/utils/database.types'
import { createListenerMiddleware, isAnyOf } from '@reduxjs/toolkit'
import { sendAnalyticsEvent, AnalyticsEvent } from '@/utils/analytics/analytics'
// Define types for the space_packs table
export type DatabaseSpacePack =
  Database['public']['Tables']['space_packs']['Row']
export type DatabaseSpacePackInsert =
  Database['public']['Tables']['space_packs']['Insert']
export type DatabaseSpacePackUpdate =
  Database['public']['Tables']['space_packs']['Update']

export const TAG_NAME_FOR_GENERAL_ENTITY: string = 'SpacePacks'
export const TAG_NAME_FOR_LIST = 'LIST'
export const SPACE_PACKS_BUCKET_NAME: string = 'space-packs'

export const spacePacksApi = createApi({
  reducerPath: 'spacePacksApi',
  baseQuery: fakeBaseQuery(),
  invalidationBehavior: 'delayed', // TODO try changing this to `immediately` and time behavior of Redux updates to engine. `delayed` is default
  tagTypes: [TAG_NAME_FOR_GENERAL_ENTITY, TAG_NAME_FOR_LIST],
  endpoints: (builder) => ({
    /**
     * Create a new Space Pack
     */
    createSpacePack: builder.mutation<
      DatabaseSpacePack,
      DatabaseSpacePackInsert
    >({
      queryFn: async ({ space_id, display_name, data }) => {
        const supabase = createSupabaseBrowserClient()

        const { data: insertedData, error } = await supabase
          .from('space_packs')
          .insert({
            space_id,
            display_name,
            data
          } as DatabaseSpacePackInsert)
          .select('*')
          .single()

        if (error) {
          return { error: error.message }
        }

        return { data: insertedData }
      },
      invalidatesTags: [
        { type: TAG_NAME_FOR_GENERAL_ENTITY, id: TAG_NAME_FOR_LIST }
      ]
    }),

    /**
     * Get a single Space Pack by its ID
     */
    getSingleSpacePack: builder.query<DatabaseSpacePack, number>({
      queryFn: async (spacePackId) => {
        const supabase = createSupabaseBrowserClient()

        const { data, error } = await supabase
          .from('space_packs')
          .select('*')
          .eq('id', spacePackId)
          .single()

        if (error) {
          return { error: error.message }
        }

        return { data }
      },
      providesTags: (result, error, spacePackId) => [
        { type: TAG_NAME_FOR_GENERAL_ENTITY, id: spacePackId }
      ]
    }),

    /**
     * Get all Space Packs for a given space
     */
    getAllSpacePacks: builder.query<DatabaseSpacePack[], number>({
      queryFn: async (spaceId) => {
        const supabase = createSupabaseBrowserClient()

        const { data, error } = await supabase
          .from('space_packs')
          .select('*')
          .eq('space_id', spaceId)

        if (error) {
          return { error: error.message }
        }

        return { data }
      },
      providesTags: (result: any) =>
        result
          ? [
              ...result.map(({ id }) => ({
                type: TAG_NAME_FOR_GENERAL_ENTITY,
                id
              })),
              {
                type: TAG_NAME_FOR_GENERAL_ENTITY,
                id: TAG_NAME_FOR_LIST
              }
            ]
          : [
              {
                type: TAG_NAME_FOR_GENERAL_ENTITY,
                id: TAG_NAME_FOR_LIST
              }
            ]
    }),

    /**
     * Update a Space Pack by its ID
     */
    updateSpacePack: builder.mutation<
      DatabaseSpacePack,
      { id: number; data: any }
    >({
      queryFn: async ({ id: spacePackId, data }) => {
        const supabase = createSupabaseBrowserClient()

        const { data: updatedData, error } = await supabase
          .from('space_packs')
          .update({ data } as DatabaseSpacePackUpdate)
          .eq('id', spacePackId)
          .select('*')
          .single()

        if (error) {
          return { error: error.message }
        }

        return { data: updatedData }
      },
      invalidatesTags: (result, error, { id: spacePackId }) => [
        { type: TAG_NAME_FOR_GENERAL_ENTITY, id: spacePackId },
        { type: TAG_NAME_FOR_GENERAL_ENTITY, id: TAG_NAME_FOR_LIST }
      ]
    }),

    /**
     * Delete a Space Pack by its ID
     */
    deleteSpacePack: builder.mutation<DatabaseSpacePack, number>({
      queryFn: async (spacePackId) => {
        const supabase = createSupabaseBrowserClient()

        const { data, error } = await supabase
          .from('space_packs')
          .delete()
          .eq('id', spacePackId)
          .single()

        if (error) {
          return { error: error.message }
        }

        return { data }
      },
      invalidatesTags: (result, error, spacePackId) => [
        { type: TAG_NAME_FOR_GENERAL_ENTITY, id: spacePackId },
        { type: TAG_NAME_FOR_GENERAL_ENTITY, id: TAG_NAME_FOR_LIST }
      ]
    })
  })
})

// Middleware for analytics or other side-effects
export const listenerMiddlewarePcImports = createListenerMiddleware()
listenerMiddlewarePcImports.startListening({
  matcher: isAnyOf(
    spacePacksApi.endpoints.createSpacePack.matchFulfilled // Match fulfilled action of the mutation
  ),
  effect: async (action, listenerApi) => {
    sendAnalyticsEvent(AnalyticsEvent.CreateSpacePackAPISuccess)
  }
})

// Export the API hooks
export const {
  useCreateSpacePackMutation,
  useGetSingleSpacePackQuery,
  useGetAllSpacePacksQuery,
  useUpdateSpacePackMutation,
  useDeleteSpacePackMutation
} = spacePacksApi
