import { TwoWayInput } from "@/components/two-way-input";
import { Input } from "@/components/ui/input";
import { cn } from "@/lib/utils";
import { useGetSingleEntityQuery, useUpdateEntityMutation } from "@/state/entities";
import { z } from 'zod'; // Import zod for validation

export function EntityFormGroup({ entity }) {

  const formSchema = z.object({
    name: z.string().min(3, { message: "Scene name must be at least 1 character long" }),
  });

  return <TwoWayInput
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
        className={cn("dark:bg-transparent border-none shadow-none text-lg text-white")}
        {...field}
      />
    )}
  />
}
