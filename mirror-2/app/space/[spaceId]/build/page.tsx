"use client"

import { useAppDispatch } from "@/hooks/hooks"
import { setCurrentScene } from "@/state/local"
import { useGetSingleSpaceBuildModeQuery } from "@/state/supabase"
import { useParams } from "next/navigation"
import { useEffect } from "react"


// blank page since we're using the parallel routes for spaceViewport, controlBar, etc.
export default function Page() {
  const params = useParams<{ spaceId: string }>()
  const { data: space, error } = useGetSingleSpaceBuildModeQuery(params.spaceId)

  // after successful query, update the current scene to the first in the space.scenes array
  const dispatch = useAppDispatch();
  useEffect(() => {
    // if no current Scene, set it to the first scene

    if (space?.scenes.length > 0) {
      console.log("setting current scene to first scene", space.scenes[0])
      dispatch(setCurrentScene(space.scenes[0].id))
    }
  }, [space])

  return null
}
