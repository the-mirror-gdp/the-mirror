import { RootState } from '@/state/store';
import { Database } from '@/utils/database.types';
import type { PayloadAction } from '@reduxjs/toolkit';
import { createSlice } from '@reduxjs/toolkit';

export type ControlBarView = "assets" | "hierarchy" | "scenes" | "code" | "database" | "versions" | "settings";

export type Scene = Database["public"]["Tables"]["scenes"]["Row"];

interface LocalUserState {
  id: string,
  email?: string,
  is_anonymous?: boolean,
}

interface LocalState {
  uiSoundsCanPlay: boolean;
  controlBarCurrentView: ControlBarView;
  user?: LocalUserState;

  // Viewport et al.
  currentScene?: Scene;

  // Property to track the entire tree for each scene
  expandedEntityIds: string[];
  automaticallyExpandedSceneIds: string[] // used for checking whether we auto expanded or not for a scene's entity hierarchy
}

// Define the initial state using that type
const initialState: LocalState = {
  uiSoundsCanPlay: true,
  controlBarCurrentView: "hierarchy",
  user: {
    email: "",
    id: "",
    is_anonymous: false
  },
  currentScene: {
    created_at: '', id: '', name: '', space_id: '', updated_at: ''
  },
  expandedEntityIds: [],
  automaticallyExpandedSceneIds: [],
}

export const localSlice = createSlice({
  name: 'local',
  initialState,
  reducers: {
    turnOffUiSounds: (state) => {
      state.uiSoundsCanPlay = false;
    },
    turnOnUiSounds: (state) => {
      state.uiSoundsCanPlay = true;
    },
    setControlBarCurrentView: (state, action: PayloadAction<ControlBarView>) => {
      state.controlBarCurrentView = action.payload;
    },
    updateLocalUserState: (state, action: PayloadAction<LocalUserState>) => {
      state.user = action.payload;
    },
    clearLocalUserState: (state) => {
      state.user = undefined;
    },
    setCurrentScene: (state, action: PayloadAction<Scene>) => {
      state.currentScene = action.payload;
    },
    setExpandedEntityIds: (state, action: PayloadAction<{ entityIds: string[] }>) => {
      const { entityIds } = action.payload;

      // update, ensuring no duplicate IDs
      state.expandedEntityIds = entityIds.filter(function (x, i, a) {
        return a.indexOf(x) == i;
      });
    },

    addExpandedEntityIds: (state, action: PayloadAction<{ entityIds: string[] }>) => {
      const { entityIds } = action.payload;

      // add new IDs, ensuring no duplicate IDs
      state.expandedEntityIds = [...state.expandedEntityIds, ...entityIds].filter(function (x, i, a) {
        return a.indexOf(x) == i;
      });
    },

    insertAutomaticallyExpandedSceneIds: (state, action: PayloadAction<{ sceneId: string }>) => {
      const { sceneId } = action.payload;

      state.automaticallyExpandedSceneIds.push(sceneId)
      // update, ensuring no duplicate IDs
      state.automaticallyExpandedSceneIds = state.automaticallyExpandedSceneIds.filter(function (x, i, a) {
        return a.indexOf(x) == i;
      });
    },
  },
});

export const {
  turnOffUiSounds,
  turnOnUiSounds,
  setControlBarCurrentView,
  updateLocalUserState,
  clearLocalUserState,
  setCurrentScene,
  setExpandedEntityIds,
  addExpandedEntityIds,
  insertAutomaticallyExpandedSceneIds
} = localSlice.actions;

// Selectors
export const selectUiSoundsCanPlay = (state: RootState) => state.local.uiSoundsCanPlay;
export const selectControlBarCurrentView = (state: RootState) => state.local.controlBarCurrentView;
export const selectLocalUserState = (state: RootState) => state.local.user;
export const getCurrentScene = (state: RootState): Scene | undefined => {
  return state.local.currentScene;
};
export const selectExpandedEntityIds = (state: RootState) => state.local.expandedEntityIds;
export const selectAutomaticallyExpandedSceneIds = (state: RootState) => state.local.automaticallyExpandedSceneIds;

export default localSlice.reducer;
