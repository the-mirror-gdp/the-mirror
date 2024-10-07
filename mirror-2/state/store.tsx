"use client"
import { configureStore } from '@reduxjs/toolkit'
import { setupListeners } from '@reduxjs/toolkit/query/react'
import { localSlice } from '@/state/local'
import { spacesApi } from '@/state/spaces'
import { scenesApi } from '@/state/scenes'
import { entitiesApi } from '@/state/entities'
import { assetsApi } from '@/state/assets'

export const store = configureStore({
  reducer: {
    // Add the generated reducer as a specific top-level slice
    [localSlice.reducerPath]: localSlice.reducer,
    [assetsApi.reducerPath]: assetsApi.reducer,
    [spacesApi.reducerPath]: spacesApi.reducer,
    [scenesApi.reducerPath]: scenesApi.reducer,
    [entitiesApi.reducerPath]: entitiesApi.reducer,
  },
  // Adding the api middleware enables caching, invalidation, polling,
  // and other useful features of `rtk-query`.
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware()
      .concat(assetsApi.middleware)
      .concat(spacesApi.middleware)
      .concat(scenesApi.middleware)
      .concat(entitiesApi.middleware)
})

// optional, but required for refetchOnFocus/refetchOnReconnect behaviors
// see `setupListeners` docs - takes an optional callback as the 2nd arg for customization
setupListeners(store.dispatch)

// Infer the `RootState` and `AppDispatch` types from the store itself
export type RootState = ReturnType<typeof store.getState>
// Inferred type
export type AppDispatch = typeof store.dispatch
