"use client"

import { useRef } from "react";

export default function SpaceViewport() {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  return (
    <div style={{ width: '100%', height: '100%' }} >
      <canvas
        ref={canvasRef}
        className="flex h-full w-full items-center justify-center shadow-sm"
      // id={CANVAS_ID}
      />
    </div>
  );
}
