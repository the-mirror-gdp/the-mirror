"use client"

import { useEffect, useRef } from "react";
import { useParams } from "next/navigation";
import * as pc from 'playcanvas'
import { setApp } from "@/state/engine/engine";

export default function SpaceViewport() {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (canvas) {
      const app = new pc.Application(canvas, {
        mouse: new pc.Mouse(canvas),
        touch: new pc.TouchDevice(canvas),
      });
      // setApp(app) // TODO re-add when ready; it's bugging things currently
      app.start();

      // Function to resize canvas based on its parent container
      const resizeCanvas = () => {
        const parent = canvas.parentElement;
        if (parent) {
          canvas.width = parent.clientWidth;
          canvas.height = parent.clientHeight;
          app.resizeCanvas(canvas.width, canvas.height);
        }
      };
      app.setCanvasFillMode('NONE')
      resizeCanvas();

      // Create a spinning box
      const box = new pc.Entity('box');
      box.addComponent('render', {
        type: 'box'
      });
      app.root.addChild(box);

      // Add a camera
      const camera = new pc.Entity('camera');
      camera.addComponent('camera', {
        clearColor: new pc.Color(0.1, 0.1, 0.1)
      });
      camera.translate(0, 0, 3);
      app.root.addChild(camera);

      // Add a directional light
      const light = new pc.Entity('light');
      light.addComponent('light');
      light.setEulerAngles(45, 0, 0);
      app.root.addChild(light);

      // Update function to rotate the box
      app.on('update', (dt) => {
        box.rotate(10 * dt, 20 * dt, 30 * dt);
      });

      window.addEventListener('resize', resizeCanvas);

      return () => {
        window.removeEventListener('resize', resizeCanvas);
        app.destroy();
      };
    }
  }, []);

  return (
    <div style={{ width: '100%', height: '100%' }} >
      <canvas
        ref={canvasRef}
        className="flex h-full w-full items-center justify-center shadow-sm"
      />
    </div>
  );
}
