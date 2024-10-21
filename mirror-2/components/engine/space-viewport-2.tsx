'use client'

import { useAppSelector } from '@/hooks/hooks'
import { selectCurrentScene, selectLocalUser } from '@/state/local.slice'
import { useContext, useEffect, useRef, useState } from 'react'

import { SpaceEngineNonGameContext } from '@/components/engine/non-game-context/space-engine-non-game-context'
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert'
import { Spinner } from '@/components/ui/spinner'
import { useGetSingleAssetQuery } from '@/state/api/assets'
import { skipToken } from '@reduxjs/toolkit/query/react' // Important for conditional queries
import { Terminal } from 'lucide-react'
import main from '/Users/jared/GitHub/the-mirror/mirror-2/splat-editor/src/index'

interface SplatEditorViewportProps {
  assetId?: number
}

export default function SplatEditorViewport({
  assetId
}: SplatEditorViewportProps) {
  // checks

  if (!assetId) {
    return (
      <Alert className="transition-opacity duration-1000">
        <Terminal className="h-4 w-4" />
        <AlertTitle>Missing Asset ID</AlertTitle>
        <AlertDescription>
          Asset ID is required to edit a splat.
        </AlertDescription>
      </Alert>
    )
  }

  const spaceEngineNonGameContext = useContext(SpaceEngineNonGameContext)
  const [engineLoaded, setEngineLoaded] = useState(false)
  const [appWasDestroyed, setAppWasDestroyed] = useState(false)
  const canvasRef = useRef<HTMLCanvasElement | null>(null)
  const user = useAppSelector(selectLocalUser)
  const [hasSetUpEntities, setHasSetUpEntities] = useState(false)
  const appRef = useRef<pc.AppBase | undefined>(undefined)

  // Conditionally fetch space data only if spaceId is defined
  const {
    data: asset,
    error: spaceError,
    isSuccess: isSuccessGetSingleSpace,
    isLoading,
    isUninitialized,
    isError
  } = useGetSingleAssetQuery(assetId || skipToken)
  const currentScene = useAppSelector(selectCurrentScene)

  // main engine init method
  useEffect(() => {
    if (
      asset &&
      !engineLoaded &&
      !appRef.current &&
      typeof window !== 'undefined'
    ) {
      // const app = initEngine()
      // appRef.current = app
      main()
      setEngineLoaded(true)
    }
    return () => {
      if (engineLoaded && typeof window !== 'undefined' && appRef.current) {
        console.log('Destroying existing PlayCanvas app', appRef.current)
        appRef.current.destroy()
        appRef.current = undefined
        setEngineLoaded(false)
      }
    }
  }, [asset, engineLoaded])

  useEffect(() => {
    if (appWasDestroyed) {
      setEngineLoaded(false)
      setAppWasDestroyed(false)
    }
  }, [appWasDestroyed])

  // useEffect(() => {
  //   if (
  //     isSuccessGetSingleSpace &&
  //     asset &&
  //     currentScene &&
  //     isSuccessGettingEntities &&
  //     entities &&
  //     engineLoaded &&
  //     !hasSetUpEntities
  //   ) {
  //     // setUpSpace(currentScene.id, entities)
  //     // ensure only happens once
  //     setHasSetUpEntities(true)
  //   }
  // }, [
  //   isSuccessGetSingleSpace,
  //   asset,
  //   currentScene,
  //   isSuccessGettingEntities,
  //   entities,
  //   hasSetUpEntities
  // ])

  return (
    <>
      {/* Temp, add back */}
      {/* {isSuccessGetSingleSpace && (
        <>
          <style id="import-style"></style>
          <div id="app-container" className="h-full"></div>
        </>
      )} */}
      {
        <>
          <style id="import-style"></style>
          <div id="app-container" className="h-full"></div>
        </>
      }
      {!isSuccessGetSingleSpace && (
        <div className="flex justify-center my-5">
          {(isLoading || isUninitialized) && <Spinner className="w-12 h-12" />}
          {/* TEMP: add back */}
          {/* {isError && (
            <Alert className="transition-opacity duration-1000">
              <Terminal className="h-4 w-4" />
              <AlertTitle>Issue Loading Asset</AlertTitle>
              <AlertDescription>
                We're sorry, there was an issue loading the Asset.
              </AlertDescription>
            </Alert>
          )} */}
        </div>
      )}
    </>
  )
}
