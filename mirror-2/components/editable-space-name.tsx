"use client"
import { Input } from "@/components/ui/input";
import { getSingleSpaceAction } from "@/supabase/spaces";
import { useParams } from "next/navigation";
import { useEffect, useState } from "react";

export function EditableSpaceName() {
  const [name, setName] = useState("");
  const params = useParams<{ spaceId: string }>()

  useEffect(() => {
    const run = async () => {
      const { data, error } = await getSingleSpaceAction(params.spaceId);
      console.log("data", data);
      console.log("error", error);
      // @ts-ignore
      setName(data[0]?.name);
    }
    run()
  }, [])
  return (
    (name && <Input
      type="text"
      className="w-full dark:bg-transparent border-none text-lg shadow-none md:w-2/3 lg:w-1/3"
      defaultValue={name}
    />)
  );
}
