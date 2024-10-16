'use client'
import * as pc from 'playcanvas'
import { AssetId, DatabaseAsset } from '@/state/api/assets'
import { setCurrentSceneUseOnlyForId } from '@/state/local.slice'
import { RootState } from '@/state/store'
import { createListenerMiddleware, createSlice } from '@reduxjs/toolkit'
import { DatabaseScene, scenesApi } from '@/state/api/scenes'

/**
 * The Space Pack reducer creates the computed state from scenes, entities, assets, etc. Redux is the source of truth and engine state is computed from that.
 */

// interface SpacePackState {
//   configFile: {
//     application_properties: {}
//     scenes: {
//       name: string
//       url: string
//     }[]
//     assets: {
//       [assetId: AssetId]: DatabaseAsset
//     }
//   }
//   sceneFiles: {
//     name: string
//     created: string
//     settings: {
//       priority_scripts?: any[]
//       physics: {
//         gravity: [number, number, number]
//       }
//       render: {
//         fog_end: number
//         fog_start: number
//         global_ambient: [number, number, number]
//         tonemapping: number
//         fog_color: [number, number, number]
//         fog: string
//         skybox: null | string
//         fog_density: number
//         gamma_correction: number
//         exposure: number
//         lightmapSizeMultiplier: number
//         lightmapMaxResolution: number
//         lightmapMode: number
//         skyboxIntensity: number
//         skyboxMip: number
//         skyboxRotation: [number, number, number]
//         lightmapFilterEnabled: boolean
//         lightmapFilterRange: number
//         lightmapFilterSmoothness: number
//         ambientBake: boolean
//         ambientBakeNumSamples: number
//         ambientBakeSpherePart: number
//         ambientBakeOcclusionBrightness: number
//         ambientBakeOcclusionContrast: number
//         clusteredLightingEnabled: boolean
//         lightingCells: [number, number, number]
//         lightingMaxLightsPerCell: number
//         lightingCookieAtlasResolution: number
//         lightingShadowAtlasResolution: number
//         lightingShadowType: number
//         lightingCookiesEnabled: boolean
//         lightingAreaLightsEnabled: boolean
//         lightingShadowsEnabled: boolean
//         skyType: string
//         skyMeshPosition: [number, number, number]
//         skyMeshRotation: [number, number, number]
//         skyMeshScale: [number, number, number]
//         skyCenter: [number, number, number]
//       }
//     }
//     entities: {
//       [entityId: string]: {
//         scale: [number, number, number]
//         name: string
//         parent: null | string
//         resource_id: string
//         labels: string[]
//         enabled: boolean
//         components: {
//           pack: any
//         }
//         position: [number, number, number]
//         rotation: [number, number, number]
//         children: string[]
//         template: null | string
//         tags: string[]
//       }
//     }
//     checkpoint_id: string
//     branch_id: string
//     id: number
//   }[]
//   manifestFile: {
//     short_name: string
//     name: string
//     start_url: string
//     display: string
//     icons: {
//       src: string
//       sizes: string
//       type: string
//     }[]
//   }
// }

// Define the initial state using that type
// const initialState: SpacePackState = {
//   configFile: {
//     application_properties: {},
//     scenes: [
//       {
//         name: '',
//         url: ''
//       }
//     ],
//     assets: {}
//   },
//   sceneFiles: [
//     {
//       name: '',
//       created: '',
//       settings: {
//         priority_scripts: [],
//         physics: {
//           gravity: [0, -9.8, 0]
//         },
//         render: {
//           fog_end: 1000,
//           fog_start: 1,
//           global_ambient: [0.156, 0.235, 0.314],
//           tonemapping: 0,
//           fog_color: [0, 0, 0],
//           fog: 'none',
//           skybox: null,
//           fog_density: 0.01,
//           gamma_correction: 1,
//           exposure: 1.5,
//           lightmapSizeMultiplier: 16,
//           lightmapMaxResolution: 2048,
//           lightmapMode: 0,
//           skyboxIntensity: 1,
//           skyboxMip: 0,
//           skyboxRotation: [0, 0, 0],
//           lightmapFilterEnabled: false,
//           lightmapFilterRange: 10,
//           lightmapFilterSmoothness: 0.2,
//           ambientBake: false,
//           ambientBakeNumSamples: 1,
//           ambientBakeSpherePart: 0.4,
//           ambientBakeOcclusionBrightness: 0,
//           ambientBakeOcclusionContrast: 0,
//           clusteredLightingEnabled: true,
//           lightingCells: [10, 3, 10],
//           lightingMaxLightsPerCell: 255,
//           lightingCookieAtlasResolution: 2048,
//           lightingShadowAtlasResolution: 2048,
//           lightingShadowType: 0,
//           lightingCookiesEnabled: false,
//           lightingAreaLightsEnabled: false,
//           lightingShadowsEnabled: true,
//           skyType: 'infinite',
//           skyMeshPosition: [0, 0, 0],
//           skyMeshRotation: [0, 0, 0],
//           skyMeshScale: [100, 100, 100],
//           skyCenter: [0, 0.1, 0]
//         }
//       },
//       entities: {},
//       checkpoint_id: '',
//       branch_id: '',
//       id: 0
//     }
//   ],
//   manifestFile: {
//     short_name: '',
//     name: '',
//     start_url: '',
//     display: '',
//     icons: []
//   }
// }

interface SpacePackState {
  mode: 'build' | 'play'
  scenes: DatabaseScene[]
}

const initialState: SpacePackState = {
  mode: 'build',
  scenes: [] as DatabaseScene[] // List of all scenes
}

export const spacePackSlice = createSlice({
  name: 'spacePack',
  initialState,
  reducers: {}
  // extraReducers: (builder) => {
  //   // When getAllScenes or getSingleScene succeeds, update scenes
  //   builder
  //     .addMatcher(
  //       scenesApi.endpoints.getAllScenes.matchFulfilled,
  //       (state, { payload }) => {
  //         state.scenes = mergeScenes(state.scenes, payload)
  //       }
  //     )
  //     .addMatcher(
  //       scenesApi.endpoints.getSingleScene.matchFulfilled,
  //       (state, { payload }) => {
  //         state.scenes = mergeScenes(state.scenes, [payload])
  //       }
  //     )
  //     .addMatcher(
  //       scenesApi.endpoints.createScene.matchFulfilled,
  //       (state, { payload }) => {
  //         state.scenes = mergeScenes(state.scenes, [payload])
  //       }
  //     )
  //     .addMatcher(
  //       scenesApi.endpoints.updateScene.matchFulfilled,
  //       (state, { payload }) => {
  //         state.scenes = mergeScenes(state.scenes, [payload])
  //       }
  //     )
  //     .addMatcher(
  //       scenesApi.endpoints.deleteScene.matchFulfilled,
  //       (state, { meta }) => {
  //         const sceneId = meta.arg.originalArgs // Extract the scene ID
  //         state.scenes = state.scenes.filter((scene) => scene.id !== sceneId)
  //       }
  //     )
  // }
})

// Helper function to merge and deduplicate scenes
function mergeScenes(existingScenes, newScenes): any[] {
  const scenesMap = new Map(existingScenes.map((scene) => [scene.id, scene]))

  // Add new scenes or update existing ones
  newScenes.forEach((scene) => {
    scenesMap.set(scene.id, scene)
  })

  // Convert the map back to an array
  return Array.from(scenesMap.values())
}

// Selectors
export const selectUiSoundsCanPlay = (state: RootState) =>
  state.local.uiSoundsCanPlay

export default spacePackSlice.reducer
