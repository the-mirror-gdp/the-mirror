'use client'
import { AssetId, DatabaseAsset } from '@/state/api/assets'
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
  configFile: {
    application_properties: {}
    scenes: {
      name: string
      url: string
    }[]
    assets: {
      [assetId: AssetId]: DatabaseAsset
    }
  }
  sceneFiles: {
    name: string
    created: string
    settings: {
      priority_scripts?: any[]
      physics: {
        gravity: [number, number, number]
      }
      render: {
        fog_end: number
        fog_start: number
        global_ambient: [number, number, number]
        tonemapping: number
        fog_color: [number, number, number]
        fog: string
        skybox: null | string
        fog_density: number
        gamma_correction: number
        exposure: number
        lightmapSizeMultiplier: number
        lightmapMaxResolution: number
        lightmapMode: number
        skyboxIntensity: number
        skyboxMip: number
        skyboxRotation: [number, number, number]
        lightmapFilterEnabled: boolean
        lightmapFilterRange: number
        lightmapFilterSmoothness: number
        ambientBake: boolean
        ambientBakeNumSamples: number
        ambientBakeSpherePart: number
        ambientBakeOcclusionBrightness: number
        ambientBakeOcclusionContrast: number
        clusteredLightingEnabled: boolean
        lightingCells: [number, number, number]
        lightingMaxLightsPerCell: number
        lightingCookieAtlasResolution: number
        lightingShadowAtlasResolution: number
        lightingShadowType: number
        lightingCookiesEnabled: boolean
        lightingAreaLightsEnabled: boolean
        lightingShadowsEnabled: boolean
        skyType: string
        skyMeshPosition: [number, number, number]
        skyMeshRotation: [number, number, number]
        skyMeshScale: [number, number, number]
        skyCenter: [number, number, number]
      }
    }
    entities: {
      [entityId: string]: {
        scale: [number, number, number]
        name: string
        parent: null | string
        resource_id: string
        labels: string[]
        enabled: boolean
        components: {
          pack: any
        }
        position: [number, number, number]
        rotation: [number, number, number]
        children: string[]
        template: null | string
        tags: string[]
      }
    }
    checkpoint_id: string
    branch_id: string
    id: number
  }[]
}

// Define the initial state using that type
const initialState: SpacePackState = {
  configFile: {
    application_properties: {},
    scenes: [
      {
        name: '',
        url: ''
      }
    ],
    assets: {}
  },
  sceneFiles: [
    {
      name: '',
      created: '',
      settings: {
        priority_scripts: [],
        physics: {
          gravity: [0, -9.8, 0]
        },
        render: {
          fog_end: 1000,
          fog_start: 1,
          global_ambient: [0.156, 0.235, 0.314],
          tonemapping: 0,
          fog_color: [0, 0, 0],
          fog: 'none',
          skybox: null,
          fog_density: 0.01,
          gamma_correction: 1,
          exposure: 1.5,
          lightmapSizeMultiplier: 16,
          lightmapMaxResolution: 2048,
          lightmapMode: 0,
          skyboxIntensity: 1,
          skyboxMip: 0,
          skyboxRotation: [0, 0, 0],
          lightmapFilterEnabled: false,
          lightmapFilterRange: 10,
          lightmapFilterSmoothness: 0.2,
          ambientBake: false,
          ambientBakeNumSamples: 1,
          ambientBakeSpherePart: 0.4,
          ambientBakeOcclusionBrightness: 0,
          ambientBakeOcclusionContrast: 0,
          clusteredLightingEnabled: true,
          lightingCells: [10, 3, 10],
          lightingMaxLightsPerCell: 255,
          lightingCookieAtlasResolution: 2048,
          lightingShadowAtlasResolution: 2048,
          lightingShadowType: 0,
          lightingCookiesEnabled: false,
          lightingAreaLightsEnabled: false,
          lightingShadowsEnabled: true,
          skyType: 'infinite',
          skyMeshPosition: [0, 0, 0],
          skyMeshRotation: [0, 0, 0],
          skyMeshScale: [100, 100, 100],
          skyCenter: [0, 0.1, 0]
        }
      },
      entities: {},
      checkpoint_id: '',
      branch_id: '',
      id: 0
    }
  ]
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
