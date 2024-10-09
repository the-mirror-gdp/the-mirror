
"use client";
import { ProgressIndeterminate } from "@/components/ui/progress-indeterminate";
import { Skeleton } from "@/components/ui/skeleton";

import { useRouter } from 'next/navigation'
import { useCreateSpaceMutation } from "@/state/spaces";
import { useEffect, useState } from "react";

// Note: with React 19 this will annoying run twice with strict mode. Not sure about solution and I don't want to disable strict mode. https://stackoverflow.com/questions/72238175/why-useeffect-running-twice-and-how-to-handle-it-well-in-react#comment139336889_78443665
export default function NewSpacePage() {
  const [createSpace] = useCreateSpaceMutation()
  const [started, setStarted] = useState(false)
  const router = useRouter()
  useEffect(() => {
    async function create() {
      const { data, error } = await createSpace({})
      if (error) {
        console.error(error)
        return
      }
      // navigate to the space
      router.replace(`/space/${data.id}/build`)
    }
    if (!started) {
      setStarted(true)
      // debugger
      create();
    }
  }, [])
  return (
    <div className="flex flex-col">
      {/* Top Menu Bar */}
      <div className="w-full h-16 bg-gray-200 dark:bg-gray-800">
        <Skeleton className="w-full h-full" />
      </div>

      <div className="flex flex-grow">
        {/* Sidebar (20% of the width) */}
        <div className="w-1/5 bg-gray-100 dark:bg-gray-900 m-4">
          <Skeleton className="w-full h-full" />
        </div>

        {/* Main content area (80% of the width) */}
        <div className="flex flex-grow p-4 items-center justify-center">
          <div className='w-full'>
            <ProgressIndeterminate />
          </div>
        </div>
      </div>
    </div>
  );
}
