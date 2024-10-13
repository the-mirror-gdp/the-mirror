'use client'

import { cn } from '@/utils/cn'
import Script from 'next/script'
import * as pc from 'playcanvas'
import { useEffect, useRef, useState } from 'react'
import { createSupabaseBrowserClient } from '@/utils/supabase/client'
import { useAppSelector } from '@/hooks/hooks'
import { selectLocalUser } from '@/state/local'

import {
  getASSET_PREFIXForLoadingEngineApp,
  getBrowserScriptTagUrlForLoadingScriptsFromStorage,
  getSCRIPT_PREFIXForLoadingEngineApp,
  modifySettingsFileFromSupabase
} from '@/utils/space-pack'
import {
  SPACE_PACKS_BUCKET_NAME,
  useGetSingleSpacePackQuery
} from '@/state/space-packs'

interface SpaceViewportProps {
  spacePackId: number
  mode?: 'build' | 'play' // Optional mode prop with default value 'play'
}

export default function SpaceViewport({
  spacePackId: spacePackId,
  mode = 'play'
}: SpaceViewportProps) {
  const [isScriptReady, setIsScriptReady] = useState(false)
  const [engineLoaded, setEngineLoaded] = useState(false)
  const [settingsScriptUrl, setSettingsScriptUrl] = useState('')
  const [modifiedSettingsFileText, setModifiedSettingsFileText] = useState('')
  const [modulesScriptUrl, setModulesScriptUrl] = useState('')
  const [importedConfigJsonUrl, setImportedConfigJsonUrl] = useState('')
  const [hasLoadedExternalFiles, setHasLoadedExternalFiles] = useState(false)
  const canvasRef = useRef<HTMLCanvasElement | null>(null)
  const user = useAppSelector(selectLocalUser)

  const startScriptPath = `/scripts/__start-custom__.js`
  const supabase = createSupabaseBrowserClient()

  // Use RTK Query to fetch the list of filenames related to the spacePackId
  const { data: spacePack, error: spacePackImportError } =
    useGetSingleSpacePackQuery(spacePackId)

  useEffect(() => {
    const loadScripts = async () => {
      if (spacePack && !spacePackImportError && user) {
        try {
          const spacePackImportPath = `${user?.id}/${spacePack.id}`

          // get __settings__.js
          const { data: settingsFile } = supabase.storage
            .from(SPACE_PACKS_BUCKET_NAME)
            .getPublicUrl(spacePackImportPath + '/__settings__.js')
          setSettingsScriptUrl(settingsFile.publicUrl)

          const { data: configFile } = supabase.storage
            .from(SPACE_PACKS_BUCKET_NAME)
            .getPublicUrl(spacePackImportPath + '/config.json')
          setImportedConfigJsonUrl(configFile.publicUrl)

          const spacePackBaseUrl = settingsFile.publicUrl.replace(
            '/__settings__.js',
            '/'
          )

          const modifiedSettingsContent = await modifySettingsFileFromSupabase(
            settingsFile.publicUrl, // This is the URL you obtained from Supabase
            spacePackBaseUrl, // Your asset prefix
            spacePackBaseUrl,
            configFile.publicUrl
          )
          setModifiedSettingsFileText(modifiedSettingsContent)

          const { data: modulesFile } = supabase.storage
            .from(SPACE_PACKS_BUCKET_NAME)
            .getPublicUrl(spacePackImportPath + '/__modules__.js')
          setModulesScriptUrl(modulesFile.publicUrl)

          setIsScriptReady(true)
          setHasLoadedExternalFiles(true)

          // // Ensure this runs only on the client-side
          if (typeof window !== 'undefined') {
            window['pc'] = pc // Declare global PlayCanvas variable
          }
        } catch (error) {
          console.error('Error loading external files:', error)
        }
      } else {
        console.log('Did not retrieve spacePack yet')
      }
    }

    if (user?.id && spacePackId && !hasLoadedExternalFiles && spacePack) {
      loadScripts()
    }
  }, [user, spacePackId, spacePack, spacePackImportError])

  return (
    <>
      {isScriptReady && settingsScriptUrl && modulesScriptUrl && (
        <>
          {/* Load all the dynamic scripts from the project folder */}
          <Script id="modified-settings-script" strategy="afterInteractive">
            {modifiedSettingsFileText}
          </Script>
          <Script src={modulesScriptUrl} strategy="afterInteractive" />
          {/* This is OUR start file, not the imported one (for engine compatibility reasons) */}
          <Script
            src={startScriptPath}
            strategy="lazyOnload"
            onLoad={() => setEngineLoaded(true)}
          />
          <style id="import-style"></style>
        </>
      )}
      <div id="direct-container">
        <canvas
          id="application-canvas"
          ref={canvasRef}
          style={{ zIndex: -1 }}
          className={cn(
            'flex h-full w-full items-center justify-center shadow-sm transition-all duration-1000'
          )}
        />
      </div>
    </>
  )
}
