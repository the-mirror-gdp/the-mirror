"use client"

import { useAppDispatch } from "@/hooks/hooks"
import { setCurrentScene } from "@/state/local"
import { useGetAllScenesQuery } from "@/state/scenes"
import { useGetSingleSpaceQuery } from "@/state/spaces"

import { useParams } from "next/navigation"
import { useEffect } from "react"


// blank page since we're using the parallel routes for spaceViewport, controlBar, etc.
export default function Page() {
  const params = useParams<{ spaceId: string }>()
  const { data: space, error } = useGetSingleSpaceQuery(params.spaceId)
  const { data: scenes, isLoading: isScenesLoading } = useGetAllScenesQuery(params.spaceId)
  // after successful query, update the current scene to the first in the space.scenes array
  const dispatch = useAppDispatch();
  useEffect(() => {
    // if no current Scene, set it to the first scene
    if (scenes?.length > 0 && scenes[0]) {
      console.log("setting current scene to first scene", scenes[0])
      dispatch(setCurrentScene(scenes[0]))
    }
  }, [space])

  return null
}
