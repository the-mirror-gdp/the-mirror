"use client";

import { Button } from '@/components/ui/button';
import { PlusCircleIcon } from 'lucide-react';
import EntityTree from '@/components/entity-tree/entity-tree';
import { useAppSelector } from '@/hooks/hooks';
import { useCreateEntityMutation } from '@/state/api/entities';
import { selectCurrentScene } from '@/state/local.slice';
import { useParams } from 'next/navigation';
import { Separator } from '@/components/ui/separator';
import { H2 } from '@/components/ui/text/h2';
import { useEffect, useState } from 'react';

export default function Hierarchy() {
  const currentScene = useAppSelector(selectCurrentScene);  
  const [createEntity] = useCreateEntityMutation();
  const [isClient, setIsClient] = useState(false);

  useEffect(() => {
    // Ensure this runs only on the client-side
    setIsClient(true);
  }, []);

  return (
    <>
      {/* Render nothing dependent on currentScene until client-side rendering */}
      {isClient && (
        <>
          <H2>{currentScene ? <>Scene: {currentScene.name}</> : "Loading..."}</H2>
          <Separator className="mt-2 mb-1" />
          {currentScene && (
            <Button
              className="w-full my-4"
              type="button"
              onClick={() => createEntity({ name: "New Entity", scene_id: currentScene.id })}
            >
              <PlusCircleIcon className="mr-2" />
              Create Entity
            </Button>
          )}
          <EntityTree />
        </>
      )}
    </>
  );
}
