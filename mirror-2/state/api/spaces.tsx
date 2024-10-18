import { createApi, fakeBaseQuery } from '@reduxjs/toolkit/query/react'
import { createSupabaseBrowserClient } from '@/utils/supabase/client'
import { Database } from '@/utils/database.types'
import { generateSpaceName } from '@/actions/name-generator'
import {
  scenesApi,
  TAG_NAME_FOR_GENERAL_ENTITY as SCENES_TAG_NAME_FOR_GENERAL_ENTITY
} from '@/state/api/scenes'
import {
  TAG_NAME_FOR_GENERAL_ENTITY as ENTITIES_TAG_NAME_FOR_GENERAL_ENTITY,
  entitiesApi
} from '@/state/api/entities'
import { createListenerMiddleware, isAnyOf } from '@reduxjs/toolkit'
import { AnalyticsEvent, sendAnalyticsEvent } from '@/utils/analytics/analytics'

export type DatabaseSpace = Database['public']['Tables']['spaces']['Row']
export type DatabaseSpaceInsert =
  Database['public']['Tables']['spaces']['Insert']
export type DatabaseSpaceUpdate =
  Database['public']['Tables']['spaces']['Update']
export const TAG_NAME_FOR_LIST = 'LIST'
export const TAG_NAME_FOR_GENERAL_ENTITY = 'Spaces'

// Supabase API for spaces
export const spacesApi = createApi({
  reducerPath: 'spacesApi',
  baseQuery: fakeBaseQuery(),
  invalidationBehavior: 'delayed', // TODO try changing this to `immediately` and time behavior of Redux updates to engine. `delayed` is default
  tagTypes: [
    TAG_NAME_FOR_GENERAL_ENTITY,
    SCENES_TAG_NAME_FOR_GENERAL_ENTITY,
    ENTITIES_TAG_NAME_FOR_GENERAL_ENTITY,
    TAG_NAME_FOR_LIST
  ],
  endpoints: (builder) => ({
    createSpace: builder.mutation<any, any>({
      queryFn: async (_, { dispatch }) => {
        const supabase = createSupabaseBrowserClient()
        const {
          data: { user }
        } = await supabase.auth.getUser()
        if (!user) {
          throw new Error('User not found')
        }
        const name = await generateSpaceName()
        const { data, error } = await supabase
          .from('spaces')
          .insert([
            {
              name,
              creator_user_id: user?.id,
              owner_user_id: user.id
            }
          ])
          .select('*')
          .single()

        if (error) {
          return { error: error.message }
        }

        // Now that the space is created, dispatch the `createScene` mutation
        const { data: createSceneData, error: createSceneError } =
          await dispatch(
            scenesApi.endpoints.createScene.initiate({
              name: 'Main',
              space_id: data.id
            })
          )

        if (createSceneError) {
          return { error: createSceneError }
        }
        // create root entity is managed by create Scene

        // if (createEntityError) {
        //   return { error: createEntityError };
        // }
        return { data }
      },
      invalidatesTags: [
        { type: TAG_NAME_FOR_GENERAL_ENTITY, id: TAG_NAME_FOR_LIST }
      ]
    }),

    getSingleSpace: builder.query<any, number>({
      queryFn: async (spaceId) => {
        const supabase = createSupabaseBrowserClient()

        if (spaceId === null || spaceId === undefined) {
          return { error: 'SpaceID undefined' }
        }

        const { data, error } = await supabase
          .from('spaces')
          .select('*')
          .eq('id', spaceId)
          .single()

        if (error) {
          return { error: error.message }
        }
        return { data }
      },
      providesTags: (result, error, id) => [
        { type: TAG_NAME_FOR_GENERAL_ENTITY, id }
      ]
    }),

    updateSpace: builder.mutation<
      Database['public']['Tables']['spaces']['Row'],
      {
        id: number
        updateData: Partial<Database['public']['Tables']['spaces']['Update']>
      }
    >({
      queryFn: async ({ id: spaceId, updateData }) => {
        const supabase = createSupabaseBrowserClient()
        const { data, error } = await supabase
          .from('spaces')
          .update(updateData)
          .eq('id', spaceId)
          .select('*')
          .single()

        if (error) {
          return { error: error.message }
        }

        return { data }
      },
      invalidatesTags: (result, error, { id: spaceId }) => [
        { type: TAG_NAME_FOR_GENERAL_ENTITY, id: spaceId },
        { type: TAG_NAME_FOR_GENERAL_ENTITY, id: TAG_NAME_FOR_LIST }
      ]
    }),

    deleteSpace: builder.mutation<
      Database['public']['Tables']['spaces']['Row'],
      number
    >({
      queryFn: async (spaceId) => {
        const supabase = createSupabaseBrowserClient()
        const { data, error } = await supabase
          .from('spaces')
          .delete()
          .eq('id', spaceId)
          .single()

        if (error) {
          return { error: error.message }
        }

        return { data }
      },
      invalidatesTags: (result, error, spaceId) => [
        { type: TAG_NAME_FOR_GENERAL_ENTITY, id: spaceId },
        { type: TAG_NAME_FOR_GENERAL_ENTITY, id: TAG_NAME_FOR_LIST }
      ]
    })
  })
})

// TODO separate into separate file per docs rec and add rest of API calls
export const listenerMiddlewareSpaces = createListenerMiddleware()
listenerMiddlewareSpaces.startListening({
  matcher: isAnyOf(
    spacesApi.endpoints.createSpace.matchFulfilled // Match fulfilled action of the createSpace mutation
  ),
  effect: async (action, listenerApi) => {
    sendAnalyticsEvent(AnalyticsEvent.CreateSpaceAPISuccess)
  }
})

// Export the API hooks
export const {
  useGetSingleSpaceQuery,
  useCreateSpaceMutation,
  useUpdateSpaceMutation,
  useDeleteSpaceMutation
} = spacesApi
