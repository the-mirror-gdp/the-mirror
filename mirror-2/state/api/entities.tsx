import {
  createSlice,
  createEntityAdapter,
  createAsyncThunk,
  createListenerMiddleware,
  isAnyOf,
  createSelector
} from '@reduxjs/toolkit'
import { createApi, fakeBaseQuery } from '@reduxjs/toolkit/query/react'
import { createSupabaseBrowserClient } from '@/utils/supabase/client'
import { TAG_NAME_FOR_BUILD_MODE_SPACE_QUERY } from '@/state/shared-cache-tags'

import { Database, Tables } from '@/utils/database.types'
import { SceneId } from '@/state/api/scenes'
import { updateEngineApp } from '@/state/engine/engine'
import { RootState } from '@/state/store'
import { setCurrentEntityUseOnlyForId } from '@/state/local.slice'
import { TransformTuples, TupleLengthMap } from '@/utils/database.types.helpers'

// Define types for the entities table
export type DatabaseEntity = TransformTuples<Tables<'entities'>>
export type DatabaseEntityInsert =
  Database['public']['Tables']['entities']['Insert']
export type DatabaseEntityUpdate =
  Database['public']['Tables']['entities']['Update']
export const TAG_NAME_FOR_GENERAL_ENTITY = 'Entities'
export type EntityId = string

