"use client"
import { TwoWayInput } from "@/components/two-way-input";
import { Input } from "@/components/ui/input";
import { useAppSelector } from "@/hooks/hooks";
import { useGetSingleEntityQuery, useUpdateEntityMutation } from "@/state/entities";
import { getCurrentEntity } from "@/state/local";
import { cn } from "@/utils/cn";
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
      renderComponent={(field) => (
        <Input
          type="text"
          autoComplete="off"
          className={cn("dark:bg-transparent border-none shadow-none  text-white")} // Apply className prop here
          {...field}
        />
      )}
    />
    }
  </div>
}
