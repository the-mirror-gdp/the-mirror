'use client'
import { DatabaseComponent, DatabaseEntity } from '@/state/api/entities'
import { DatabaseScene } from '@/state/api/scenes'
import { RootState } from '@/state/store'
import { setAnalyticsUserId } from '@/utils/analytics/analytics'
import type { PayloadAction } from '@reduxjs/toolkit'
import { createListenerMiddleware, createSlice } from '@reduxjs/toolkit'

export type ControlBarView =
  | 'assets'
  | 'hierarchy'
  | 'scenes'
  | 'code'
  | 'database'
  | 'versions'
  | 'settings'

interface LocalUserState {
  id: string
  email?: string
  is_anonymous?: boolean
}

interface LocalSlice {
  uiSoundsCanPlay: boolean
  controlBarCurrentView: ControlBarView
  user?: LocalUserState

  // Viewport et al.
  currentScene?: DatabaseScene
  currentEntity?: DatabaseEntity

  // Property to track the entire tree for each scene
  expandedEntityIds: string[]
  automaticallyExpandedSceneIds: number[] // used for checking whether we auto expanded or not for a scene's entity hierarchy
}

// Define the initial state using that type
const initialState: LocalSlice = {
  uiSoundsCanPlay: true,
  controlBarCurrentView: 'hierarchy',
  user: {
    email: '',
    id: '',
    is_anonymous: false
  },
  currentScene: {
    created_at: '',
    id: 0,
    name: '',
    space_id: 0,
    updated_at: '',
    settings: {}
  },
  expandedEntityIds: [],
  automaticallyExpandedSceneIds: []
}

export const localSlice = createSlice({
  name: 'local',
  initialState,
  reducers: {
    turnOffUiSounds: (state) => {
      state.uiSoundsCanPlay = false
    },
    turnOnUiSounds: (state) => {
      state.uiSoundsCanPlay = true
    },
    setControlBarCurrentView: (
      state,
      action: PayloadAction<ControlBarView>
    ) => {
      state.controlBarCurrentView = action.payload
    },
    updateLocalUserState: (state, action: PayloadAction<LocalUserState>) => {
      state.user = action.payload
    },
    clearLocalUserState: (state) => {
      state.user = undefined
    },
    setCurrentScene: (state, action: PayloadAction<DatabaseScene>) => {
      state.currentScene = action.payload
    },
    setCurrentEntity: (state, action: PayloadAction<DatabaseEntity>) => {
      const entity = {
        ...action.payload
      }
      state.currentEntity = entity
    },
    clearCurrentEntity: (state) => {
      state.currentScene = undefined
    },
    setExpandedEntityIds: (
      state,
      action: PayloadAction<{ entityIds: string[] }>
    ) => {
      const { entityIds } = action.payload

      // update, ensuring no duplicate IDs
      state.expandedEntityIds = entityIds.filter(function (x, i, a) {
        return a.indexOf(x) == i
      })
    },

    addExpandedEntityIds: (
      state,
      action: PayloadAction<{ entityIds: string[] }>
    ) => {
      const { entityIds } = action.payload

      // add new IDs, ensuring no duplicate IDs
      state.expandedEntityIds = [
        ...state.expandedEntityIds,
        ...entityIds
      ].filter(function (x, i, a) {
        return a.indexOf(x) == i
      })
    },

    insertAutomaticallyExpandedSceneIds: (
      state,
      action: PayloadAction<{ sceneId: number }>
    ) => {
      const { sceneId } = action.payload

      state.automaticallyExpandedSceneIds.push(sceneId)
      // update, ensuring no duplicate IDs
      state.automaticallyExpandedSceneIds =
        state.automaticallyExpandedSceneIds.filter(function (x, i, a) {
          return a.indexOf(x) == i
        })
    }
  }
})

export const {
  turnOffUiSounds,
  turnOnUiSounds,
  setControlBarCurrentView,
  updateLocalUserState,
  clearLocalUserState,
  setCurrentScene,
  setCurrentEntity,
  clearCurrentEntity,
  setExpandedEntityIds,
  addExpandedEntityIds,
  insertAutomaticallyExpandedSceneIds
} = localSlice.actions

// Middleware
export const listenerMiddlewareLocal = createListenerMiddleware()
listenerMiddlewareLocal.startListening({
  actionCreator: updateLocalUserState,
  effect: async (action, listenerApi) => {
    setAnalyticsUserId(action.payload.id)
  }
})

// Selectors
export const selectUiSoundsCanPlay = (state: RootState) =>
  state.local.uiSoundsCanPlay
export const selectControlBarCurrentView = (state: RootState) =>
  state.local.controlBarCurrentView
export const selectLocalUser = (state: RootState) => state.local.user
export const selectCurrentScene = (
  state: RootState
): DatabaseScene | undefined => {
  return state.local.currentScene
}
export const selectCurrentEntity = (
  state: RootState
): DatabaseEntity | undefined => {
  return state.local.currentEntity
}
import { createSelector } from '@reduxjs/toolkit'

export const selectCurrentEntityComponents = createSelector(
  (state: RootState) => state.local.currentEntity?.components,
  (components: any) => {
    return components
  }
)
export const selectExpandedEntityIds = (state: RootState) =>
  state.local.expandedEntityIds
export const selectAutomaticallyExpandedSceneIds = (state: RootState) =>
  state.local.automaticallyExpandedSceneIds

export default localSlice.reducer