export type DatabaseComponent =
  Database['public']['Tables']['entities']['Row']['components']

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
        const { data, error } = await supabase
          .from('entities')
          .select('*')
          .eq('scene_id', sceneId)

        if (error) {
          return { error: error.message }
        }

        // Ensure the data matches the expected type
        const formattedData = data.map((entity) => ({
          ...entity,
          local_position: [
            entity.local_position[0],
            entity.local_position[1],
            entity.local_position[2]
          ] as [number, number, number],
          local_scale: [
            entity.local_scale[0],
            entity.local_scale[1],
            entity.local_scale[2]
          ] as [number, number, number],
          local_rotation: [
            entity.local_rotation[0],
            entity.local_rotation[1],
            entity.local_rotation[2],
            entity.local_rotation[3]
          ] as [number, number, number, number]
        }))

        return { data: formattedData }
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

    getSingleEntity: builder.query<DatabaseEntity, EntityId>({
      queryFn: async (entityId: EntityId) => {
        if (!entityId) {
          return { error: 'No entityId (string) provided' }
        }
        const supabase = createSupabaseBrowserClient()

        const { data, error } = await supabase
          .from('entities')
          .select('*')
          .eq('id', entityId)
          .single()

        if (error) {
          return { error: error.message }
        }

        // update formatting to handle number[] to [number,number,number, (number?)] conversion
        const formattedData = {
          ...data,
          local_position: [
            data.local_position[0],
            data.local_position[1],
            data.local_position[2]
          ] as [number, number, number],
          local_rotation: [
            data.local_rotation[0],
            data.local_rotation[1],
            data.local_rotation[2],
            data.local_rotation[3]
          ] as [number, number, number, number],
          local_scale: [
            data.local_scale[0],
            data.local_scale[1],
            data.local_scale[2]
          ] as [number, number, number]
        }
        return {
          data: formattedData
        }
      },
      providesTags: (result, error, entityId) => [
        { type: TAG_NAME_FOR_GENERAL_ENTITY, id: entityId }
      ] // Provide the entity tag based on entityId
    }),

    updateEntity: builder.mutation<
      any,
      {
        id: EntityId
        name?: string
        enabled?: boolean
        parent_id?: string
        order_under_parent?: number
        scene_id?: number
        local_position?: [number, number, number] // Using array for vector3
        local_scale?: [number, number, number] // Using array for scale
        local_rotation?: [number, number, number] // Using array for rotation (Euler angles or quaternion)
        tags?: string[]

        // use the components method for updating components
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
        local_rotation,
        tags
      }) => {
        const supabase = createSupabaseBrowserClient()

        // Whitelist update payload
        const updatePayload: any = {
          name,
          enabled,
          parent_id,
          order_under_parent,
          scene_id,
          local_position,
          local_rotation,
          local_scale,
          tags
        }

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

    /**
     * Has custom logic for checking parent_id and order_under_parent. Should only be used by a TreeItem. Not ideal but easier to avoid errors this way
     */
    updateEntityTreeItem: builder.mutation<
      any,
      {
        id: EntityId
        name?: string
        enabled?: boolean
        parent_id?: string
        order_under_parent?: number
        scene_id?: number
        local_position?: [number, number, number] // Using array for vector3
        local_scale?: [number, number, number] // Using array for scale
        local_rotation?: [number, number, number] // Using array for rotation (Euler angles or quaternion)
        // local_position?: number[] // Using array for vector3
        // local_scale?: number[] // Using array for vector3
        // local_rotation?: number[] // Using array for vector3
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
          id: EntityId
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

    deleteEntity: builder.mutation<any, EntityId>({
      queryFn: async (entityId: EntityId) => {
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
    }),

    /**
     * Components
     */
    addComponentToEntity: builder.mutation<
      any,
      {
        id: EntityId
        componentKey: string // The key for the component (e.g., 'render')
        componentData: any // The new component data to be added
      }
    >({
      queryFn: async ({ id, componentKey, componentData }) => {
        const supabase = createSupabaseBrowserClient()

        // Fetch the existing components
        const { data: existingEntity, error: fetchError } = await supabase
          .from('entities')
          .select('components')
          .eq('id', id)
          .single()

        if (fetchError) {
          return { error: fetchError.message }
        }

        // Merge the new component data under the specified key (componentKey)
        const updatedComponents = {
          ...(typeof existingEntity.components === 'object'
            ? existingEntity.components
            : {}),
          [componentKey]: componentData // Add or overwrite the specific component
        }

        const { data, error } = await supabase
          .from('entities')
          .update({ components: updatedComponents })
          .eq('id', id)
          .single()

        if (error) {
          return { error: error.message }
        }

        return { data }
      },
      invalidatesTags: (result, error, { id }) => [
        { type: TAG_NAME_FOR_GENERAL_ENTITY, id }
      ]
    }),

    getComponentsOfEntity: builder.query<any, EntityId>({
      queryFn: async (id: EntityId) => {
        const supabase = createSupabaseBrowserClient()

        const { data, error } = await supabase
          .from('entities')
          .select('components')
          .eq('id', id)
          .single()

        if (error) {
          return { error: error.message }
        }

        return { data: data.components }
      },
      providesTags: (result, error, id) => [
        { type: TAG_NAME_FOR_GENERAL_ENTITY, id }
      ]
    }),

    updateComponentOnEntity: builder.mutation<
      any,
      {
        id: EntityId
        componentKey: string // The key for the component (e.g., 'render')
        updatedComponentData: any // The new data for the component
      }
    >({
      queryFn: async ({ id, componentKey, updatedComponentData }) => {
        const supabase = createSupabaseBrowserClient()

        // Fetch the existing components
        const { data: existingEntity, error: fetchError } = await supabase
          .from('entities')
          .select('components')
          .eq('id', id)
          .single()

        if (fetchError) {
          return { error: fetchError.message }
        }

        // Update the specific component in the JSONB object
        const updatedComponents = {
          ...(typeof existingEntity.components === 'object'
            ? existingEntity.components
            : {}),
          [componentKey]: updatedComponentData // Update only the specific component
        }

        const { data, error } = await supabase
          .from('entities')
          .update({ components: updatedComponents })
          .eq('id', id)
          .single()

        if (error) {
          return { error: error.message }
        }

        return { data }
      },
      invalidatesTags: (result, error, { id }) => [
        { type: TAG_NAME_FOR_GENERAL_ENTITY, id }
      ]
    }),

    deleteComponentFromEntity: builder.mutation<
      any,
      {
        id: EntityId
        componentKey: string // The key of the component to be deleted
      }
    >({
      queryFn: async ({ id, componentKey }) => {
        const supabase = createSupabaseBrowserClient()

        // Fetch the existing components
        const { data: existingEntity, error: fetchError } = await supabase
          .from('entities')
          .select('components')
          .eq('id', id)
          .single()

        if (fetchError) {
          return { error: fetchError.message }
        }

        // Ensure existingEntity.components is typed correctly
        const components = existingEntity.components as Record<string, any>

        // Remove the specific component from the JSONB object
        const { [componentKey]: _, ...remainingComponents } = components

        const { data, error } = await supabase
          .from('entities')
          .update({ components: remainingComponents })
          .eq('id', id)
          .single()

        if (error) {
          return { error: error.message }
        }

        return { data }
      },
      invalidatesTags: (result, error, { id }) => [
        { type: TAG_NAME_FOR_GENERAL_ENTITY, id }
      ]
    })
    /**
     * End Components
     */
  })
})

