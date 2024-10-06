"use client"

import { useAppDispatch, useAppSelector } from "@/hooks/hooks";
import { getCurrentScene, setCurrentScene } from "@/state/local";
import { useGetAllEntitiesQuery, useGetAllScenesQuery } from "@/state/supabase";
import { useParams } from "next/navigation";
import { useEffect } from "react";

export default function SpaceViewport() {
  // get all entities for the scene. may move this to a loader in the future
  const params = useParams<{ spaceId: string }>()
  const { data: scenes } = useGetAllScenesQuery(params.spaceId);
  const { data: entities } = useGetAllEntitiesQuery(params.spaceId);
  const currentScene = useAppSelector(getCurrentScene)
  const dispatch = useAppDispatch();
  useEffect(() => {
    if (!currentScene) {
      // if no current Scene, set it to the first scene
      if (scenes && scenes.length > 0) {
        console.log("setting current scene to first scene", scenes[0])
        dispatch(setCurrentScene(scenes[0].id))
      }
    }
  }, [])

  return (
    <main className="h-full">
      <div
        className="flex h-full w-full items-center justify-center rounded-sm border border-dashed shadow-sm"
      >
        <h3 className="text-2xl font-bold">
          3D Viewport
        </h3>
      </div>
    </main>
  );
}
