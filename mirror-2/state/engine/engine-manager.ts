import * as pc from 'playcanvas'

// Singleton PlayCanvas instance manager
let playCanvasApp: pc.Application | null = null

export function getApp(): pc.Application | null {
  return playCanvasApp
}

export function setApp(app: pc.Application) {
  playCanvasApp = app
}
