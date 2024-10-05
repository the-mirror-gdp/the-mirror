"use client";
import { Form, FormControl, FormField, FormItem, FormMessage } from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { zodResolver } from "@hookform/resolvers/zod";
import { useEffect } from "react";
import { useForm } from "react-hook-form";
import { z, ZodSchema } from "zod";
import clsx from "clsx"; // Utility to merge class names

interface TwoWayInputProps<T> {
  entityId: string;
  fieldName: keyof T;
  formSchema: ZodSchema;
  defaultValue: string;
  useGetEntityQuery: (id: string) => { data?: T; isLoading: boolean; isSuccess: boolean; error?: any };
  useUpdateEntityMutation: () => readonly [
    (args: { sceneId: string; updateData: Partial<T> }) => any, // The mutation trigger function
    { isLoading: boolean; isSuccess: boolean; error?: any }
  ];
  className?: string; // Optional className prop
}

export function TwoWayInput<T>({
  entityId,
  fieldName,
  formSchema,
  defaultValue,
  useGetEntityQuery,
  useUpdateEntityMutation,
  className, // Destructure the className prop
}: TwoWayInputProps<T>) {
  const { data: entity, isLoading, isSuccess } = useGetEntityQuery(entityId);

  // Destructure the mutation trigger function and its state from the readonly tuple
  const [updateEntity, { isLoading: isUpdating, isSuccess: isUpdated, error }] = useUpdateEntityMutation();

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    mode: "onBlur",
    defaultValues: {
      [fieldName]: entity?.[fieldName] ?? defaultValue,
    },
  });

  // Handle form submission
  async function onSubmit(values: z.infer<typeof formSchema>) {
    await updateEntity({ sceneId: entityId, updateData: { [fieldName]: values[fieldName] } as Partial<T> });
  }

  // Reset form when entity data is fetched
  useEffect(() => {
    if (entity && isSuccess) {
      form.reset({
        [fieldName]: entity[fieldName] ?? defaultValue,
      });
    }
  }, [entity, isSuccess, form]);

  if (isLoading) {
    return <Skeleton className={clsx("w-full dark:bg-transparent border-none text-lg shadow-none", className)} />;
  }

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className={clsx("w-full", className)} onBlur={form.handleSubmit(onSubmit)}>
        <FormField
          control={form.control}
          name={fieldName as string} // Type casting to string since fieldName is dynamic
          render={({ field }) => (
            <FormItem>
              <FormControl>
                <Input
                  type="text"
                  className={clsx("w-full dark:bg-transparent border-none text-lg shadow-none", className)} // Apply className prop here
                  {...field}
                />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
      </form>
    </Form>
  );
}
