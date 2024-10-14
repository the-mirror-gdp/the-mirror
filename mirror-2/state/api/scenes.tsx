import { AnalyticsEvent, sendAnalyticsEvent } from '@/utils/analytics/analytics'
import { Database } from '@/utils/database.types'
import { createSupabaseBrowserClient } from '@/utils/supabase/client'
import { createListenerMiddleware, isAnyOf } from '@reduxjs/toolkit'
import { createApi, fakeBaseQuery } from '@reduxjs/toolkit/query/react'

export const TAG_NAME_FOR_GENERAL_ENTITY = 'Scenes'
// Define types for the scenes table
export type DatabaseScene = Database['public']['Tables']['scenes']['Row']
export type DatabaseSceneInsert =
  Database['public']['Tables']['scenes']['Insert']
export type DatabaseSceneUpdate =
  Database['public']['Tables']['scenes']['Update']

// trying out branding, but might remove if it causes unnecessary pains
export type SceneId = number & { __brand: 'SceneId' }

// Supabase API for spaces
export const scenesApi = createApi({
  reducerPath: 'scenesApi',
  baseQuery: fakeBaseQuery(),
  tagTypes: [TAG_NAME_FOR_GENERAL_ENTITY, 'LIST'],
  endpoints: (builder) => ({
    /**
     * Create a new Scene
     */
    createScene: builder.mutation<
      DatabaseScene,
      { name: string; space_id: number }
    >({
      queryFn: async ({ name, space_id }, { dispatch }) => {
        const supabase = createSupabaseBrowserClient()
        const {
          data: { user },
          error: authError
        } = await supabase.auth.getUser()

        if (!user) {
          return { error: 'User not found' }
        }

        if (!space_id) {
          return { error: 'No spaceId provided' }
        }

        const { data, error } = await supabase
          .from('scenes')
          .insert({
            name,
            space_id
          })
          .select('*')
          .single()

        if (error) {
          return { error: error.message }
        }

        // Other logic for root entity creation

        return { data }
      },
      invalidatesTags: [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id: 'LIST' }]
    }),

    /**
     * Get a single Scene by its ID
     */
    getSingleScene: builder.query<DatabaseScene, number>({
      queryFn: async (sceneId: SceneId) => {
        const supabase = createSupabaseBrowserClient()

        const { data, error } = await supabase
          .from('scenes')
          .select('*')
          .eq('id', sceneId)
          .single()

        if (error) {
          return { error: error.message }
        }

        return { data }
      },
      providesTags: (result, error, sceneId) => [
        { type: TAG_NAME_FOR_GENERAL_ENTITY, id: sceneId }
      ]
    }),

    /**
     * Get all Scenes for a given space
     */
    getAllScenes: builder.query<DatabaseScene[], number>({
      queryFn: async (spaceId) => {
        const supabase = createSupabaseBrowserClient()

        const { data, error } = await supabase
          .from('scenes')
          .select('*')
          .eq('space_id', spaceId)

        if (error) {
          return { error: error.message }
        }

        return { data }
      },
      providesTags: (result) =>
        result
          ? [
              ...result.map(({ id }) => ({
                type: 'Scenes' as const, // Directly assign the type as "Scenes"
                id
              })),
              { type: 'LIST' as const, id: 'LIST' } // Ensure the type is "LIST"
            ]
          : [{ type: 'LIST' as const, id: 'LIST' }]
    }),

    /**
     * Update a Scene by its ID
     */
    updateScene: builder.mutation<
      DatabaseScene,
      { id: SceneId; name?: string }
    >({
      queryFn: async ({ id: sceneId, name }) => {
        const supabase = createSupabaseBrowserClient()

        const { data, error } = await supabase
          .from('scenes')
          .update({ name } as DatabaseSceneUpdate)
          .eq('id', sceneId)
          .single()

        if (error) {
          return { error: error.message }
        }

        return { data }
      },
      invalidatesTags: (result, error, { id: sceneId }) => [
        { type: TAG_NAME_FOR_GENERAL_ENTITY, id: sceneId }
      ]
    }),

    /**
     * Delete a Scene by its ID
     */
    deleteScene: builder.mutation<DatabaseScene, SceneId>({
      queryFn: async (sceneId) => {
        const supabase = createSupabaseBrowserClient()

        const { data, error } = await supabase
          .from('scenes')
          .delete()
          .eq('id', sceneId)
          .single()

        if (error) {
          return { error: error.message }
        }

        return { data }
      },
      invalidatesTags: (result, error, sceneId) => [
        { type: TAG_NAME_FOR_GENERAL_ENTITY, id: sceneId }
      ]
    })
  })
})

// Middleware for analytics or other side-effects
export const listenerMiddlewarePcImports = createListenerMiddleware()
listenerMiddlewarePcImports.startListening({
  matcher: isAnyOf(
    scenesApi.endpoints.createScene.matchFulfilled // Match fulfilled action of the mutation
  ),
  effect: async (action, listenerApi) => {
    sendAnalyticsEvent(AnalyticsEvent.CreateSceneAPISuccess)
  }
})

// Export the API hooks
export const {
  useCreateSceneMutation,
  useGetAllScenesQuery,
  useLazyGetAllScenesQuery,
  useUpdateSceneMutation,
  useGetSingleSceneQuery,
  useLazyGetSingleSceneQuery,
  useDeleteSceneMutation
} = scenesApi