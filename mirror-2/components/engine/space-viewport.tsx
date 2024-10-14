'use client'

import { useAppSelector } from '@/hooks/hooks'
import { selectLocalUser } from '@/state/local.slice'
import { createSupabaseBrowserClient } from '@/utils/supabase/client'
import { useEffect, useRef, useState } from 'react'
import initEngine from './__start-custom__'

import { useGetSingleSpaceQuery } from '@/state/api/spaces'

interface SpaceViewportProps {
  spaceId: number
  mode?: 'build' | 'play' // Optional mode prop with default value 'play'
}

export default function SpaceViewport({
  spaceId,
  mode = 'play'
}: SpaceViewportProps) {
  const [engineLoaded, setEngineLoaded] = useState(false)
  const canvasRef = useRef<HTMLCanvasElement | null>(null)
  const user = useAppSelector(selectLocalUser)

  const supabase = createSupabaseBrowserClient()

  useEffect(() => {
    // // Ensure this runs only on the client-side
    // if (typeof window !== 'undefined' && !window['pc']) {
    //   window['pc'] = pc // Declare global PlayCanvas variable
    // }
    setTimeout(() => {
      initEngine()
      setEngineLoaded(true)
    }, 1250)
  }, [])

  // get Space
  const { data: space, error: spaceError } = useGetSingleSpaceQuery(spaceId)

  return (
    <>
      {' '}
      <style id="import-style"></style>
      <div
        id="direct-container"
        style={{ zIndex: -1 }}
        // className={cn(
        //   'flex h-full w-full items-center justify-center shadow-sm transition-all duration-1000'
        // )}
      ></div>
    </>
  )
}
