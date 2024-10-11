'use client';
import { Button } from '@/components/ui/button';

import { ScrollArea } from '@radix-ui/react-scroll-area';
import { PlusCircleIcon, MoreHorizontal } from 'lucide-react'; // Import MoreHorizontal for ellipsis icon
import { DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuItem } from '@/components/ui/dropdown-menu'; // shadcn dropdown menu
import { useParams } from 'next/navigation';

import { z } from 'zod'; // Import zod for validation
import { SyncedTextInput } from '@/components/ui/synced-inputs/synced-text-input';
import { useAppDispatch, useAppSelector } from '@/hooks/hooks';
import { getCurrentScene, setControlBarCurrentView, setCurrentScene } from '@/state/local';
import { useCreateSceneMutation, useDeleteSceneMutation, useGetAllScenesQuery, useGetSingleSceneQuery, useUpdateSceneMutation } from '@/state/scenes';
import { cn } from '@/utils/cn';
import { generateSceneName } from '@/actions/name-generator';
import { Input } from '@/components/ui/input';

export default function Scenes() {
  const params = useParams<{ spaceId: string }>()

  const { data: scenes } = useGetAllScenesQuery(params.spaceId);
  const [createScene, { data: createdScene }] = useCreateSceneMutation();
  const [deleteScene] = useDeleteSceneMutation();
  const [updateScene] = useUpdateSceneMutation();
  const dispatch = useAppDispatch();
  const currentScene = useAppSelector(getCurrentScene);

  // Validation schema for scene name
  const formSchema = z.object({
    name: z.string().min(3, { message: "Scene name must be at least 3 characters long" }),
  });

  return (
    <>
      {/* Create Scene Button */}
      <Button className="w-full my-4" type="button" onClick={async () => {
        const result = await createScene({ name: await generateSceneName(), space_id: params.spaceId });
        if (result.data) {
          console.log("Scene created successfully:", result.data);
          await dispatch(setCurrentScene(result.data));
          dispatch(setControlBarCurrentView('hierarchy'));
        } else {
          console.error("Error creating scene:", result.error);
        }
      }}>
        <PlusCircleIcon className="mr-2" />
        Create Scene
      </Button>

      {/* Scrollable area that takes up remaining space */}
      <div className="flex-1 overflow-hidden">
        <ScrollArea className="">
          <div className="grid grid-cols-1 gap-4 pb-40">
            {scenes?.map((scene) => (
              <div
                key={scene.id}
                className={cn("relative flex flex-col items-center shadow-md rounded-lg p-4 gap-4 border border-transparent hover:border-accent transition-all duration-100 cursor-pointer", { "border border-primary": currentScene?.id === scene.id })}
                onClick={() => {
                  // Handle scene click
                  dispatch(setCurrentScene(scene));
                  dispatch(setControlBarCurrentView('hierarchy'));
                }}
              >
                <img
                  src={scene.image_url || "/dev/150.jpg"} // Fallback to a placeholder image if no image_url is present
                  alt={scene.name}
                  className="w-full h-32 object-cover rounded-lg"
                />
                <div className="flex justify-between w-full">
                  <div className="flex-auto">
                    <SyncedTextInput
                      id={scene.id}
                      fieldName="name"
                      formSchema={formSchema} // Your Zod validation schema
                      defaultValue={scene.name}
                      generalEntity={scene}
                      useGenericGetEntityQuery={useGetSingleSceneQuery}
                      useGenericUpdateEntityMutation={useUpdateSceneMutation}
                      renderComponent={(field) => (
                        <Input
                          type="text"
                          autoComplete="off"
                          className={cn("dark:bg-transparent border-none shadow-none  text-white")} // Apply className prop here
                          {...field}
                        />
                      )}
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
    </>
  );
}
