"use client"
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { useGetSingleSpaceQuery } from "@/state/supabase";
import { useParams } from "next/navigation";
import { Suspense, useEffect } from "react";

export function EditableSpaceName() {
  const params = useParams<{ spaceId: string }>()
  let { data: space, isLoading, error } = useGetSingleSpaceQuery(params.spaceId)
  return (
    isLoading ? <Skeleton className="w-full dark:bg-transparent border-none text-lg shadow-none md:w-2/3 lg:w-1/3"></Skeleton> :
      <Input
        type="text"
        className="w-full dark:bg-transparent border-none text-lg shadow-none md:w-2/3 lg:w-1/3"
        defaultValue={space?.name || ""}
      />

  );
}
