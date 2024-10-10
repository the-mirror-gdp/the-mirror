"use client"
import { TwoWayInput } from "@/components/two-way-input";
import { useAppSelector } from "@/hooks/hooks";
import { useGetSingleEntityQuery, useUpdateEntityMutation } from "@/state/entities";
import { getCurrentEntity } from "@/state/local";
import { z } from 'zod'; // Import zod for validation

export default function Inspector() {
  const entity = useAppSelector(getCurrentEntity)

  const formSchema = z.object({
    name: z.string().min(3, { message: "Scene name must be at least 1 character long" }),
  });

  return <div className={"p-2"}>
    {entity && <TwoWayInput
      id={entity.id}
      fieldName="name"
      formSchema={formSchema} // Your Zod validation schema
      defaultValue={entity.name}
      generalEntity={entity}
      useGeneralGetEntityQuery={useGetSingleEntityQuery}
      useGeneralUpdateEntityMutation={useUpdateEntityMutation}
    />
    }
  </div>
}
