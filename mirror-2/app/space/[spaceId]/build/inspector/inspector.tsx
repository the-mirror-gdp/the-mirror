"use client"
import { EntityFormGroup } from "@/app/space/[spaceId]/build/inspector/entity.formgroup";
import { useAppSelector } from "@/hooks/hooks";
import { getCurrentEntity } from "@/state/local";
import { cn } from "@/utils/cn";

export default function Inspector({ className }) {
  const entity = useAppSelector(getCurrentEntity)

  return <div className={cn(className, "mt-1 p-2")}>
    {entity && <EntityFormGroup entity={entity} />}
  </div>


}
