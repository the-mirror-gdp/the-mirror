"use client"

import { useEffect, useRef } from "react";
import { useParams } from "next/navigation";
import * as pc from 'playcanvas'
import { setApp } from "@/state/engine/engine";


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
      setApp(app)
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
