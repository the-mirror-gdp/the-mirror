"use client"
import SpaceViewport from "@/state/engine/space-viewport";
import { modifyFile } from "@/utils/pc-import.server";
import Script from "next/script";
import * as pcImport from 'playcanvas';
import { useEffect, useState } from "react";

export default function PageTemp() {
  const [isScriptReady, setIsScriptReady] = useState(false);

  useEffect(() => {
    const modifyAndLoadScripts = async () => {
      try {
        // First, modify the file on the server side
        await modifyFile(); // Wait for the modification to complete

        // Once the file is modified, allow the scripts to load
        setIsScriptReady(true);
        console.log('file is ready')
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
          <Script src="/sample/__settings__.import.js" strategy="lazyOnload" />
          <Script src="/sample/__modules__.import.js" strategy="lazyOnload" />
          {/* This is OUR start file, not the imported one (for engine compatability reasons; we use the latest and someone might import an older file) */}
          <Script src="/sample/__our-start__.js" strategy="lazyOnload" />
          <style id="import-style"></style>
        </>
      )}
      <SpaceViewport />
    </>
  );
}
