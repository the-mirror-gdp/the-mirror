"use client"
import { useEffect } from 'react';

import { Button } from '@/components/ui/button';
import { PlusCircleIcon } from 'lucide-react';

import { useAppSelector } from '@/hooks/hooks';
import { useCreateEntityMutation, useGetAllEntitiesQuery, useUpdateEntityMutation } from '@/state/entities';
import { getCurrentScene } from '@/state/local';
import { useGetAllScenesQuery } from '@/state/scenes';
import { useGetSingleSpaceQuery } from '@/state/spaces';
import { skipToken } from '@reduxjs/toolkit/query';
import { useParams } from 'next/navigation';

export default function EntityHierarchy() {
  const currentScene = useAppSelector(getCurrentScene)
  const params = useParams<{ spaceId: string }>()
  // const { data: spaceBuildModeData, error } = useGetSingleSpaceBuildModeQuery(params.spaceId)
  const { data: space } = useGetSingleSpaceQuery(params.spaceId)
  const { data: scenes, isLoading: isScenesLoading } = useGetAllScenesQuery(params.spaceId)
  const { data: entities, isFetching: isEntitiesFetching } = useGetAllEntitiesQuery(
    scenes && scenes.length > 0 ? scenes.map(scene => scene.id) : skipToken  // Conditional query
  );

  const [updateEntity] = useUpdateEntityMutation();
  const [createEntity, { data: createdEntity }] = useCreateEntityMutation();

  // useEffect(() => {
  //   debugger
  //   if (currentScene) {
  //     getSingleSpace(currentScene);
  //   }
  // }, [currentScene]);
  useEffect(() => {
    if (entities && entities.length > 0) {

      // updateState({ entities, type: 'set-tree', itemId: '' });
    }
  }, [entities]);  // Re-run effect when 'entities' changes


  return (
    <div>
      {/* Create Scene Button */}
      <Button className="w-full my-4" type="button" onClick={() => createEntity({ name: "New Entity", scene_id: currentScene })}>
        <PlusCircleIcon className="mr-2" />
        Create Entity
      </Button>
      <>

      </>
    </div >
  );
}
