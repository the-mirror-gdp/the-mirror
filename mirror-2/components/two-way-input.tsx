"use client";
import { Form, FormControl, FormField, FormItem, FormMessage } from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { zodResolver } from "@hookform/resolvers/zod";
import { useEffect, useRef } from "react";
import { useForm } from "react-hook-form";
import { z, ZodSchema } from "zod";
import clsx from "clsx"; // Utility to merge class names
import { cn } from "@/lib/utils";

interface TwoWayInputProps<T> {
  id: string;
  generalEntity: any;
  fieldName: keyof T;
  formSchema: ZodSchema;
  defaultValue: string;
  // "General"  entity bc not referring our proper Entity, but anything
  useGeneralGetEntityQuery: (id: string) => { data?: T; isLoading: boolean; isSuccess: boolean; error?: any };
  // "General"  entity bc not referring our proper Entity, but anything
  useGeneralUpdateEntityMutation: () => readonly [
    (args: { id: string;[fieldName: string]: any }) => any, // The mutation trigger function
    { isLoading: boolean; isSuccess: boolean; error?: any }
  ];
  className?: string; // Optional className prop
  onSubmitFn?: Function
  onBlurFn?: Function
}
//  TODO fix and ensure deduping works correctly to not fire a ton of network requests
export function TwoWayInput<T>({
  id: generalEntityId,
  generalEntity,
  fieldName,
  formSchema,
  defaultValue,
  useGeneralGetEntityQuery, // "General"  entity bc not referring our proper Entity, but anything
  useGeneralUpdateEntityMutation, // "General"  entity bc not referring our proper Entity, but anything
  className, // Destructure the className prop
  onSubmitFn,
  onBlurFn
}: TwoWayInputProps<T>) {
  const { data: entity, isLoading, isSuccess } = useGeneralGetEntityQuery(generalEntityId);

  // Destructure the mutation trigger function and its state from the readonly tuple
  const [updateGeneralEntity, { isLoading: isUpdating, isSuccess: isUpdated, error }] = useGeneralUpdateEntityMutation();

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    mode: "onBlur",
    defaultValues: {
      [fieldName]: entity?.[fieldName] ?? defaultValue,
    },

  });

  // Handle form submission
  async function onSubmit(values: z.infer<typeof formSchema>) {
    // check if values changed
    if (entity && isSuccess && entity[fieldName] === values[fieldName]) {
      return;
    }
    if (onSubmitFn) {
      onSubmitFn()
    }
    await updateGeneralEntity({ id: generalEntityId, ...generalEntity, [fieldName]: values[fieldName] });
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
      <form onSubmit={form.handleSubmit(onSubmit)} className={cn(className)} onBlur={form.handleSubmit(onSubmit)}>
        <FormField
          control={form.control}
          name={fieldName as string} // Type casting to string since fieldName is dynamic
          render={({ field }) => (
            <FormItem>
              <FormControl>
                <Input
                  type="text"
                  className={cn("dark:bg-transparent border-none shadow-none  text-white", className)} // Apply className prop here
                  {...field}
                  onBlur={() => {
                    if (onBlurFn) {
                      onBlurFn()
                    }
                  }
                  }
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
