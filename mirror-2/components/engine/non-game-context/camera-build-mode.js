'use client'
import { getApp } from '@/components/engine/__start-custom__'
import * as pc from 'playcanvas'
import { Observer } from '@playcanvas/observer'

// Note: using JS for PC Script files for now since TypeScript & ES6 support seems underdocumented. Will migrate to ES6 classes in the future.

export const createBuildModeCameraScript = () => {
  const app = getApp()

  const BuildModeCamera = pc.createScript('buildModeCamera', app)

  BuildModeCamera.attributes.add('speed', {
    type: 'number',
    default: 10
  })

  BuildModeCamera.attributes.add('fastSpeed', {
    type: 'number',
    default: 20
  })

  BuildModeCamera.attributes.add('mode', {
    type: 'number',
    default: 0,
    enum: [
      {
        Lock: 0
      },
      {
        Drag: 1
      }
    ]
  })

  BuildModeCamera.prototype.initialize = function () {
    // Camera euler angle rotation around x and y axes
    var eulers = this.entity.getLocalEulerAngles()
    this.ex = eulers.x
    this.ey = eulers.y
    this.moved = false
    this.rmbDown = false

    // Disabling the context menu stops the browser displaying a menu when
    // you right-click the page
    this.app.mouse.disableContextMenu()
    this.app.mouse.on(pc.EVENT_MOUSEMOVE, this.onMouseMove, this)
    this.app.mouse.on(pc.EVENT_MOUSEDOWN, this.onMouseDown, this)
    this.app.mouse.on(pc.EVENT_MOUSEUP, this.onMouseUp, this);


    // TEMP same script


  }

  BuildModeCamera.prototype.update = function (dt) {
    // Update the camera's orientation
    this.entity.setLocalEulerAngles(this.ex, this.ey, 0)

    var app = this.app

    var speed = this.speed
    if (app.keyboard.isPressed(pc.KEY_SHIFT)) {
      speed = this.fastSpeed
    }

    // Update the camera's position
    if (app.keyboard.isPressed(pc.KEY_UP) || app.keyboard.isPressed(pc.KEY_W)) {
      this.entity.translateLocal(0, 0, -speed * dt)
    } else if (
      app.keyboard.isPressed(pc.KEY_DOWN) ||
      app.keyboard.isPressed(pc.KEY_S)
    ) {
      this.entity.translateLocal(0, 0, speed * dt)
    }

    if (
      app.keyboard.isPressed(pc.KEY_LEFT) ||
      app.keyboard.isPressed(pc.KEY_A)
    ) {
      this.entity.translateLocal(-speed * dt, 0, 0)
    } else if (
      app.keyboard.isPressed(pc.KEY_RIGHT) ||
      app.keyboard.isPressed(pc.KEY_D)
    ) {
      this.entity.translateLocal(speed * dt, 0, 0)
    }
  }

  BuildModeCamera.prototype.onMouseMove = function (event) {
    if (!this.mode) {
      if (!pc.Mouse.isPointerLocked()) {
        return
      }
    } else {
      if (!this.rmbDown) {
        return
      }
    }

    // Update the current Euler angles, clamp the pitch.
    if (!this.moved) {
      // first move event can be very large
      this.moved = true
      return
    }
    this.ex -= event.dy / 5
    this.ex = pc.math.clamp(this.ex, -90, 90)
    this.ey -= event.dx / 5
  }

  BuildModeCamera.prototype.onMouseDown = function (event) {
    if (event.button === pc.MOUSEBUTTON_RIGHT) {
      this.rmbDown = true

      // When the mouse button is clicked try and capture the pointer
      if (!this.mode && !pc.Mouse.isPointerLocked()) {
        this.app.mouse.enablePointerLock()
      }
    }
  }

  BuildModeCamera.prototype.onMouseUp = function (event) {
    if (event.button === 0) {
      this.rmbDown = false
    }
    if (pc.Mouse.isPointerLocked()) {
      this.app.mouse.disablePointerLock()
    }
  }



  return BuildModeCamera
}