/**
 * Middleware to react to state/entity updates and update the Space app
 */
export const listenerMiddlewareEntities = createListenerMiddleware()

// **Pending Actions Listener**
listenerMiddlewareEntities.startListening({
  predicate: (action) =>
    entitiesApi.endpoints.createEntity.matchPending(action) ||
    entitiesApi.endpoints.updateEntity.matchPending(action) ||
    entitiesApi.endpoints.updateEntityTreeItem.matchPending(action) ||
    entitiesApi.endpoints.batchUpdateEntities.matchPending(action) ||
    entitiesApi.endpoints.deleteEntity.matchPending(action) ||
    // components
    entitiesApi.endpoints.addComponentToEntity.matchPending(action) ||
    entitiesApi.endpoints.getComponentsOfEntity.matchPending(action) ||
    entitiesApi.endpoints.updateComponentOnEntity.matchPending(action) ||
    entitiesApi.endpoints.deleteComponentFromEntity.matchPending(action),
  effect: async (action, listenerApi) => {
    console.log('match pending running', action, listenerApi)
    const state = listenerApi.getState() as RootState

    // Access all queries from the entitiesApi cache
    const queries = state[entitiesApi.reducerPath]?.queries || {}

    // Extract all entities from each cached query
    const allEntities: DatabaseEntity[] = []

    try {
      Object.keys(queries).forEach((queryKey) => {
        const query = queries[queryKey]

        // Ensure query.data exists and is an array
        if (query?.data && Array.isArray(query.data)) {
          // Type assertion: Now we can safely assume query.data is an array of DatabaseEntity[]
          const entitiesArray = query.data as DatabaseEntity[]

          allEntities.push(...entitiesArray)
        }
      })
    } catch (error) {
      console.error('Error while extracting entities from cache:', error)
    }

    updateCurrentlySelectedEntity(state, allEntities, listenerApi)

    // Pass the optimistic changes to PlayCanvas or your engine
    // console.log('Optimistically updating entities', allEntities)
    updateEngineApp(allEntities, { isOptimistic: true })
  }
})

listenerMiddlewareEntities.startListening({
  predicate: (action) =>
    entitiesApi.endpoints.createEntity.matchFulfilled(action) ||
    entitiesApi.endpoints.updateEntity.matchFulfilled(action) ||
    entitiesApi.endpoints.updateEntityTreeItem.matchFulfilled(action) ||
    entitiesApi.endpoints.batchUpdateEntities.matchFulfilled(action) ||
    entitiesApi.endpoints.deleteEntity.matchFulfilled(action) ||
    // components
    entitiesApi.endpoints.addComponentToEntity.matchFulfilled(action) ||
    entitiesApi.endpoints.getComponentsOfEntity.matchFulfilled(action) ||
    entitiesApi.endpoints.updateComponentOnEntity.matchFulfilled(action) ||
    entitiesApi.endpoints.deleteComponentFromEntity.matchFulfilled(action),
  effect: async (action, listenerApi) => {
    console.log('match fulfilled running', action, listenerApi)
    const state = listenerApi.getState() as RootState

    // Access all queries from the entitiesApi cache
    const queries = state[entitiesApi.reducerPath]?.queries || {}

    // Extract all entities from each cached query
    const allEntities: DatabaseEntity[] = []

    try {
      Object.keys(queries).forEach((queryKey) => {
        const query = queries[queryKey]

        // Ensure query.data exists and is an array
        if (query?.data && Array.isArray(query.data)) {
          // Type assertion: Now we can safely assume query.data is an array of DatabaseEntity[]
          const entitiesArray = query.data as DatabaseEntity[]

          allEntities.push(...entitiesArray)
        }
      })
    } catch (error) {
      console.error('Error while extracting entities from cache:', error)
    }

    updateCurrentlySelectedEntity(state, allEntities, listenerApi)

    // Apply confirmed changes to PlayCanvas or your engine
    // console.log('Applying confirmed updates to entities', allEntities)
    updateEngineApp(allEntities, { isOptimistic: false })
  }
})

