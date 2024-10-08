"use client"

import { Button } from '@/components/ui/button';
import { PlusCircleIcon } from 'lucide-react';

import EntityTree from '@/components/entity-tree/entity-tree';
import { useAppSelector } from '@/hooks/hooks';
import { useUpsertEntityMutation } from '@/state/entities';
import { getCurrentScene } from '@/state/local';
import { useParams } from 'next/navigation';

export default function EntityHierarchy() {
  const currentScene = useAppSelector(getCurrentScene)
  const params = useParams<{ spaceId: string }>()
  const [upsertEntity, { data: createdEntity }] = useUpsertEntityMutation();

  return (
    <div>
      {/* Create Scene Button */}
      <Button className="w-full my-4" type="button" onClick={() => upsertEntity({ name: "New Entity", scene_id: currentScene })}>
        <PlusCircleIcon className="mr-2" />
        Create Entity
      </Button>
      <>
        <EntityTree />
      </>
    </div >
  );
}
