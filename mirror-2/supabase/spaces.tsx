"use client";
import { createSupabaseBrowserClient } from "@/utils/supabase/client";
import { cache } from "react";

// we want to use client-side only because supabase tracks auth clientside


export const getSingleSpaceAction = cache(async (spaceId: string) => {
  const supabase = createSupabaseBrowserClient();

  const { data, error } = await supabase
    .from("spaces")
    .select("*")
    .eq("id", spaceId)
    .single()

  if (error) {
    console.error('sb', error.message);
    console.error(error.message);
    return { error: error.message };
  }
  console.log('sb data', data)
  return { data };
})
