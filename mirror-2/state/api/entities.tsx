import {
  createSlice,
  createEntityAdapter,
  createAsyncThunk,
  createListenerMiddleware,
  isAnyOf,
  createSelector
} from '@reduxjs/toolkit'
import {
  RootState,
  createApi,
  fakeBaseQuery
} from '@reduxjs/toolkit/query/react'
import { createSupabaseBrowserClient } from '@/utils/supabase/client'
import { TAG_NAME_FOR_BUILD_MODE_SPACE_QUERY } from '@/state/shared-cache-tags'

import {
  createGeneralEntityListenerMiddleware,
  selectAllEntities
} from '@/state/engine/middleware'
import { Database } from '@/utils/database.types'
import { SceneId } from '@/state/api/scenes'

// Define types for the entities table
export type DatabaseEntity = Database['public']['Tables']['entities']['Row']
export type DatabaseEntityInsert =
  Database['public']['Tables']['entities']['Insert']
export type DatabaseEntityUpdate =
  Database['public']['Tables']['entities']['Update']
export const TAG_NAME_FOR_GENERAL_ENTITY = 'Entities'

// Supabase API for spaces
export const entitiesApi = createApi({
  reducerPath: 'entitiesApi',
  baseQuery: fakeBaseQuery(),
  tagTypes: [
    TAG_NAME_FOR_GENERAL_ENTITY,
    'LIST',
    TAG_NAME_FOR_BUILD_MODE_SPACE_QUERY
  ],
  endpoints: (builder) => ({
    createEntity: builder.mutation<
      any,
      {
        name: string
        scene_id: number
        parent_id?: string
        order_under_parent?: number
        isRootEntity?: boolean
      }
    >({
      queryFn: async ({
        name,
        scene_id,
        parent_id,
        order_under_parent,
        isRootEntity
      }) => {
        const supabase = createSupabaseBrowserClient()
        const {
          data: { user },
          error: authError
        } = await supabase.auth.getUser()

        if (!user) {
          return { error: 'User not found' }
        }

        // if no parent_id and not the root entity upon creation, find the root entity
        if (!parent_id && !isRootEntity) {
          const { data: rootEntity, error: rootEntityError } = await supabase
            .from('entities')
            .select('*')
            .eq('scene_id', scene_id)
            .is('parent_id', null)
            .single()

          if (rootEntityError) {
            return { error: rootEntityError.message }
          }

          parent_id = rootEntity.id
        }

        if (
          parent_id &&
          (order_under_parent === undefined || order_under_parent === null)
        ) {
          // need to find the order_under_parent to use for the new entity
          const { data: entitiesWithSameParent, error: parentEntityError } =
            await supabase
              .from('entities')
              .select('*')
              .eq('parent_id', parent_id)

          if (parentEntityError) {
            return { error: parentEntityError.message }
          }
          // find the highest order_under_parent
          if (entitiesWithSameParent) {
            const highestOrderUnderParent = entitiesWithSameParent.reduce(
              (max, entity) => {
                const entityOrderUnderParent = entity.order_under_parent ?? -1 // If null or undefined, default to -1
                return entityOrderUnderParent > max
                  ? entityOrderUnderParent
                  : max
              },
              -1
            )
            order_under_parent = highestOrderUnderParent + 1
          }
        }

        const { data, error } = await supabase
          .from('entities')
          .insert({
            name: name,
            scene_id,
            parent_id,
            order_under_parent,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          })
          .select('*')
          .single()

        if (error) {
          return { error: error.message }
        }

        return { data }
      },
      invalidatesTags: [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id: 'LIST' }]
    }),

    getAllEntities: builder.query<DatabaseEntity[], SceneId>({
      queryFn: async (sceneId) => {
        const supabase = createSupabaseBrowserClient()

        if (!sceneId) {
          return { error: 'No scene_id provided' }
        }

        const { data, error } = await supabase
          .from('entities')
          .select('*')
          .eq('scene_id', sceneId)

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
              { type: TAG_NAME_FOR_GENERAL_ENTITY, id: 'LIST' }
            ]
          : [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id: 'LIST' }]
    }),

    getSingleEntity: builder.query<DatabaseEntity, string>({
      queryFn: async (entityId) => {
        const supabase = createSupabaseBrowserClient()

        const { data, error } = await supabase
          .from('entities')
          .select('*')
          .eq('id', entityId)
          .single()

        if (error) {
          return { error: error.message }
        }
        return { data }
      },
      providesTags: (result, error, entityId) => [
        { type: TAG_NAME_FOR_GENERAL_ENTITY, id: entityId }
      ] // Provide the entity tag based on entityId
    }),

    updateEntity: builder.mutation<
      any,
      {
        id: string
        name?: string
        enabled?: boolean
        parent_id?: string
        order_under_parent?: number
        scene_id?: number
        local_position?: [number, number, number] // Using array for vector3
        local_scale?: [number, number, number] // Using array for scale
        local_rotation?: [number, number, number] // Using array for rotation (Euler angles or quaternion)
      }
    >({
      queryFn: async ({
        id,
        name,
        enabled,
        parent_id,
        order_under_parent,
        scene_id,
        local_position,
        local_scale,
        local_rotation
      }) => {
        const supabase = createSupabaseBrowserClient()

        // If no parent_id, find the root entity
        if (!parent_id) {
          if (!scene_id) {
            return { error: 'No scene_id provided' }
          }
          const { data: rootEntity, error: rootEntityError } = await supabase
            .from('entities')
            .select('*')
            .eq('scene_id', scene_id)
            .is('parent_id', null)
            .single()

          if (rootEntityError) {
            return { error: rootEntityError.message }
          }

          if (rootEntity.id !== id) {
            // ensure not self (the Root)
            parent_id = rootEntity.id
          }
        }

        // If parent_id exists but no order_under_parent
        if (
          (parent_id && order_under_parent === undefined) ||
          (parent_id && order_under_parent === null)
        ) {
          const { data: entitiesWithSameParent, error: parentEntityError } =
            await supabase
              .from('entities')
              .select('*')
              .eq('parent_id', parent_id)

          if (parentEntityError) {
            return { error: parentEntityError.message }
          }

          // Find the highest order_under_parent
          const highestOrderUnderParent = entitiesWithSameParent.reduce(
            (max, entity: any) => {
              return entity.order_under_parent > max
                ? entity.order_under_parent
                : max
            },
            -1
          )
          order_under_parent = highestOrderUnderParent + 1
        }

        // Prepare the update payload
        const updatePayload: any = {
          name,
          enabled,
          parent_id,
          order_under_parent,
          scene_id
        }

        // Add position, scale, rotation updates if provided
        if (local_position) updatePayload.local_position = local_position
        if (local_rotation) updatePayload.local_rotation = local_rotation
        if (local_scale) updatePayload.local_scale = local_scale

        const { data, error } = await supabase
          .from('entities')
          .update(updatePayload)
          .eq('id', id)
          .single()

        if (error) {
          return { error: error.message }
        }

        return { data }
      },

      // Optimistic update
      async onQueryStarted({ id, ...patch }, { dispatch, queryFulfilled }) {
        const patchResult = dispatch(
          entitiesApi.util.updateQueryData('getSingleEntity', id, (draft) => {
            Object.assign(draft, patch)
          })
        )
        try {
          await queryFulfilled
        } catch {
          patchResult.undo()
        }
      },

      invalidatesTags: (result, error, { id: entityId }) => [
        { type: TAG_NAME_FOR_GENERAL_ENTITY, id: entityId },
        TAG_NAME_FOR_BUILD_MODE_SPACE_QUERY
      ]
    }),

    batchUpdateEntities: builder.mutation<
      any,
      {
        entities: {
          id: string
          name?: string
          scene_id?: number
          parent_id?: string
          order_under_parent?: number
        }[]
        enabled?: boolean
      }
    >({
      queryFn: async ({ entities }) => {
        const supabase = createSupabaseBrowserClient()
        const entityIds = entities.map((entity) => entity.id)

        // Fetch all current entities by the provided IDs. This is needed since supabase batch upsert requires ALL properties to be passed in or else it overwrites the existing data.
        const { data: existingEntities, error: fetchError } = await supabase
          .from('entities')
          .select('*')
          .in('id', entityIds)

        if (fetchError) {
          return { error: fetchError.message }
        }

        // Merge each entity's new properties with existing data
        const entitiesToUpsert = entities.map((newEntity) => {
          const existingEntity = existingEntities.find(
            (e) => e.id === newEntity.id
          )

          if (existingEntity === undefined) {
            throw new Error(
              `Entity with ID ${(existingEntity as any).id} doesn't exist`
            )
          }

          // Merge existing entity fields with new updates
          const data = {
            ...existingEntity, // Existing entity data
            ...newEntity, // New updates, this will override fields like name, scene_id, etc.
            updated_at: new Date().toISOString() // Update timestamp
          }

          if (!existingEntity?.name) {
            throw new Error(
              `Entity with ID ${existingEntity?.id} is missing a name`
            )
          }

          return data
        })

        // Perform the batch upsert
        const { data: upsertData, error: upsertError } = await supabase
          .from('entities')
          .upsert(entitiesToUpsert)
          .select('*') // You can select specific fields if you want

        if (upsertError) {
          return { error: upsertError.message }
        }

        return { data: upsertData }
      },
      invalidatesTags: [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id: 'LIST' }] // Invalidates the cache
    }),

    deleteEntity: builder.mutation<any, number>({
      queryFn: async (entityId) => {
        const supabase = createSupabaseBrowserClient()

        const { data, error } = await supabase
          .from('entities')
          .delete()
          .eq('id', entityId)
          .single()

        if (error) {
          return { error: error.message }
        }
        return { data }
      },
      invalidatesTags: (result, error, entityId) => [
        { type: TAG_NAME_FOR_GENERAL_ENTITY, id: entityId }
      ]
    })
  })
})

