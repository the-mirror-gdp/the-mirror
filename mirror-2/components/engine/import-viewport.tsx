"use client"
import { cn } from "@/utils/cn";
import { modifyFile } from "@/utils/pc-import.server";
import Script from "next/script";
import * as pcImport from 'playcanvas';
import { useEffect, useRef, useState } from "react";

/**
 * Note: it may seem odd to use a <Script/> tag for importing out own __start-build__.js file, but the intent is for this to also be a forcing function to maintain compatability with imported PlayCanvas projects, so it's cleaner for the "pathway" to be the same/as close as possible.
 * The main difference between the -play and -build scripts is that the build mode script adjusts the canvas size to fit within the editor.
 */

export default function ImportViewportAndWillBeV2({ mode = 'play' }: { mode?: 'build' | 'play' }) {
  const [isScriptReady, setIsScriptReady] = useState(false);
  const [settingsLoaded, setSettingsLoaded] = useState(false);
  const [modulesLoaded, setModulesLoaded] = useState(false);
  const [engineLoaded, setEngineLoaded] = useState(false);
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const startScriptUrl = mode === 'play' ? "/sample/__start-play__.js" : "/sample/__start-build__.js"
  useEffect(() => {
    const modifyAndLoadScripts = async () => {
      try {
        // First, modify the file on the server side
        await modifyFile(); // Wait for the modification to complete

        // Once the file is modified, allow the scripts to load
        setIsScriptReady(true);

        // Ensure this runs only on the client-side
        if (typeof window !== "undefined") {
          window['pc'] = pcImport;  // Declare global PlayCanvas variable
        }
      } catch (error) {
        console.error("Error modifying the file:", error);
      }
    };

    modifyAndLoadScripts();
  }, []);

  return (
    <>
      {isScriptReady && (
        <>
          <Script src="/sample/__settings__.import.js" strategy="afterInteractive" onLoad={() => setSettingsLoaded(true)} />
          <Script src="/sample/__modules__.import.js" strategy="afterInteractive" onLoad={() => setModulesLoaded(true)} />
          {/* This is OUR start file, not the imported one (for engine compatability reasons; we use the latest and someone might import an older file) */}
          {settingsLoaded && modulesLoaded && <Script src={startScriptUrl} strategy="lazyOnload" onLoad={() => setEngineLoaded(true)} />}
          <style id="import-style"></style>
        </>
      )}
      <div id="direct-container" >
        {/* Leaving here for posterity temporarily. With the build loading scripts, it's appended directly to the direct-container via vanilla JS via ID. */}
        {/* <canvas
          id="application-canvas"
          ref={canvasRef}
          style={{ zIndex: -1 }}
          className={cn("flex h-full w-full items-center justify-center shadow-sm transition-all duration-1000")}
        /> */}
      </div>
    </>
  );
}
