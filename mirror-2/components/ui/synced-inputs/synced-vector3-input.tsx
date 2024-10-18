'use client'
import { Input } from '@/components/ui/input'
import { AxisLabelCharacter } from '@/components/ui/text/axis-label-character'
import { cn } from '@/lib/utils'
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormMessage
} from '@/components/ui/form'
import { zodResolver } from '@hookform/resolvers/zod'
import { useForm } from 'react-hook-form'
import { DatabaseEntity } from '@/state/api/entities' // Import entities
import { z } from 'zod' // Import zod for validation
import { useEffect } from 'react'
import { Separator } from '@/components/ui/separator'
import { skipToken } from '@reduxjs/toolkit/query'

interface SyncedVector3InputProps {
  label: string
  entity: DatabaseEntity
  dbColumnNameSnakeCase: keyof DatabaseEntity
  defaultValues: [number, number, number] // Array of default values [x, y, z]
  useGetSingleGenericEntityQuery: (id: any) => {
    isLoading: boolean
    isSuccess: boolean
    data?: DatabaseEntity
  }
  useUpdateGenericEntityMutation: () => readonly [
    (args: Partial<DatabaseEntity> & { id: string }) => Promise<any>, // Mutation expects `id` to be required
    { isLoading: boolean; isSuccess: boolean }
  ]
  /**
   * Use if the update query needs to send existing info for full overwrites, such as with batch updates
   */
  propertiesToIncludeInUpdate: { [x: string]: any }
}

export default function SyncedVector3Input({
  label,
  entity,
  dbColumnNameSnakeCase,
  defaultValues,
  useGetSingleGenericEntityQuery: useGetSingleGenericEntityQuery,
  useUpdateGenericEntityMutation: useUpdateGenericEntityMutation,
  propertiesToIncludeInUpdate
}: SyncedVector3InputProps) {
  // Define the form schema for a vector3 input
  const formSchema = z.object({
    x: z.coerce.number().finite().safe(),
    y: z.coerce.number().finite().safe(),
    z: z.coerce.number().finite().safe()
  })

  // Initialize the form with react-hook-form
  const form = useForm({
    resolver: zodResolver(formSchema),
    defaultValues: {
      x: defaultValues[0],
      y: defaultValues[1],
      z: defaultValues[2]
    },
    mode: 'onBlur' // Trigger form submission on blur
  })

  // Mutation to update the entity in the database
  const [updateGenericEntity] = useUpdateGenericEntityMutation()
  const {
    isLoading,
    isSuccess,
    data: fetchedGenericEntity
  } = useGetSingleGenericEntityQuery(entity.id || skipToken)

  // Update form with fetched values
  useEffect(() => {
    if (
      isSuccess &&
      fetchedGenericEntity &&
      fetchedGenericEntity[dbColumnNameSnakeCase]
    ) {
      const values = fetchedGenericEntity[dbColumnNameSnakeCase] as [
        number,
        number,
        number
      ]
      form.reset({
        x: values[0] ?? defaultValues[0],
        y: values[1] ?? defaultValues[1],
        z: values[2] ?? defaultValues[2]
      })
    }
  }, [
    fetchedGenericEntity,
    isSuccess,
    form,
    dbColumnNameSnakeCase,
    defaultValues
  ])

  // Handle form submission
  async function onSubmit(values: any) {
    const newValues = [values.x, values.y, values.z]

    // Only update if values have changed
    const existingValues = entity[dbColumnNameSnakeCase] as
      | [number, number, number]
      | null
    if (
      existingValues &&
      newValues[0] === existingValues[0] &&
      newValues[1] === existingValues[1] &&
      newValues[2] === existingValues[2]
    ) {
      return
    }

    // Submit the updated vector to the database
    await updateGenericEntity({
      id: entity.id,
      ...propertiesToIncludeInUpdate,
      [dbColumnNameSnakeCase]: newValues // Update the entire array in the DB
    })
  }

  return (
    <>
      <div className="text-white mt-1">{label}</div>
      <Form {...form}>
        <form className="flex space-x-2" onBlur={form.handleSubmit(onSubmit)}>
          {' '}
          {/* Submit on blur */}
          <AxisInput axis="x" field="x" form={form} />
          <AxisInput axis="y" field="y" form={form} />
          <AxisInput axis="z" field="z" form={form} />
        </form>
      </Form>
    </>
  )
}

// AxisInput Component for each axis (x, y, z)
function AxisInput({
  axis,
  field,
  form
}: {
  axis: 'x' | 'y' | 'z'
  field: string
  form: any
}) {
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
                className={cn(
                  'dark:bg-transparent px-1 py-0 pb-1 border-none shadow-none text-lg text-white'
                )}
                {...field}
              />
            </FormControl>
            <FormMessage />
          </FormItem>
        )}
      />
    </div>
  )
}
