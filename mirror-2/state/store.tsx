'use client'
import { combineReducers, configureStore } from '@reduxjs/toolkit'
import { setupListeners } from '@reduxjs/toolkit/query/react'
import { listenerMiddlewareLocal, localSlice } from '@/state/local.slice'
import { listenerMiddlewareSpaces, spacesApi } from '@/state/api/spaces'
import { scenesApi } from '@/state/api/scenes'
import { entitiesApi, listenerMiddlewareEntities } from '@/state/api/entities'
import { assetsApi } from '@/state/api/assets'
import { spacePacksApi } from '@/state/api/space-packs'
import { spacePackSlice } from '@/state/space-pack.slice'
import storage from 'redux-persist/lib/storage'
import { persistStore, persistReducer } from 'redux-persist'

// const persistConfig = {
//   key: 'persist',
//   storage
// }

// const rootReducer = combineReducers({
//   user: userSlice
// })

export const makeStore = () => {
  return configureStore({
    reducer: {
      // Add the generated reducer as a specific top-level slice
      [localSlice.reducerPath]: localSlice.reducer,
      [spacePackSlice.reducerPath]: spacePackSlice.reducer,
      [assetsApi.reducerPath]: assetsApi.reducer,
      [spacesApi.reducerPath]: spacesApi.reducer,
      [scenesApi.reducerPath]: scenesApi.reducer,
      [entitiesApi.reducerPath]: entitiesApi.reducer,
      [spacePacksApi.reducerPath]: spacePacksApi.reducer
    },
    // Adding the api middleware enables caching, invalidation, polling,
    // and other useful features of `rtk-query`.
    middleware: (getDefaultMiddleware) =>
      getDefaultMiddleware()
        .concat(assetsApi.middleware)
        .concat(spacesApi.middleware)
        .concat(scenesApi.middleware)
        .concat(entitiesApi.middleware)
        .concat(spacePacksApi.middleware)
        .concat(listenerMiddlewareLocal.middleware)
        .concat(listenerMiddlewareSpaces.middleware)
        .concat(listenerMiddlewareEntities.middleware)
  })
}

// export const makeStore = () => {
//   const isServer = typeof window === 'undefined'
//   if (isServer) {
//     return makeConfiguredStore()
//   } else {
//     const persistedReducer = persistReducer(persistConfig, rootReducer)
//     let store: any = configureStore({
//       reducer: persistedReducer
//     })
//     store.__persistor = persistStore(store)
//     return store
//   }
// }

// optional, but required for refetchOnFocus/refetchOnReconnect behaviors
// see `setupListeners` docs - takes an optional callback as the 2nd arg for customization
// setupListeners(store.dispatch)

// Infer the type of makeStore
export type AppStore = ReturnType<typeof makeStore>
// Infer the `RootState` and `AppDispatch` types from the store itself
export type RootState = ReturnType<AppStore['getState']>
export type AppDispatch = AppStore['dispatch']
