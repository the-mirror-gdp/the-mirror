// listenerMiddlewares.ts
import { createListenerMiddleware } from '@reduxjs/toolkit';
import { updateEngineApp } from '@/state/engine/engine'; // Adjust path as needed
import { RootState } from '@/state/store'; // Adjust path as needed
import { DatabaseEntity, entitiesApi } from '@/state/entities'; // Adjust path as needed


// Selector to aggregate all entities from getAllEntities queries
export const selectAllEntities = (state: RootState): DatabaseEntity[] => {
  const queries = state[entitiesApi.reducerPath]?.queries || {};
  const entities: DatabaseEntity[] = [];

  Object.keys(queries).forEach((key) => {
    // Check if the query key starts with 'getAllEntities'
    if (key.startsWith('getAllEntities')) {
      const query = queries[key];
      if (Array.isArray(query?.data)) {
        entities.push(...query.data);
      }
    }
  });

  return entities;
};


function createGeneralEntityListenerMiddleware(
  api: typeof entitiesApi, // Type the api correctly
  generalEntityName: string,
  getEntities: (state: RootState) => DatabaseEntity[]
) {
  const listenerMiddleware = createListenerMiddleware();

  // **Pending Actions Listener**
  listenerMiddleware.startListening({
    predicate: (action) =>
      api.endpoints.createEntity.matchPending(action) ||
      api.endpoints.updateEntity.matchPending(action) ||
      api.endpoints.batchUpdateEntities.matchPending(action) ||
      api.endpoints.deleteEntity.matchPending(action),
    effect: async (action, listenerApi) => {
      const state = listenerApi.getState() as RootState;
      const entities = getEntities(state);

      // Pass the optimistic changes to PlayCanvas
      console.log(`Optimistically updating ${generalEntityName}`, entities);
      updateEngineApp(entities, { isOptimistic: true });
    },
  });

  // **Fulfilled Actions Listener**
  listenerMiddleware.startListening({
    predicate: (action) =>
      api.endpoints.createEntity.matchFulfilled(action) ||
      api.endpoints.updateEntity.matchFulfilled(action) ||
      api.endpoints.batchUpdateEntities.matchFulfilled(action) ||
      api.endpoints.deleteEntity.matchFulfilled(action) ||
      api.endpoints.getAllEntities.matchFulfilled(action),
    effect: async (action, listenerApi) => {
      const state = listenerApi.getState() as RootState;
      const entities = getEntities(state);

      console.log(`Applying confirmed updates to ${generalEntityName}`, entities);
      updateEngineApp(entities, { isOptimistic: false });
    },
  });

  // **Rejected Actions Listener**
  listenerMiddleware.startListening({
    predicate: (action) =>
      api.endpoints.createEntity.matchRejected(action) ||
      api.endpoints.updateEntity.matchRejected(action) ||
      api.endpoints.batchUpdateEntities.matchRejected(action) ||
      api.endpoints.deleteEntity.matchRejected(action),
    effect: async (action, listenerApi) => {
      const state = listenerApi.getState() as RootState;
      const entities = getEntities(state);

      console.log(`Reverting updates for ${generalEntityName}`, entities);
      updateEngineApp(entities, { isReverted: true });
    },
  });

  return listenerMiddleware;
}

export { createGeneralEntityListenerMiddleware };
