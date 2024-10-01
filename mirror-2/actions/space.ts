"use server";

import { createClient } from "@/utils/supabase/server";

export const getSingleSpaceAction = async (spaceId: string) => {
  const supabase = createClient();
  const { data, error } = await supabase
    .from("spaces")
    .select("*")
    .eq("id", spaceId)

  if (error) {
    console.error(error.message);
    return { error: error.message };
  }

  return { data };
};
