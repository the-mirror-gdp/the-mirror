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
  if (mode === 'build') {
    if (!spaceId) {
      throw new Error('Attempted to load Build Mode Space without spaceId')
    }
  }
  if (mode === 'play') {
    if (!spacePackId) {
      throw new Error('Attempted to load Build Mode Space without spacePackId')
    }
  }

  const [engineLoaded, setEngineLoaded] = useState(false)
  const canvasRef = useRef<HTMLCanvasElement | null>(null)
  const user = useAppSelector(selectLocalUser)
  // get Space
  const {
    data: space,
    error: spaceError,
    isSuccess,
    isLoading,
    isUninitialized,
    isError
  } = useGetSingleSpaceQuery(3)
  const supabase = createSupabaseBrowserClient()

  useEffect(() => {
    // // Ensure this runs only on the client-side
    // if (typeof window !== 'undefined' && !window['pc']) {
    //   window['pc'] = pc // Declare global PlayCanvas variable
    // }
    // TODO remove this once bugs fixed
    setTimeout(() => {
      if (isSuccess) {
        initEngine()
        setEngineLoaded(true)
      }
    }, 1250)
  }, [])

  return (
    <>
      {isSuccess && (
        <>
          <style id="import-style"></style>
          <div
            id="direct-container"
            style={{ zIndex: -1 }}
            // className={cn(
            //   'flex h-full w-full items-center justify-center shadow-sm transition-all duration-1000'
            // )}
          ></div>
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
