'use client'
import { getApp } from '@/components/engine/__start-custom__'
import * as pc from 'playcanvas'
import { Observer } from '@playcanvas/observer'

// Note: using JS for PC Script files for now since TypeScript & ES6 support seems underdocumented

export function createEntityPickerScript() {
  const app = getApp()

  const EntitySelect = pc.createScript('EntitySelect', app)

  // initialize code called once per entity
  EntitySelect.prototype.initialize = function () {
    // Setup the different positions to move to
    this.firstPosition = new pc.Vec3(-1, 1.25, 6.5);
    this.secondPosition = new pc.Vec3(1, 1.25, 6.5);

    // Add a mousedown event handler
    this.app.mouse.on(pc.EVENT_MOUSEDOWN, this.mouseDown, this);

    // Add touch event only if touch is available
    if (this.app.touch) {
      this.app.touch.on(pc.EVENT_TOUCHSTART, this.touchStart, this);
    }

    this.on('destroy', function () {
      this.app.mouse.off(pc.EVENT_MOUSEDOWN, this.mouseDown, this);

      // Add touch event only if touch is available
      if (this.app.touch) {
        this.app.touch.off(pc.EVENT_TOUCHSTART, this.touchStart, this);
      }
    }, this);
  };

  EntitySelect.prototype.mouseDown = function (e) {
    this.doRaycast(e);
  };

  EntitySelect.prototype.touchStart = function (e) {
    // Only perform the raycast if there is one finger on the screen
    if (e.touches.length == 1) {
      this.doRaycast(e.touches[0]);
    }
    e.event.preventDefault();
  };

  EntitySelect.prototype.doRaycast = function (screenPosition) {
    // The pc.Vec3 to raycast from
    var from = this.entity.getPosition();
    // The pc.Vec3 to raycast to 
    var to = this.entity.camera.screenToWorld(screenPosition.x, screenPosition.y, this.entity.camera.farClip);

    // Raycast between the two points
    var result = this.app.systems.rigidbody.raycastFirst(from, to);

    // If there was a hit, store the entity
    if (result) {
      var hitEntity = result.entity;
      // Set the target position of the lerp script based on the name of the clicked box
      if (hitEntity.name == '1')
        this.entity.script.lerp.targetPosition = this.firstPosition;
      else if (hitEntity.name == '2')
        this.entity.script.lerp.targetPosition = this.secondPosition;
    }
  };


  return EntitySelect
}
