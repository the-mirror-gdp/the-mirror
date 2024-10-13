'use client'
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormMessage
} from '@/components/ui/form'
import { Input } from '@/components/ui/input'
import { Skeleton } from '@/components/ui/skeleton'
import { useGetSingleSpaceQuery, useUpdateSpaceMutation } from '@/state/spaces'
import { zodResolver } from '@hookform/resolvers/zod'
import { useParams } from 'next/navigation'
import { useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { z } from 'zod'

const formSchema = z.object({
  name: z.string().min(3)
})

export function EditableSpaceName() {
  const params = useParams<{ spaceId: string }>()
  const spaceId: number = parseInt(params.spaceId, 10) // Use parseInt for safer conversion

  const {
    data: space,
    isLoading,
    isSuccess,
    error
  } = useGetSingleSpaceQuery(spaceId)
  const [updateSpace] = useUpdateSpaceMutation()

  // define the form
  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    mode: 'onBlur',
    defaultValues: {
      name: space?.name || ''
    }
    // errors: error TODO add error handling here
  })
  // 2. Define a submit handler.
  async function onSubmit(values: z.infer<typeof formSchema>) {
    // update the space name
    await updateSpace({ id: space.id, updateData: { name: values.name } })
  }

  // Reset the form values when the space data is fetched
  useEffect(() => {
    if (space && isSuccess) {
      form.reset({
        name: space.name || '' // Set the form value once space.name is available
      })
    }
  }, [space, isSuccess, form]) // Only run this effect when space or isLoading changes

  return isLoading ? (
    <Skeleton className="w-full dark:bg-transparent border-none text-lg shadow-none md:w-2/3 lg:w-1/3"></Skeleton>
  ) : (
    <Form {...form}>
      <form
        onSubmit={form.handleSubmit(onSubmit)}
        className="w-full"
        onBlur={form.handleSubmit(onSubmit)}
      >
        <FormField
          control={form.control}
          name="name"
          render={({ field }) => (
            <FormItem>
              <FormControl>
                <Input
                  type="text"
                  className="w-full dark:bg-transparent border-none text-lg shadow-none md:w-2/3 lg:w-1/3"
                  {...field}
                />
              </FormControl>
              {/* TODO add better styling for this so it doesn't shift the input field */}
              <FormMessage />
            </FormItem>
          )}
        />
      </form>
    </Form>
  )
}
