import { RootState } from '@/state/store'
import type { PayloadAction } from '@reduxjs/toolkit'
import { createSlice } from '@reduxjs/toolkit'

export type ControlBarView = "assets" | "hierarchy" | "scenes" | "code" | "database" | "versions" | "settings"

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
  controlBarCurrentView: "assets",
  user: {
    // this dummy state will be removed by the logic in auth.tsx, but we need initial data for SSR purposes
    email: "",
    id: "",
    is_anonymous: false
  }
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
      console.log('auth clearLocalUserState')
      state.user = undefined
    }
  },
})


export const { turnOffUiSounds, turnOnUiSounds, setControlBarCurrentView, updateLocalUserState, clearLocalUserState } = localSlice.actions

// Other code such as selectors can use the imported `RootState` type
export const selectUiSoundsCanPlay = (state: RootState) => state.local.uiSoundsCanPlay
export const selectControlBarCurrentView = (state: RootState) => state.local.controlBarCurrentView
export const selectLocalUserState = (state: RootState) => state.local.user

export default localSlice.reducer

