"use client"

import { useGetSingleSpaceQuery } from "@/state/supabase"
import { useParams } from "next/navigation"


// blank page since we're using the parallel routes for spaceViewport, controlBar, etc.
export default function Page() {
  const params = useParams<{ spaceId: string }>()
  const space = useGetSingleSpaceQuery(params.spaceId)
  return null
}
