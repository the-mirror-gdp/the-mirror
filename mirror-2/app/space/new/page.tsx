
"use client";
import { ProgressIndeterminate } from "@/components/ui/progress-indeterminate";
import { Skeleton } from "@/components/ui/skeleton";
import { useAppDispatch } from "@/hooks/hooks";
import { useCreateSpaceMutation } from "@/state/supabase";
import { useEffect } from "react";
import { useRouter } from 'next/navigation'

export default function NewSpacePage() {
  const [createSpace] = useCreateSpaceMutation()
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
    create()
  }, [router])
  return (
    <div className="min-h-screen flex flex-col">
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
