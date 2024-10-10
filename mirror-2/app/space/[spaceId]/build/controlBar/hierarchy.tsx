"use client"

import { Button } from '@/components/ui/button';
import { PlusCircleIcon } from 'lucide-react';

import EntityTree from '@/components/entity-tree/entity-tree';
import { useAppSelector } from '@/hooks/hooks';
import { useCreateEntityMutation } from '@/state/entities';
import { getCurrentScene } from '@/state/local';
import { useParams } from 'next/navigation';
import { Separator } from '@/components/ui/separator';

export default function Hierarchy() {
  const currentScene = useAppSelector(getCurrentScene)
  const params = useParams<{ spaceId: string }>()
  const [createEntity, { data: createdEntity }] = useCreateEntityMutation();

  return (
    <>
      <h2 className='text-lg'>{currentScene && <>Scene: {currentScene.name}</>}</h2>
      <Separator className='mt-2 mb-1' />
      {/* Create Entity Button */}
      {currentScene && <Button className="w-full my-4" type="button" onClick={() => createEntity({ name: "New Entity", scene_id: currentScene.id })}>
        <PlusCircleIcon className="mr-2" />
        Create Entity
      </Button>}
      <>
        <EntityTree />
      </>
    </>
  );
}
