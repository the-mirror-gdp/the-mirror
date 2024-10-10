import { createSlice, createEntityAdapter, createAsyncThunk } from '@reduxjs/toolkit';
import { createApi, fakeBaseQuery } from '@reduxjs/toolkit/query/react';
import { createSupabaseBrowserClient } from '@/utils/supabase/client';
import { TAG_NAME_FOR_BUILD_MODE_SPACE_QUERY } from '@/state/shared-cache-tags';


export const TAG_NAME_FOR_GENERAL_ENTITY = 'Entities'

// Supabase API for spaces
export const entitiesApi = createApi({
  reducerPath: 'entitiesApi',
  baseQuery: fakeBaseQuery(),
  tagTypes: [TAG_NAME_FOR_GENERAL_ENTITY, 'LIST', TAG_NAME_FOR_BUILD_MODE_SPACE_QUERY],
  endpoints: (builder) => ({

    createEntity: builder.mutation<any, { name: string, scene_id: string, parent_id?: string, order_under_parent?: number, isRootEntity?: boolean }>({
      queryFn: async ({ name, scene_id, parent_id, order_under_parent, isRootEntity }) => {
        const supabase = createSupabaseBrowserClient();
        const { data: { user }, error: authError } = await supabase.auth.getUser();

        if (!user) {
          return { error: 'User not found' };
        }

        // if no parent_id and not the root entity upon creation, find the root entity
        if (!parent_id && !isRootEntity) {
          const { data: rootEntity, error: rootEntityError } = await supabase
            .from("entities")
            .select("*")
            .eq("scene_id", scene_id)
            .is("parent_id", null)
            .single();

          if (rootEntityError) {
            return { error: rootEntityError.message };
          }

          parent_id = rootEntity.id;
        }

        if (parent_id && (order_under_parent === undefined || order_under_parent === null)) {
          // need to find the order_under_parent to use for the new entity
          const { data: entitiesWithSameParent, error: parentEntityError } = await supabase
            .from("entities")
            .select("*")
            .eq("parent_id", parent_id)

          if (parentEntityError) {
            return { error: parentEntityError.message };
          }
          // find the highest order_under_parent
          if (entitiesWithSameParent) {
            const highestOrderUnderParent = entitiesWithSameParent.reduce((max, entity) => {
              const entityOrderUnderParent = entity.order_under_parent ?? -1; // If null or undefined, default to -1
              return (entityOrderUnderParent > max ? entityOrderUnderParent : max);
            }, -1);
            order_under_parent = highestOrderUnderParent + 1;
          }
        }


        const { data, error } = await supabase
          .from("entities")
          .insert({
            name: name,
            scene_id,
            parent_id,
            order_under_parent,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          })
          .select('*')
          .single();

        if (error) {
          return { error: error.message };
        }

        return { data };
      },
      invalidatesTags: [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id: 'LIST' }],

    }),

    getAllEntities: builder.query<any, string>({
      queryFn: async (sceneId) => {
        const supabase = createSupabaseBrowserClient();

        if (!sceneId) {
          return { error: 'No scene_id provided' };
        }

        const { data, error } = await supabase
          .from("entities")
          .select("*")
          .eq("scene_id", sceneId);

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
      providesTags: (result, error, entityId) => [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id: entityId }], // Provide the entity tag based on entityId
    }),

    updateEntity: builder.mutation<any, { id: string, name?: string, parent_id?: string, order_under_parent?: number, scene_id?: string }>({
      queryFn: async ({ id, name, parent_id, order_under_parent, scene_id }) => {
        const supabase = createSupabaseBrowserClient();

        // if no parent_id, find the root entity
        if (!parent_id) {
          if (!scene_id) {
            // must have scene_id to find the root entity
            return { error: 'No scene_id provided' };
          }
          const { data: rootEntity, error: rootEntityError } = await supabase
            .from("entities")
            .select("*")
            .eq("scene_id", scene_id)
            .is("parent_id", null)
            .single();

          if (rootEntityError) {
            return { error: rootEntityError.message };
          }

          parent_id = rootEntity.id;
        }

        // case: parent_id exists but no order_under_parent
        if ((parent_id && order_under_parent === undefined) || (parent_id && order_under_parent === null)) {
          // need to find the order_under_parent to use for the new entity
          const { data: entitiesWithSameParent, error: parentEntityError } = await supabase
            .from("entities")
            .select("*")
            .eq("parent_id", parent_id)

          if (parentEntityError) {
            return { error: parentEntityError.message };
          }
          // find the highest order_under_parent
          const highestOrderUnderParent = entitiesWithSameParent.reduce((max, entity: any) => {
            return entity.order_under_parent > max ? entity.order_under_parent : max;
          }, -1);
          order_under_parent = highestOrderUnderParent + 1;
        }

        // case: parent_id and order_under_parent exist
        // if (parent_id && order_under_parent) {
        //   // increment all order_under_parents below the new entity since it's being inserted
        //   const { data, error }: { data: any, error: any } = await supabase
        //     // @ts-ignore
        //     .rpc('increment_and_resequence_order_under_parent', { p_scene_id: scene_id, p_entity_id: id })
        //     .single();
        // }


        const { data, error } = await supabase
          .from("entities")
          .update(
            { name, parent_id, order_under_parent, scene_id }
          )
          .eq("id", id)
          .single();

        if (error) {
          debugger
          return { error: error.message };
        }
        return { data };
      },
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
      ], // Invalidate tag for entityId
    }),

    batchUpdateEntities: builder.mutation<any, { entities: { id: string, name?: string, scene_id?: string, parent_id?: string, order_under_parent?: number }[] }>({
      queryFn: async ({ entities }) => {
        const supabase = createSupabaseBrowserClient();
        const entityIds = entities.map(entity => entity.id);

        // Fetch all current entities by the provided IDs. This is needed since supabase batch upsert requires ALL properties to be passed in or else it overwrites the existing data.
        const { data: existingEntities, error: fetchError } = await supabase
          .from('entities')
          .select('*')
          .in('id', entityIds);

        if (fetchError) {
          return { error: fetchError.message };
        }

        // Merge each entity's new properties with existing data
        const entitiesToUpsert = entities.map(newEntity => {
          const existingEntity = existingEntities.find(e => e.id === newEntity.id);

          if (existingEntity === undefined) {
            throw new Error(`Entity with ID ${(existingEntity as any).id} doesn't exist`);
          }

          // Merge existing entity fields with new updates
          const data = {
            ...existingEntity,  // Existing entity data
            ...newEntity,       // New updates, this will override fields like name, scene_id, etc.
            updated_at: new Date().toISOString(),  // Update timestamp
          };

          if (!existingEntity?.name) {
            throw new Error(`Entity with ID ${existingEntity?.id} is missing a name`);
          }

          return data
        });

        // Perform the batch upsert
        const { data: upsertData, error: upsertError } = await supabase
          .from('entities')
          .upsert(entitiesToUpsert)
          .select('*');  // You can select specific fields if you want

        if (upsertError) {
          return { error: upsertError.message };
        }

        return { data: upsertData };
      },
      invalidatesTags: [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id: 'LIST' }], // Invalidates the cache
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
      invalidatesTags: (result, error, entityId) => [{ type: TAG_NAME_FOR_GENERAL_ENTITY, id: entityId }]
    }),

  }),
});


// Export the API hooks
export const {
  useCreateEntityMutation, useBatchUpdateEntitiesMutation, useGetAllEntitiesQuery, useUpdateEntityMutation, useGetSingleEntityQuery, useLazyGetAllEntitiesQuery, useDeleteEntityMutation
} = entitiesApi;
