'use client';
import { Button } from '@/components/ui/button';
import { useCreateSceneMutation, useDeleteSceneMutation, useGetAllScenesQuery, useGetSingleSceneQuery, useUpdateSceneMutation } from '@/state/supabase';
import { ScrollArea } from '@radix-ui/react-scroll-area';
import { PlusCircleIcon, MoreHorizontal } from 'lucide-react'; // Import MoreHorizontal for ellipsis icon
import { DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuItem } from '@/components/ui/dropdown-menu'; // shadcn dropdown menu
import { useParams } from 'next/navigation';

import { z } from 'zod'; // Import zod for validation
import { TwoWayInput } from '@/components/two-way-input';

export default function Scenes() {
  const params = useParams<{ spaceId: string }>()

  const { data: scenes } = useGetAllScenesQuery(params.spaceId);
  const [createScene, { data: createdScene }] = useCreateSceneMutation();
  const [deleteScene] = useDeleteSceneMutation();
  const [updateScene] = useUpdateSceneMutation();

  // Validation schema for scene name
  const formSchema = z.object({
    name: z.string().min(3, { message: "Scene name must be at least 3 characters long" }),
  });

  return (
    <div className="flex flex-col p-4">
      {/* Create Scene Button */}
      <Button className="w-full my-4" type="button" onClick={() => createScene({ name: "New Scene", space_id: params.spaceId })}>
        <PlusCircleIcon className="mr-2" />
        Create Scene
      </Button>

      {/* Scrollable area that takes up remaining space */}
      <div className="flex-1 overflow-auto">
        <ScrollArea className="h-screen">
          <div className="grid grid-cols-1 gap-4 pb-40">
            {scenes?.map((scene) => (
              <div key={scene.id} className="relative flex flex-col items-center shadow-md rounded-lg p-4 gap-4">
                <img
                  src={scene.image_url || "/dev/150.jpg"} // Fallback to a placeholder image if no image_url is present
                  alt={scene.name}
                  className="w-full h-32 object-cover rounded-lg"
                />
                <div className="flex justify-between w-full">
                  <div className="flex-auto">
                    <TwoWayInput
                      entityId={scene.id}
                      fieldName="name"
                      formSchema={formSchema} // Your Zod validation schema
                      defaultValue={scene.name}
                      useGetEntityQuery={useGetSingleSceneQuery}
                      useUpdateEntityMutation={useUpdateSceneMutation}
                    />
                  </div>
                  <div className="flex-none content-center">
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost">
                          <MoreHorizontal className="w-5 h-5" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem className="cursor-pointer" onClick={() => deleteScene(scene.id)}>
                          Delete
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </ScrollArea>
      </div>
    </div>
  );
}
