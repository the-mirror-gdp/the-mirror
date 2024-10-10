"use client";
import { Form, FormControl, FormField, FormItem, FormMessage } from "@/components/ui/form";
import { Skeleton } from "@/components/ui/skeleton";
import { zodResolver } from "@hookform/resolvers/zod";
import { useEffect } from "react";
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
  useGeneralGetEntityQuery: (id: string) => { data?: T; isLoading: boolean; isSuccess: boolean; error?: any };
  useGeneralUpdateEntityMutation: () => readonly [
    (args: { id: string;[fieldName: string]: any }) => any, // The mutation trigger function
    { isLoading: boolean; isSuccess: boolean; error?: any }
  ];
  className?: string; // Optional className prop
  onSubmitFn?: Function;
  onBlurFn?: Function;
  renderComponent: (field: any, fieldName: string) => JSX.Element; // Dynamically render a component
}

export function TwoWayInput<T>({
  id: generalEntityId,
  generalEntity,
  fieldName,
  formSchema,
  defaultValue,
  useGeneralGetEntityQuery,
  useGeneralUpdateEntityMutation,
  className,
  onSubmitFn,
  onBlurFn,
  renderComponent, // Now accepting a renderComponent prop
}: TwoWayInputProps<T>) {
  const { data: entity, isLoading, isSuccess } = useGeneralGetEntityQuery(generalEntityId);

  const [updateGeneralEntity, { isLoading: isUpdating, isSuccess: isUpdated, error }] = useGeneralUpdateEntityMutation();

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    mode: "onBlur",
    defaultValues: {
      [fieldName]: entity?.[fieldName] ?? defaultValue,
    },
  });

  async function onSubmit(values: z.infer<typeof formSchema>) {
    if (entity && isSuccess && entity[fieldName] === values[fieldName]) {
      return;
    }
    if (onSubmitFn) {
      onSubmitFn();
    }
    await updateGeneralEntity({ id: generalEntityId, ...generalEntity, [fieldName]: values[fieldName] });
  }

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
                {/* Use the renderComponent prop to dynamically render any input */}
                {renderComponent && renderComponent(field, fieldName as string)}
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
      </form>
    </Form>
  );
}
