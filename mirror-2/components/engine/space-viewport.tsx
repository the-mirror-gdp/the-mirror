'use client'

import { useAppSelector } from '@/hooks/hooks'
import { selectLocalUser } from '@/state/local.slice'
import { createSupabaseBrowserClient } from '@/utils/supabase/client'
import { useEffect, useRef, useState } from 'react'
import initEngine from './__start-custom__'

import { useGetSingleSpaceQuery } from '@/state/api/spaces'
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert'
import { Terminal } from 'lucide-react'
import { Spinner } from '@/components/ui/spinner'
import { skipToken } from '@reduxjs/toolkit/query/react' // Important for conditional queries

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
  const canvasRef = useRef<HTMLCanvasElement | null>(null)
  const user = useAppSelector(selectLocalUser)

  // Conditionally fetch space data only if spaceId is defined
  const {
    data: space,
    error: spaceError,
    isSuccess,
    isLoading,
    isUninitialized,
    isError
  } = useGetSingleSpaceQuery(spaceId || skipToken)

  const supabase = createSupabaseBrowserClient()

  useEffect(() => {
    setTimeout(() => {
      if (isSuccess) {
        initEngine()
        setEngineLoaded(true)
      }
    }, 1250)
  }, [isSuccess])

  return (
    <>
      {isSuccess && (
        <>
          <style id="import-style"></style>
          <div id="direct-container" style={{ zIndex: -1 }}></div>
        </>
      )}
      {!isSuccess && (
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
