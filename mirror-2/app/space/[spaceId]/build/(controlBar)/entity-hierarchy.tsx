"use client"

import { Button } from '@/components/ui/button';
import { PlusCircleIcon } from 'lucide-react';

import EntityTree from '@/components/entity-tree/entity-tree';
import { useAppSelector } from '@/hooks/hooks';
import { useCreateEntityMutation } from '@/state/entities';
import { getCurrentScene } from '@/state/local';
import { useParams } from 'next/navigation';

export default function EntityHierarchy() {
  const currentScene = useAppSelector(getCurrentScene)
  const params = useParams<{ spaceId: string }>()
  const [createEntity, { data: createdEntity }] = useCreateEntityMutation();

  return (
    <div>
      <h2>{currentScene && <>Scene: {currentScene.name}</>}</h2>
      {/* Create Etntity Button */}
      {currentScene && <Button className="w-full my-4" type="button" onClick={() => createEntity({ name: "New Entity", scene_id: currentScene.id })}>
        <PlusCircleIcon className="mr-2" />
        Create Entity
      </Button>}
      <>
        <EntityTree />
      </>
    </div >
  );
}