listenerMiddlewareEntities.startListening({
  predicate: (action) =>
    entitiesApi.endpoints.createEntity.matchRejected(action) ||
    entitiesApi.endpoints.updateEntity.matchRejected(action) ||
    entitiesApi.endpoints.updateEntityTreeItem.matchRejected(action) ||
    entitiesApi.endpoints.batchUpdateEntities.matchRejected(action) ||
    entitiesApi.endpoints.deleteEntity.matchRejected(action) ||
    // components
    entitiesApi.endpoints.addComponentToEntity.matchRejected(action) ||
    entitiesApi.endpoints.getComponentsOfEntity.matchRejected(action) ||
    entitiesApi.endpoints.updateComponentOnEntity.matchRejected(action) ||
    entitiesApi.endpoints.deleteComponentFromEntity.matchRejected(action),
  effect: async (action, listenerApi) => {
    console.log('match rejected running', action, listenerApi)
    const state = listenerApi.getState() as RootState

    // Access all queries from the entitiesApi cache
    const queries = state[entitiesApi.reducerPath]?.queries || {}

    // Extract all entities from each cached query
    const allEntities: DatabaseEntity[] = []

    try {
      Object.keys(queries).forEach((queryKey) => {
        const query = queries[queryKey]

        // Ensure query.data exists and is an array
        if (query?.data && Array.isArray(query.data)) {
          // Type assertion: Now we can safely assume query.data is an array of DatabaseEntity[]
          const entitiesArray = query.data as DatabaseEntity[]

          allEntities.push(...entitiesArray)
        }
      })
    } catch (error) {
      console.error('Error while extracting entities from cache:', error)
    }

    updateCurrentlySelectedEntity(state, allEntities, listenerApi)

    // Revert the changes
    // console.log('Reverting updates to entities', allEntities)
    updateEngineApp(allEntities, { isReverted: true })
  }
})

/**
 * Updates currentlySeletedEntity since it's separate state from RTK
 */
function updateCurrentlySelectedEntity(
  state: RootState,
  allEntities: DatabaseEntity[],
  listenerApi: any
) {
  const currentlySelectedEntity = state.local.currentEntity
  console.log(
    'updateCurrentlySelectedEntity components', //@ts-ignore
    allEntities.find((entity) => entity.id === currentlySelectedEntity?.id)
      .components,
    currentlySelectedEntity?.components
  )
  if (currentlySelectedEntity) {
    const updatedEntity = allEntities.find(
      (entity) => entity.id === currentlySelectedEntity.id
    )
    if (updatedEntity) {
      listenerApi.dispatch(setCurrentEntityUseOnlyForId(updatedEntity))
    }
  }
}

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
  useUpdateEntityTreeItemMutation,
  useGetSingleEntityQuery,
  useLazyGetAllEntitiesQuery,
  useDeleteEntityMutation,

  useAddComponentToEntityMutation,
  useGetComponentsOfEntityQuery,
  useUpdateComponentOnEntityMutation,
  useDeleteComponentFromEntityMutation
} = entitiesApi
