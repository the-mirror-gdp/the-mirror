'use client';
import { Button } from '@/components/ui/button';
import { useCreateSceneMutation, useGetAllScenesQuery, useLazyGetUserMostRecentlyUpdatedAssetsQuery } from '@/state/supabase';
import { ScrollArea } from '@radix-ui/react-scroll-area';
import { PlusCircleIcon, MoreHorizontal } from 'lucide-react'; // Import MoreHorizontal for ellipsis icon
import { DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuItem } from '@/components/ui/dropdown-menu'; // shadcn dropdown menu
import { useParams } from 'next/navigation';

export default function Scenes() {
  const params = useParams<{ spaceId: string }>()

  const { data: scenes } = useGetAllScenesQuery(params.spaceId);
  const [createScene, { data: createdScene }] = useCreateSceneMutation();

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
              <div key={scene.id} className="relative flex flex-col items-center shadow-md rounded-lg p-4">
                <img
                  src={scene.image_url || "/dev/150.jpg"} // Fallback to a placeholder image if no image_url is present
                  alt={scene.name}
                  className="w-full h-32 object-cover rounded-lg"
                />
                <div className="flex justify-betwee w-full">
                  <div className="flex-auto">
                    <input
                      type="text"
                      defaultValue={scene.name}
                      className="mt-2 w-full p-2 border rounded focus:outline-none focus:ring-2 focus:ring-primary"
                    />
                  </div>
                  <div className="flex-none content-center">
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" >
                          <MoreHorizontal className="w-5 h-5" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem onClick={() => alert(`Deleting scene: ${scene.name}`)}>
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
