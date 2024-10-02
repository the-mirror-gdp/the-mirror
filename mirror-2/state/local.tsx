import { RootState } from '@/state/store'
import type { PayloadAction } from '@reduxjs/toolkit'
import { createSlice } from '@reduxjs/toolkit'
import { createSupabaseBrowserClient } from "@/utils/supabase/client";

export type ControlBarView = "assets" | "scenes" | "code" | "database" | "versions" | "settings"

interface LocalUserState {
  id: string,
  email?: string,
  is_anonymous?: boolean,
}
interface LocalState {
  uiSoundsCanPlay: boolean
  controlBarCurrentView: ControlBarView,
  user?: LocalUserState
}

// Define the initial state using that type
const initialState: LocalState = {
  uiSoundsCanPlay: true,
  controlBarCurrentView: "assets"
}

export const localSlice = createSlice({
  name: 'local',
  // `createSlice` will infer the state type from the `initialState` argument
  initialState,
  reducers: {
    turnOffUiSounds: (state) => {
      state.uiSoundsCanPlay = false
    },
    turnOnUiSounds: (state) => {
      state.uiSoundsCanPlay = true
    },
    setControlBarCurrentView: (state, action: PayloadAction<ControlBarView>) => {
      state.controlBarCurrentView = action.payload
    },
    updateLocalUserState: (state, action: PayloadAction<LocalUserState>) => {
      state.user = action.payload
    },
    clearLocalUserState: (state) => {
      state.user = undefined
    },
  },
})


export const { turnOffUiSounds, turnOnUiSounds, setControlBarCurrentView, updateLocalUserState, clearLocalUserState } = localSlice.actions

// Other code such as selectors can use the imported `RootState` type
export const selectUiSoundsCanPlay = (state: RootState) => state.local.uiSoundsCanPlay
export const selectControlBarCurrentView = (state: RootState) => state.local.controlBarCurrentView

export default localSlice.reducer

