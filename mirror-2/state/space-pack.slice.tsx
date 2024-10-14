'use client'
import { RootState } from '@/state/store'
import { createListenerMiddleware, createSlice } from '@reduxjs/toolkit'

/**
 * The Space Pack reducer creates the computed state from scenes, entities, assets, etc. to mirror the format that the engine expects. Redux is the source of truth. Example flow:
 * 0. Entity changes, latest entity is on the store.entitiesApi (RTK query)
 * 1. Reducer computes the new Space Pack Slice
 * 2. Where appropriate, File (Blob) is created/updated or deleted
 *     Space create/update: manifest.json File (Blob) is upserted
 *     Scene create/update: <sceneId>.json File (Blob) is upserted
 *     Entity create/update: config.json File (Blob) is upserted
 *     Asset create/update: /files/<assetId> is upserted (NOTE: not every asset will have a /files/ path, e.g. a renderAsset (type: render). That woudl just live in config.json and reference  "data": {
        "containerAsset": containerAssetId, (asset of type: container)
        "renderIndex": 0
      })
 */

export type ControlBarView =
  | 'assets'
  | 'hierarchy'
  | 'scenes'
  | 'code'
  | 'database'
  | 'versions'
  | 'settings'

interface SpacePackState {
  uiSoundsCanPlay: boolean
}

// Define the initial state using that type
const initialState: SpacePackState = {
  uiSoundsCanPlay: true
}

export const spacePackSlice = createSlice({
  name: 'spacePacks',
  initialState,
  reducers: {
    turnOffUiSounds: (state) => {
      state.uiSoundsCanPlay = false
    }
  }
})

export const { turnOffUiSounds } = spacePackSlice.actions

// Middleware
export const listenerMiddlewareLocal = createListenerMiddleware()
listenerMiddlewareLocal.startListening({
  actionCreator: turnOffUiSounds,
  effect: async (action, listenerApi) => {
    // setAnalyticsUserId(action.payload.id)
  }
})

// Selectors
export const selectUiSoundsCanPlay = (state: RootState) =>
  state.local.uiSoundsCanPlay

export default spacePackSlice.reducer
