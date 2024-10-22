'use client'
import { getApp } from '@/components/engine/__start-custom__'
import * as pc from 'playcanvas'
import { Observer } from '@playcanvas/observer'

// Note: using JS for PC Script files for now since TypeScript & ES6 support seems underdocumented

export function createEntityPickerScript() {
  const app = getApp()

  const BuidModeEntityPicker = pc.createScript('buildModeEntityPicker', app)

  // // create gizmo
  // const layer = pc.Gizmo.createLayer(app);
  // const gizmo = new pc.TranslateGizmo(camera.camera, layer);
  // // gizmo.attach(box);
  // const data = new Observer({})
  // data.set('gizmo', {
  //   size: gizmo.size,
  //   snapIncrement: gizmo.snapIncrement,
  //   xAxisColor: Object.values(gizmo.xAxisColor),
  //   yAxisColor: Object.values(gizmo.yAxisColor),
  //   zAxisColor: Object.values(gizmo.zAxisColor),
  //   colorAlpha: gizmo.colorAlpha,
  //   shading: gizmo.shading,
  //   coordSpace: gizmo.coordSpace,
  //   axisLineTolerance: gizmo.axisLineTolerance,
  //   axisCenterTolerance: gizmo.axisCenterTolerance,
  //   axisGap: gizmo.axisGap,
  //   axisLineThickness: gizmo.axisLineThickness,
  //   axisLineLength: gizmo.axisLineLength,
  //   axisArrowThickness: gizmo.axisArrowThickness,
  //   axisArrowLength: gizmo.axisArrowLength,
  //   axisPlaneSize: gizmo.axisPlaneSize,
  //   axisPlaneGap: gizmo.axisPlaneGap,
  //   axisCenterSize: gizmo.axisCenterSize
  // });

  // // controls hook
  // const tmpC = new pc.Color();
  // data.on('*:set', (/** @type {string} */ path, /** @type {any} */ value) => {
  //   const [category, key] = path.split('.');
  //   switch (category) {
  //     case 'camera':
  //       switch (key) {
  //         case 'proj':
  //           camera.camera.projection = value - 1;
  //           break;
  //         case 'fov':
  //           camera.camera.fov = value;
  //           break;
  //       }
  //       return;
  //     case 'gizmo':

  //       if (gizmo[key] instanceof pc.Color) {
  //         gizmo[key] = tmpC.set(...value);
  //         return;
  //       }

  //       gizmo[key] = value;
  //   }
  // });

  return BuidModeEntityPicker
}
