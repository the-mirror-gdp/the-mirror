"use client"

import { useGetAllEntitiesQuery } from "@/state/entities";
import { useGetAllScenesQuery } from "@/state/scenes";

import { useParams } from "next/navigation";

export default function SpaceViewport() {
  // // get all entities for the scene. may move this to a loader in the future
  const params = useParams<{ spaceId: string }>()
  // const { data: scenes } = useGetAllScenesQuery(params.spaceId);
  // const { data: entities } = useGetAllEntitiesQuery(params.spaceId);


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
