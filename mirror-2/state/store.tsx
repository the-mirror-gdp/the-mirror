'use client'
import { configureStore } from '@reduxjs/toolkit'
import { setupListeners } from '@reduxjs/toolkit/query/react'
import { listenerMiddlewareLocal, localSlice } from '@/state/local'
import { listenerMiddlewareSpaces, spacesApi } from '@/state/spaces'
import { scenesApi } from '@/state/scenes'
import { entitiesApi, listenerMiddlewareEntities } from '@/state/entities'
import { assetsApi } from '@/state/assets'
import { pcImportsApi } from '@/state/pc-imports'

export const store = configureStore({
  reducer: {
    // Add the generated reducer as a specific top-level slice
    [localSlice.reducerPath]: localSlice.reducer,
    [assetsApi.reducerPath]: assetsApi.reducer,
    [spacesApi.reducerPath]: spacesApi.reducer,
    [scenesApi.reducerPath]: scenesApi.reducer,
    [entitiesApi.reducerPath]: entitiesApi.reducer,
    [pcImportsApi.reducerPath]: pcImportsApi.reducer
  },
  // Adding the api middleware enables caching, invalidation, polling,
  // and other useful features of `rtk-query`.
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware()
      .concat(assetsApi.middleware)
      .concat(spacesApi.middleware)
      .concat(scenesApi.middleware)
      .concat(entitiesApi.middleware)
      .concat(pcImportsApi.middleware)
      .concat(listenerMiddlewareLocal.middleware)
      .concat(listenerMiddlewareSpaces.middleware)
      .concat(listenerMiddlewareEntities.middleware)
})

// optional, but required for refetchOnFocus/refetchOnReconnect behaviors
// see `setupListeners` docs - takes an optional callback as the 2nd arg for customization
setupListeners(store.dispatch)

// Infer the `RootState` and `AppDispatch` types from the store itself
export type RootState = ReturnType<typeof store.getState>
// Inferred type
export type AppDispatch = typeof store.dispatch