// export const listenerMiddlewareEntities = createGeneralEntityListenerMiddleware(
//   entitiesApi,
//   'Entities',
//   selectAllEntities
// )

// export const listenerMiddlewareEntities = createListenerMiddleware();

// listenerMiddlewareEntities.startListening({
//   matcher: isAnyOf(
//     entitiesApi.endpoints.createEntity.matchPending,
//     entitiesApi.endpoints.updateEntity.matchPending,
//     entitiesApi.endpoints.batchUpdateEntities.matchPending,
//     entitiesApi.endpoints.deleteEntity.matchPending
//   ),
//   effect: async (action, listenerApi) => {
//     // Optimistically update PlayCanvas when mutation starts
//     const state: any = listenerApi.getState();
//     const entities = state.entitiesApi.queries; // Adjust based on how your state is structured

//     // Pass the optimistic changes to PlayCanvas
//     updateEngineApp(entities, { isOptimistic: true });
//   },
// });

// listenerMiddlewareEntities.startListening({
//   matcher: isAnyOf(
//     entitiesApi.endpoints.createEntity.matchFulfilled,
//     entitiesApi.endpoints.updateEntity.matchFulfilled,
//     entitiesApi.endpoints.batchUpdateEntities.matchFulfilled,
//     entitiesApi.endpoints.deleteEntity.matchFulfilled,
//     entitiesApi.endpoints.getAllEntities.matchFulfilled
//   ),
//   effect: async (action, listenerApi) => {
//     // Confirm the update when the mutation is successfully completed
//     const state: any = listenerApi.getState();
//     const entities = state.entitiesApi.queries; // Adjust based on how your state is structured

