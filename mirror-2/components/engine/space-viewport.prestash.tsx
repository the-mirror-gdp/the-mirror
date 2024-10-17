'use client'

import { useAppSelector } from '@/hooks/hooks'
import { selectCurrentScene, selectLocalUser } from '@/state/local.slice'
import { createSupabaseBrowserClient } from '@/utils/supabase/client'
import { useEffect, useRef, useState } from 'react'
import initEngine, { CANVAS_ID, getApp } from './__start-custom__'

import { useGetSingleSpaceQuery } from '@/state/api/spaces'
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert'
import { Terminal } from 'lucide-react'
import { Spinner } from '@/components/ui/spinner'
import { skipToken } from '@reduxjs/toolkit/query/react' // Important for conditional queries
import { setUpSpace } from '@/components/engine/space-engine.utils'
import { useGetAllEntitiesQuery } from '@/state/api/entities'

interface SpaceViewportProps {
  spaceId?: number
  spacePackId?: number
  mode?: 'build' | 'play'
}

export default function SpaceViewport({
  spaceId,
  spacePackId,
  mode
}: SpaceViewportProps) {
  // checks
  if (!mode) {
    throw new Error('Attempted to load Space without specifying a mode')
  }
  if (mode === 'build' && !spaceId) {
    return (
      <Alert className="transition-opacity duration-1000">
        <Terminal className="h-4 w-4" />
        <AlertTitle>Missing Space ID</AlertTitle>
        <AlertDescription>Space ID is required in build mode.</AlertDescription>
      </Alert>
    )
  }
  if (mode === 'play' && !spacePackId) {
    return (
      <Alert className="transition-opacity duration-1000">
        <Terminal className="h-4 w-4" />
        <AlertTitle>Missing Space Pack ID</AlertTitle>
        <AlertDescription>
          Space Pack ID is required in play mode.
        </AlertDescription>
      </Alert>
    )
  }

  const [engineLoaded, setEngineLoaded] = useState(false)
  const [appWasDestroyed, setAppWasDestroyed] = useState(false)
  const canvasRef = useRef<HTMLCanvasElement | null>(null)
  const user = useAppSelector(selectLocalUser)
  const [hasSetUpEntities, setHasSetUpEntities] = useState(false)
  const appRef = useRef<pc.AppBase | undefined>(undefined)

  // Conditionally fetch space data only if spaceId is defined
  const {
    data: space,
    error: spaceError,
    isSuccess: isSuccessGetSingleSpace,
    isLoading,
    isUninitialized,
    isError
  } = useGetSingleSpaceQuery(spaceId || skipToken)
  const currentScene = useAppSelector(selectCurrentScene)
  const {
    data: entities,
    isSuccess: isSuccessGettingEntities,
    error
  } = useGetAllEntitiesQuery(currentScene?.id || skipToken)

  // main engine init method
  useEffect(() => {
    console.log('space:', space)
    console.log('engineLoaded:', engineLoaded)
    console.log('appRef.current:', appRef.current)
    console.log('typeof window !== "undefined":', typeof window !== 'undefined')
    if (
      space &&
      !engineLoaded &&
      !appRef.current &&
      typeof window !== 'undefined'
    ) {
      const app = initEngine()
      appRef.current = app
      setEngineLoaded(true)
    }
    return () => {
      if (
        // existingApp &&
        engineLoaded &&
        typeof window !== 'undefined' &&
        // existingApp.destroy
        appRef.current
      ) {
        console.log('Destroying existing PlayCanvas app', appRef.current)
        appRef.current.destroy()
        appRef.current = undefined
        setEngineLoaded(false)
      }
    }
  }, [space, engineLoaded])

  useEffect(() => {
    if (appWasDestroyed) {
      setEngineLoaded(false)
      setAppWasDestroyed(false)
    }
  }, [appWasDestroyed])

  // devtools only for helping with hot reloads
  useEffect(() => {
    if (process.env.NODE_ENV === 'development') {
      const canvas = document.getElementById(CANVAS_ID)
      if (canvas) {
        console.log('listening webgl context')
        canvas.addEventListener('webglcontextlost', (event) => {
          event.preventDefault()
          console.warn('WebGL context lost')
          // Handle context loss, possibly by reinitializing the app
        })
      }
    }
  }, [engineLoaded])

  console.log('TEMP space:', space)

  useEffect(() => {
    if (
      isSuccessGetSingleSpace &&
      space &&
      currentScene &&
      isSuccessGettingEntities &&
      entities &&
      engineLoaded &&
      !hasSetUpEntities
    ) {
      setUpSpace(currentScene.id, entities)
      // ensure only happens once
      setHasSetUpEntities(true)
    }
  }, [
    isSuccessGetSingleSpace,
    space,
    currentScene,
    isSuccessGettingEntities,
    entities,
    hasSetUpEntities
  ])

  return (
    <>
      {space && (
        <>
          <style id="import-style"></style>
          <div id="direct-container" style={{ zIndex: -1 }}></div>
        </>
      )}
      {!space && (
        <div className="flex justify-center my-5">
          {(isLoading || isUninitialized) && <Spinner className="w-12 h-12" />}
          {isError && (
            <Alert className="transition-opacity duration-1000">
              <Terminal className="h-4 w-4" />
              <AlertTitle>Issue Loading Space</AlertTitle>
              <AlertDescription>
                We're sorry, there was an issue loading the Space.
              </AlertDescription>
            </Alert>
          )}
        </div>
      )}
    </>
  )
}
