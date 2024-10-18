"use client"

import { useAppDispatch, useAppSelector } from "@/hooks/hooks"
import { selectCurrentScene, setCurrentSceneUseOnlyForId } from "@/state/local.slice"
import { useGetAllScenesQuery } from "@/state/api/scenes"
import { useGetSingleSpaceQuery } from "@/state/api/spaces"

import { useParams } from "next/navigation"
import { useEffect } from "react"
import dynamic from "next/dynamic"


// blank page since we're using the parallel routes for spaceViewport, controlBar, etc.
export default function Page() {
  const currentScene = useAppSelector(selectCurrentScene);
  const params = useParams<{ spaceId: string }>()
  const spaceId: number = parseInt(params.spaceId, 10) // Use parseInt for safer conversion

  const { data: space, error } = useGetSingleSpaceQuery(spaceId)
  const { data: scenes, isLoading: isScenesLoading } = useGetAllScenesQuery(spaceId)

  // after successful query, update the current scene to the first in the space.scenes array
  const dispatch = useAppDispatch();
  useEffect(() => {
    // if no current Scene, set it to the first scene
    if (scenes && scenes?.length > 0 && scenes[0]) {
      if (!currentScene?.id) {
        console.log("setting current scene to first scene", scenes[0])
        dispatch(setCurrentSceneUseOnlyForId(scenes[0]))
      }
    } else {
      console.log('No scenes to set', scenes, currentScene)
    }
  }, [space, scenes])

  return null
}
