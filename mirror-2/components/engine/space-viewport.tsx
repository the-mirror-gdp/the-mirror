'use client';

import { cn } from "@/utils/cn";
import Script from "next/script";
import * as pc from 'playcanvas';
import { useEffect, useRef, useState } from "react";
import { createSupabaseBrowserClient } from '@/utils/supabase/client';
import { useAppSelector } from "@/hooks/hooks";
import { selectLocalUser } from "@/state/local";
import { useGetSinglePcImportQuery } from "@/state/pc-imports";
import { getBrowserScriptTagUrlForLoadingScriptsFromStorage, getSCRIPT_PREFIXForLoadingEngineApp } from "@/utils/pc-import";


interface SpaceViewportProps {
  pcImportId: string;
  mode?: 'build' | 'play'; // Optional mode prop with default value 'play'
}

export default function SpaceViewport({ pcImportId, mode = 'play' }: SpaceViewportProps) {
  const [isScriptReady, setIsScriptReady] = useState(false);
  const [engineLoaded, setEngineLoaded] = useState(false);
  const [settingsScriptUrl, setSettingsScriptUrl] = useState('');
  const [modulesScriptUrl, setModulesScriptUrl] = useState('');
  const [importedConfigJsonUrl, setImportedConfigJsonUrl] = useState('');
  const [hasLoadedExternalFiles, setHasLoadedExternalFiles] = useState(false);
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const user = useAppSelector(selectLocalUser);

  const startScriptPath = `/scripts/__start-custom__.js`;
  const supabase = createSupabaseBrowserClient();

  // Use RTK Query to fetch the list of filenames related to the pcImportId
  const { data: pcImport, error: pcImportError } = useGetSinglePcImportQuery(pcImportId);

  useEffect(() => {
    const loadScripts = async () => {

      if (pcImport && !pcImportError && user) {
        try {

          // const urls = await constructAndDownloadUrls(pcImportFiles);
          const pcImportPath = `${user?.id}/${pcImportId}`

          // Fetch the list of files from Supabase Storage
          // const { data: fileList, error: listError } = await supabase.storage
          //   .from('pc-imports')
          //   .list(pcImportPath);
          //        // if (listError) {
          // //   throw new Error(`Error listing files: ${listError.message}`);
          // // }

          // get __settings__.js
          const { data: settingsFile } = supabase
            .storage
            .from('pc-imports')
            .getPublicUrl(pcImportPath + '/__settings__.js')
          setSettingsScriptUrl(settingsFile.publicUrl)

          const { data: modulesFile } = supabase
            .storage
            .from('pc-imports')
            .getPublicUrl(pcImportPath + '/__modules__.js')
          setModulesScriptUrl(modulesFile.publicUrl)

          const { data: configFile } = supabase
            .storage
            .from('pc-imports')
            .getPublicUrl(pcImportPath + '/config.json')
          setImportedConfigJsonUrl(configFile.publicUrl)

          setIsScriptReady(true);
          setHasLoadedExternalFiles(true);

          // // Ensure this runs only on the client-side
          if (typeof window !== "undefined") {
            window['pc'] = pc; // Declare global PlayCanvas variable
            // window['CONFIG_FILENAME'] = `${configFile.publicUrl}`
            debugger
          }

        } catch (error) {
          console.error("Error loading external files:", error);
        }
      }
    };

    if (user?.id && pcImportId && !hasLoadedExternalFiles && pcImport) {
      loadScripts();
    }
  }, [user, pcImportId, pcImport, pcImportError]);

  return (
    <>
      {isScriptReady && settingsScriptUrl && modulesScriptUrl && (
        <>

          {/* Load all the dynamic scripts from the project folder */}
          <Script src={settingsScriptUrl} strategy="afterInteractive" />
          <Script src={modulesScriptUrl} strategy="afterInteractive" />
          {/* This is OUR start file, not the imported one (for engine compatibility reasons) */}
          <Script id="config-json-script" strategy="beforeInteractive">
            {`
            // Ensure this runs only on the client-side
          if (typeof window !== "undefined") {
            window['CONFIG_FILENAME'] = \`${importedConfigJsonUrl}\`
            console.log('set config', window['CONFIG_FILENAME'])
          }
            `}
          </Script>
          <Script src={startScriptPath} strategy="lazyOnload" onLoad={() => setEngineLoaded(true)} />
          <style id="import-style"></style>
        </>
      )}
      <div id="direct-container">
        <canvas
          id="application-canvas"
          ref={canvasRef}
          style={{ zIndex: -1 }}
          className={cn("flex h-full w-full items-center justify-center shadow-sm transition-all duration-1000")}
        />
      </div>
    </>
  );
}

