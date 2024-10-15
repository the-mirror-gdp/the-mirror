"use client"
import { EntityFormGroup } from "@/app/space/[spaceId]/build/inspector/entity.formgroup";
import { useAppSelector } from "@/hooks/hooks";
import { selectCurrentEntity } from "@/state/local.slice";
import { cn } from "@/utils/cn";

export default function Inspector({ className }) {
  const entity = useAppSelector(selectCurrentEntity)

  return <div className={cn(className, "flex flex-col p-3")}>
    {entity && <EntityFormGroup entity={entity} />}
  </div>


}
