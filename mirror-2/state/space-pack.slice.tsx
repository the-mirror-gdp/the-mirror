'use client'
import * as pc from 'playcanvas'
import { AssetId, DatabaseAsset } from '@/state/api/assets'
import { setCurrentScene } from '@/state/local.slice'
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
  manifestFile: {
    short_name: string
    name: string
    start_url: string
    display: string
    icons: {
      src: string
      sizes: string
      type: string
    }[]
  }
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
  ],
  manifestFile: {
    short_name: '',
    name: '',
    start_url: '',
    display: '',
    icons: []
  }
}

export const spacePackSlice = createSlice({
  name: 'spacePacks',
  initialState,
  reducers: {
    updateSceneSettings: (state, action) => {
      const { sceneId, settingKey, settingValue } = action.payload

      // Find the scene by ID
      // is this correct?? Seems like we should grab it from the scenesApi
      // const scene = state.sceneFiles.find((scene) => scene.id === sceneId)

      // if (scene) {
      //   // Update the appropriate setting in the scene
      //   if (settingKey in scene.settings) {
      //     // If it's a known top-level setting like 'physics' or 'render'
      //     scene.settings[settingKey] = settingValue
      //   } else if (settingKey in scene.settings.render) {
      //     // For nested settings, like render settings
      //     scene.settings.render[settingKey] = settingValue
      //   } else if (settingKey in scene.settings.physics) {
      //     // For nested physics settings
      //     scene.settings.physics[settingKey] = settingValue
      //   }
      // }
    },
    updateSceneName: (state, action) => {
      // first, update config.json.scenes
      // second, update the <sceneId>.json.name
      // finally, trigger engine updates with this
    },
    updateManifestFile: (state, action) => {
      state.manifestFile = action.payload
    }
  }
})

export const { updateManifestFile, updateSceneSettings } =
  spacePackSlice.actions

// Middleware
export const listenerMiddlewareSpacePack = createListenerMiddleware()

listenerMiddlewareSpacePack.startListening({
  actionCreator: updateSceneSettings,
  effect: async (action, listenerApi) => {
    const { sceneId, settingKey, settingValue } = action.payload

    // Assuming `pc` is the PlayCanvas namespace
    // and `app` is the PlayCanvas app instance

    const app = pc.app
    if (!app) {
      throw new Error('Space app reference not found')
    }

    // Get the active scene
    const scene = app.root.findByName('SceneName') // Replace 'SceneName' with actual scene
    console.log('not implemented, doing scene change first')
    // if (scene) {
    //   switch (settingKey) {
    //     case 'fog_end':
    //       app.scene.fogEnd = settingValue // Update fog_end value
    //       break
    //     case 'gravity':
    //       app.systems.rigidbody.gravity.set(
    //         settingValue[0],
    //         settingValue[1],
    //         settingValue[2]
    //       ) // Update gravity
    //       break
    //     case 'fog_color':
    //       app.scene.fogColor.set(
    //         settingValue[0],
    //         settingValue[1],
    //         settingValue[2]
    //       ) // Update fog color
    //       break
    //     // Add other cases for settings that you need to update
    //     default:
    //       console.warn(`Unknown setting key: ${settingKey}`)
    //   }

    //   // Trigger a scene update if necessary
    //   app.scene.update() // Make sure the scene is refreshed
    // }
  }
})

listenerMiddlewareSpacePack.startListening({
  actionCreator: setCurrentScene,
  effect: async (action, listenerApi) => {
    const { id: sceneId, name } = action.payload
    const app = window.pc.app
    if (!app) {
      throw new Error('Space app reference not found')
    }
    // TODO change to find by url to avoid name collision
    const scene = app.root.findByName(name)
    if (!scene) {
      throw new Error('Scene not found')
    }
    app.scenes.changeScene(scene.name)
  }
})

// Selectors
export const selectUiSoundsCanPlay = (state: RootState) =>
  state.local.uiSoundsCanPlay

export default spacePackSlice.reducer