//     updateEngineApp(entities, { isOptimistic: false });
//   },
// });

// listenerMiddlewareEntities.startListening({
//   matcher: isAnyOf(
//     entitiesApi.endpoints.createEntity.matchRejected,
//     entitiesApi.endpoints.updateEntity.matchRejected,
//     entitiesApi.endpoints.batchUpdateEntities.matchRejected,
//     entitiesApi.endpoints.deleteEntity.matchRejected
//   ),
//   effect: async (action, listenerApi) => {
//     // Revert PlayCanvas update when mutation fails
//     const state: any = listenerApi.getState()
//     const entities = state.entitiesApi.queries; // Adjust based on how your state is structured

//     updateEngineApp(entities, { isReverted: true });
//   },
// });

export const selectEntitiesResult = entitiesApi.endpoints.getAllEntities.select

const selectEntitiesBySceneId = createSelector(
  (state) => state.entities.data,
  (_, sceneId: SceneId) => sceneId,
  (entities: DatabaseEntity[], sceneId: SceneId) =>
    entities.filter((entity) => entity.scene_id === sceneId)
)

// Export the API hooks
export const {
  useCreateEntityMutation,
  useBatchUpdateEntitiesMutation,
  useGetAllEntitiesQuery,
  useUpdateEntityMutation,
  useGetSingleEntityQuery,
  useLazyGetAllEntitiesQuery,
  useDeleteEntityMutation
} = entitiesApi
