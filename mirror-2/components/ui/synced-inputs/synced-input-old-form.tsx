'use client'
import {
  FormProvider,
  FormControl,
  FormField,
  FormItem,
  FormMessage
} from '@/components/ui/form'
import { Skeleton } from '@/components/ui/skeleton'
import { zodResolver } from '@hookform/resolvers/zod'
import { useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { z, ZodSchema } from 'zod'
import clsx from 'clsx' // Utility to merge class names
import { cn } from '@/lib/utils'

interface SyncedInputProps<T> {
  id: any // TODO fix to string | number; not worth debugging the TS right now
  generalEntity: any
  fieldName: keyof T
  formSchema: ZodSchema
  defaultValue: any
  useGenericGetEntityQuery: (id: any) => {
    // TODO fix to string | number for id
    data?: T
    isLoading: boolean
    isSuccess: boolean
    error?: any
  }
  useGenericUpdateEntityMutation: () => readonly [
    (args: { id: any; [fieldName: string]: any }) => any, // TODO fix to string | number for id; not worth debugging the TS right now
    { isLoading: boolean; isSuccess: boolean; error?: any }
  ]
  className?: string // Optional className prop
  onSubmitFn?: Function
  onBlurFn?: Function
  renderComponent: (field: any, fieldName: string) => JSX.Element // Dynamically render a component
  convertSubmissionToNumber?: boolean // New optional prop to convert submission to number
  triggerOnChange?: boolean // triggers the form component on change. Use for booleans or specific cases.
}

export function SyncedInput<T>({
  id,
  generalEntity,
  fieldName,
  formSchema,
  defaultValue,
  useGenericGetEntityQuery,
  useGenericUpdateEntityMutation,
  className,
  onSubmitFn,
  onBlurFn,
  renderComponent,
  convertSubmissionToNumber = false, // Default to false
  triggerOnChange = false // triggers the form component on change. Use for booleans
}: SyncedInputProps<T>) {
  // const generalEntityId: any =
  //   typeof generalEntityIdInput === 'string'
  //     ? parseInt(generalEntityIdInput, 10)
  //     : generalEntityIdInput // TODO fix to string | number; not worth debugging the TS right now

  const {
    data: genericEntity,
    isLoading,
    isSuccess
  } = useGenericGetEntityQuery(id)

  const [
    updateGeneralEntity,
    { isLoading: isUpdating, isSuccess: isUpdated, error }
  ] = useGenericUpdateEntityMutation()
  let defaultValueToSet =
    genericEntity?.[fieldName] !== undefined
      ? genericEntity[fieldName]
      : defaultValue

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    mode: 'onBlur',
    defaultValues: {
      [fieldName]: defaultValueToSet
    }
  })

  async function onSubmit(values: z.infer<typeof formSchema>) {
    // Handle conversion to number if convertSubmissionToNumber is true
    if (convertSubmissionToNumber) {
      const convertedValue = Number(values[fieldName]) // Convert to number
      if (isNaN(convertedValue)) {
        console.error('Invalid number input')
        return
      }
      values = { ...values, [fieldName]: convertedValue } // Update values with the converted number
    }

    // Check if the value has actually changed
    if (genericEntity && isSuccess) {
      const entityValue = genericEntity[fieldName]
      const formValue = values[fieldName]
      if (entityValue === formValue) {
        return
      }
    }
    if (onSubmitFn) {
      onSubmitFn()
    }
    await updateGeneralEntity({
      id,
      ...generalEntity,
      [fieldName]: values[fieldName]
    })
  }

  // Reset the form when the entity data is successfully fetched
  useEffect(() => {
    if (genericEntity && isSuccess) {
      defaultValueToSet =
        genericEntity?.[fieldName] !== undefined
          ? genericEntity[fieldName]
          : defaultValue

      form.reset({
        [fieldName]: defaultValueToSet
      })
    }
  }, [genericEntity, isSuccess, form])

  const handleChange = async () => {
    const isValid = await form.trigger(fieldName as string) // Manually trigger validation
    if (isValid) {
      const values = form.getValues() // Get current form values
      console.log('Form is valid, triggering submission:', values)
      onSubmit(values) // Manually call onSubmit after validation passes
    }
  }

  // Display loading state if data is still being fetched
  if (isLoading) {
    return (
      <Skeleton
        className={clsx(
          'w-full dark:bg-transparent border-none text-lg shadow-none',
          className
        )}
      />
    )
  }

  return (
    <FormProvider {...form}>
      <form
        className={cn(className)}
        onBlur={form.handleSubmit(onSubmit)} // Trigger submission on blur as fallback
      >
        <FormField
          control={form.control}
          name={fieldName as string}
          render={({ field }) => (
            <FormItem>
              <FormControl>
                {renderComponent &&
                  renderComponent(
                    {
                      ...field,
                      onChange: (e) => {
                        field.onChange(e) // Update form state
                        if (triggerOnChange) {
                          handleChange() // Trigger submission on change if flag is true
                        }
                      }
                    },
                    fieldName as string
                  )}
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
      </form>
    </FormProvider>
  )
}
