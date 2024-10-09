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
  expandedEntityIds: string[]
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
  expandedEntityIds: [], // Initialize the sceneTrees state
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
  },
});

export const {
  turnOffUiSounds,
  turnOnUiSounds,
  setControlBarCurrentView,
  updateLocalUserState,
  clearLocalUserState,
  setCurrentScene,
  setExpandedEntityIds
} = localSlice.actions;

// Selectors
export const selectUiSoundsCanPlay = (state: RootState) => state.local.uiSoundsCanPlay;
export const selectControlBarCurrentView = (state: RootState) => state.local.controlBarCurrentView;
export const selectLocalUserState = (state: RootState) => state.local.user;
export const getCurrentScene = (state: RootState): Scene | undefined => {
  return state.local.currentScene;
};
export const selectExpandedEntityIds = (state: RootState) => state.local.expandedEntityIds; // Selector for scene trees

export default localSlice.reducer;
