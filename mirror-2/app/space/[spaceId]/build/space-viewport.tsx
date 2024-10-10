"use client"

import { useEffect, useRef } from "react";
import { useParams } from "next/navigation";
import * as pc from 'playcanvas'

export default function SpaceViewport() {
  const canvasRef = useRef<HTMLCanvasElement | null>(null); // Create a reference for the canvas

  useEffect(() => {
    // Initialize PlayCanvas application
    const canvas = canvasRef.current;
    if (canvas) {
      const app = new pc.Application(canvas, {
        mouse: new pc.Mouse(canvas),
        touch: new pc.TouchDevice(canvas),
      });

      app.start();

      // Function to resize canvas based on its parent container
      const resizeCanvas = () => {
        const parent = canvas.parentElement;
        if (parent) {
          canvas.width = parent.clientWidth; // Set width based on parent
          canvas.height = parent.clientHeight; // Set height based on parent
          app.resizeCanvas(canvas.width, canvas.height); // Resize PlayCanvas application
        }
      };

      // Initial resize based on the canvas's parent container size
      resizeCanvas();

      // Update the canvas size on window resize
      window.addEventListener('resize', resizeCanvas);

      // Create a camera
      const camera = new pc.Entity();
      camera.addComponent('camera', {
        clearColor: new pc.Color(0.5, 0.5, 0.5),
      });
      camera.setPosition(0, 1, 5); // Position the camera
      app.root.addChild(camera);

      // Create a light
      const light = new pc.Entity();
      light.addComponent('light');
      light.setEulerAngles(45, 0, 0); // Set the light angle
      app.root.addChild(light);

      // Create a mesh
      const box = new pc.Entity();
      box.addComponent('model', {
        type: 'box',
      });
      box.setLocalPosition(0, 1, 0); // Center the mesh
      app.root.addChild(box);

      // Update the application
      app.on("update", function (dt) {
        box.rotate(10 * dt, 20 * dt, 30 * dt); // Rotate the mesh
      });

      // Cleanup function to remove event listeners and destroy the app on unmount
      return () => {
        window.removeEventListener('resize', resizeCanvas); // Clean up event listener
        app.destroy(); // Destroy the PlayCanvas app
      };
    }
  }, []);

  return (
    <div style={{ width: '100%', height: '100%' }} >
      <canvas
        ref={canvasRef}
        className="flex h-full w-full items-center justify-center shadow-sm"
      // style={{ width: '100%', height: '100%' }} // Ensure canvas fills the parent
      />
    </div>
  );
}
