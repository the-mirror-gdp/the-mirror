import { RootState } from '@/state/store'
import type { PayloadAction } from '@reduxjs/toolkit'
import { createSlice } from '@reduxjs/toolkit'

export type ControlBarView = "assets" | "scenes" | "code" | "database" | "versions" | "settings"
interface CounterState {
  value: number,
  uiSoundsCanPlay: boolean
  controlBarCurrentView: ControlBarView
}

// Define the initial state using that type
const initialState: CounterState = {
  value: 0,
  uiSoundsCanPlay: true,
  controlBarCurrentView: "assets"
}

export const counterSlice = createSlice({
  name: 'counter',
  // `createSlice` will infer the state type from the `initialState` argument
  initialState,
  reducers: {
    increment: (state) => {
      state.value += 1
    },
    decrement: (state) => {
      state.value -= 1
    },
    // Use the PayloadAction type to declare the contents of `action.payload`
    incrementByAmount: (state, action: PayloadAction<number>) => {
      state.value += action.payload
    },
    turnOffUiSounds: (state) => {
      state.uiSoundsCanPlay = false
    },
    turnOnUiSounds: (state) => {
      state.uiSoundsCanPlay = true
    },
    setControlBarCurrentView: (state, action: PayloadAction<ControlBarView>) => {
      state.controlBarCurrentView = action.payload
    }
  },
})

export const { increment, decrement, incrementByAmount, turnOffUiSounds, turnOnUiSounds, setControlBarCurrentView } = counterSlice.actions

// Other code such as selectors can use the imported `RootState` type
export const selectUiSoundsCanPlay = (state: RootState) => state.counter.uiSoundsCanPlay
export const selectControlBarCurrentView = (state: RootState) => state.counter.controlBarCurrentView

export default counterSlice.reducer
