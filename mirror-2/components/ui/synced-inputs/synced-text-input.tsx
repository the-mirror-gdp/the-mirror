"use client";
import { Form, FormControl, FormField, FormItem, FormMessage } from "@/components/ui/form";
import { Skeleton } from "@/components/ui/skeleton";
import { zodResolver } from "@hookform/resolvers/zod";
import { useEffect } from "react";
import { useForm } from "react-hook-form";
import { z, ZodSchema } from "zod";
import clsx from "clsx"; // Utility to merge class names
import { cn } from "@/lib/utils";

interface SyncedTextInputProps<T> {
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
  convertSubmissionToNumber?: boolean; // New optional prop to convert submission to number
}

export function SyncedTextInput<T>({
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
  renderComponent,
  convertSubmissionToNumber = false, // Default to false
}: SyncedTextInputProps<T>) {
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
    // Handle conversion to number if convertSubmissionToNumber is true
    if (convertSubmissionToNumber) {
      const convertedValue = Number(values[fieldName]); // Convert to number
      if (isNaN(convertedValue)) {
        console.error("Invalid number input");
        return;
      }
      values = { ...values, [fieldName]: convertedValue }; // Update values with the converted number
    }

    // Check if the value has actually changed
    if (entity && isSuccess && entity[fieldName] === values[fieldName]) {
      return;
    }
    if (onSubmitFn) {
      onSubmitFn();
    }
    await updateGeneralEntity({ id: generalEntityId, ...generalEntity, [fieldName]: values[fieldName] });
  }

  // Reset the form when the entity data is successfully fetched
  useEffect(() => {
    if (entity && isSuccess) {
      form.reset({
        [fieldName]: entity[fieldName] ?? defaultValue,
      });
    }
  }, [entity, isSuccess, form]);

  const formSubmitFn = async (event) => {
    event.preventDefault()
    const isValid = await form.trigger(fieldName as string); // Manually trigger validation

    if (isValid) {
      const values = form.getValues(); // Get current form values
      console.log("Form is valid, triggering submission:", values);
      onSubmit(values); // Manually call onSubmit after validation passes
    }
  }

  // Display loading state if data is still being fetched
  if (isLoading) {
    return <Skeleton className={clsx("w-full dark:bg-transparent border-none text-lg shadow-none", className)} />;
  }

  return (
    <Form {...form}>
      <form
        className={cn(className)}
        onBlur={
          formSubmitFn
        }
        onSubmit={formSubmitFn}
      >
        <FormField
          control={form.control}
          name={fieldName as string}
          render={({ field }) => (
            <FormItem>
              <FormControl>
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
