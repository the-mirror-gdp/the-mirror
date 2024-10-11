"use client";
import { Input } from "@/components/ui/input";
import { AxisLabelCharacter } from "@/components/ui/text/axis-label-character";
import { cn } from "@/lib/utils";
import { Form, FormControl, FormField, FormItem, FormMessage } from "@/components/ui/form";
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";
import { DatabaseEntity, useGetSingleEntityQuery, useUpdateEntityMutation } from "@/state/entities";
import { z } from 'zod'; // Import zod for validation
import { useEffect } from "react";
import { Separator } from "@/components/ui/separator";

interface InputVector3Props {
  label: string;
  entity: DatabaseEntity;
  /**
   * Column name, e.g., "local_position", "local_scale". MUST BE SNAKE CASE
   */
  dbColumnNameSnakeCase: string;
  defaultValues: [number, number, number]; // Array of default values [x, y, z]
}

export default function InputVector3({ label, entity, dbColumnNameSnakeCase, defaultValues }: InputVector3Props) {
  // Define the form schema for a vector3 input
  const formSchema = z.object({
    x: z.coerce.number().finite().safe(),
    y: z.coerce.number().finite().safe(),
    z: z.coerce.number().finite().safe(),
  });

  // Initialize the form with react-hook-form
  const form = useForm({
    resolver: zodResolver(formSchema),
    defaultValues: {
      x: defaultValues[0],
      y: defaultValues[1],
      z: defaultValues[2],
    },
    mode: "onBlur", // Trigger form submission on blur
  });

  // Mutation to update the entity in the database
  const [updateEntity] = useUpdateEntityMutation();
  const { isLoading, isSuccess, data: fetchedEntity } = useGetSingleEntityQuery(entity.id);

  // Update form with fetched values
  useEffect(() => {
    if (isSuccess && fetchedEntity) {
      form.reset({
        x: fetchedEntity[dbColumnNameSnakeCase][0],
        y: fetchedEntity[dbColumnNameSnakeCase][1],
        z: fetchedEntity[dbColumnNameSnakeCase][2],
      });
    }
  }, [fetchedEntity, isSuccess, form, dbColumnNameSnakeCase]);

  // Handle form submission
  async function onSubmit(values: any) {
    const newValues = [values.x, values.y, values.z];

    // Only update if values have changed
    if (
      newValues[0] === entity[dbColumnNameSnakeCase][0] &&
      newValues[1] === entity[dbColumnNameSnakeCase][1] &&
      newValues[2] === entity[dbColumnNameSnakeCase][2]
    ) {
      return;
    }


    // Submit the updated vector to the database
    await updateEntity({
      id: entity.id,
      scene_id: entity.scene_id,
      parent_id: entity.parent_id || undefined,
      order_under_parent: entity.order_under_parent || undefined,
      [dbColumnNameSnakeCase]: newValues, // Update the entire array in the DB
    });
  }

  return (
    <>
      <div className="text-white mt-1">{label}</div>
      <Form {...form}>
        <form
          className="flex space-x-2"
          onBlur={form.handleSubmit(onSubmit)} // Submit on blur
        >
          <AxisInput axis="x" field="x" form={form} />
          <AxisInput axis="y" field="y" form={form} />
          <AxisInput axis="z" field="z" form={form} />
        </form>
      </Form>
    </>
  );
}

// AxisInput Component for each axis (x, y, z)
function AxisInput({ axis, field, form }: { axis: 'x' | 'y' | 'z'; field: string; form: any }) {
  return (
    <div className="flex items-center space-x-2">
      <AxisLabelCharacter axis={axis} className="my-auto mr-3" />
      <FormField
        control={form.control}
        name={field}
        render={({ field }) => (
          <FormItem>
            <FormControl>
              <Input
                type="number"
                autoComplete="off"
                className={cn("dark:bg-transparent px-1 py-0 pb-1 border-none shadow-none text-lg text-white")}
                {...field}
              />
            </FormControl>
            <FormMessage />
          </FormItem>
        )}
      />
    </div>
  );
}
