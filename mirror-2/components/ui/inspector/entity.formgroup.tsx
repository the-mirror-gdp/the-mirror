'use client'
import {
  entitySchema,
  entitySchemaUiFormDefaultValues
} from '@/components/engine/schemas/entity.schema'
import { FormProvider } from '@/components/ui/form'
import { Separator } from '@/components/ui/separator'
import { SyncedTextInput } from '@/components/ui/synced-inputs/synced-text-input'
import { SyncedVec3Input } from '@/components/ui/synced-inputs/synced-vec3-input'
import { useAppSelector } from '@/hooks/hooks'
import {
  DatabaseEntity,
  useGetSingleEntityQuery,
  useUpdateEntityMutation
} from '@/state/api/entities'
import { selectCurrentEntity } from '@/state/local.slice'
import { convertVecNumbersToIndividual } from '@/utils/utils'
import { zodResolver } from '@hookform/resolvers/zod'
import { skipToken } from '@reduxjs/toolkit/query'
import { useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { z } from 'zod'

export function EntityFormGroup() {
  const currentEntityForId = useAppSelector(selectCurrentEntity)
  const { data: entity, isSuccess: getEntitySuccess } = useGetSingleEntityQuery(
    currentEntityForId?.id || skipToken
  )
  const [updateEntity, { isLoading: isUpdating, isSuccess: isUpdated, error }] =
    useUpdateEntityMutation()

  const form = useForm<z.infer<typeof entitySchema>>({
    resolver: zodResolver(entitySchema),
    mode: 'onBlur',
    defaultValues: entitySchemaUiFormDefaultValues,
    // values: <- dont do this here, use the useEffect so we have control over resets. Otherwise, weird behavior.
    resetOptions: {
      keepDefaultValues: true,
      keepDirtyValues: true
    }
  })
  // hadnle form reset on entity update
  useEffect(() => {
    if (entity && getEntitySuccess) {
      // @ts-expect-error null vs. undefined not playing nicely
      form.reset(entity)
    }
  }, [entity])

  async function onSubmit(values: z.infer<typeof entitySchema>) {
    console.log('onSubmit values', values)
    const isValid = await form.trigger() // Manually trigger validation
    if (isValid) {
      const values = form.getValues() // Get current form values
      console.log('Form is valid, triggering submission:', values)
      await updateEntity({ id: entity?.id as string, ...values })
    } else {
      console.log('form not valid', form)
    }
  }

  const handleChange = async () => {
    onSubmit(form.getValues()) // Manually call onSubmit after validation passes
  }

  return (
    <>
      <FormProvider {...form}>
        <form
          onBlur={form.handleSubmit(onSubmit)} // Trigger submission on blur as fallback
        >
          <div className="flex flex-col gap-1">
            <SyncedTextInput
              className="pl-0 font-bold"
              fieldName="name"
              form={form} // Provided by FormProvider context
              handleChange={handleChange} // Handled internally by SyncedForm
              triggerOnChange={true} // Triggers submission on each change
            />
            <Separator />
            <p className="text-sm">Position</p>
            <SyncedVec3Input
              className="pl-1"
              fieldName="local_position"
              form={form} // Provided by FormProvider context
              handleChange={handleChange} // Handled internally by SyncedForm
              triggerOnChange={true} // Triggers submission on each change
            />
            <p className="text-sm">Will be vec4</p>
            {/* <p className="text-sm">Rotation</p>
            <SyncedVec3Input
              className="pl-1"
              fieldNameX="local_rotationX"
              fieldNameY="local_rotationY"
              fieldNameZ="local_rotationZ"
              form={form} // Provided by FormProvider context
              handleChange={handleChange} // Handled internally by SyncedForm
              triggerOnChange={true} // Triggers submission on each change
            /> */}
            <p className="text-sm">Scale</p>
            <SyncedVec3Input
              className="pl-1"
              fieldName="local_scale"
              form={form} // Provided by FormProvider context
              handleChange={handleChange} // Handled internally by SyncedForm
              triggerOnChange={true} // Triggers submission on each change
            />
          </div>
        </form>
      </FormProvider>
    </>
  )
}
