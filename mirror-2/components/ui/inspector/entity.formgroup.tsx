'use client'
import { entitySchema } from '@/components/engine/schemas/entity.schema'
import { FormProvider } from '@/components/ui/form'
import { Separator } from '@/components/ui/separator'
import { SyncedTextInput } from '@/components/ui/synced-inputs/synced-text-input'
import { SyncedVec3Input } from '@/components/ui/synced-inputs/synced-vec3-input'
import { DatabaseEntity, useUpdateEntityMutation } from '@/state/api/entities'
import { convertVecNumbersToIndividual } from '@/utils/utils'
import { zodResolver } from '@hookform/resolvers/zod'
import { useForm } from 'react-hook-form'
import { z } from 'zod'

export function EntityFormGroup({ entity }: { entity: DatabaseEntity }) {
  const [updateEntity, { isLoading: isUpdating, isSuccess: isUpdated, error }] =
    useUpdateEntityMutation()

  const vecKeys = ['local_position', 'local_rotation', 'local_scale']

  const form = useForm<z.infer<typeof entitySchema>>({
    resolver: zodResolver(entitySchema),
    mode: 'onBlur',
    defaultValues: {
      ...entity,
      ...vecKeys.reduce((acc, key) => {
        return {
          ...acc,
          ...convertVecNumbersToIndividual(entity, key)
        }
      }, {})
    }
  })

  async function onSubmit(values: z.infer<typeof entitySchema>) {
    // Handle conversion to number if convertSubmissionToNumber is true
    // if (convertSubmissionToNumber) {
    //   const convertedValue = Number(values[fieldName]) // Convert to number
    //   if (isNaN(convertedValue)) {
    //     console.error('Invalid number input')
    //     return
    //   }
    //   values = { ...values, [fieldName]: convertedValue } // Update values with the converted number
    // }
    vecKeys.forEach((key) => {
      values[key] = [values[`${key}X`], values[`${key}Y`], values[`${key}Z`]]
      delete values[`${key}X`]
      delete values[`${key}Y`]
      delete values[`${key}Z`]
      delete values[`${key}W`]
    })
    console.log('onSubmit values', values)
    // const convertedValues = convertIndividualToVecNumbers(values)
    // console.log('convertedValues', convertedValues)
    // @ts-ignore
    await updateEntity({ id: entity.id, ...values })
  }

  // Reset the form when the entity data is successfully fetched
  // useEffect(() => {
  //   if (entity) {
  //     // defaultValueToSet =
  //     //   genericEntity?.[fieldName] !== undefined
  //     //     ? genericEntity[fieldName]
  //     //     : defaultValue

  //     form.reset()
  //   }
  // }, [genericEntity, isSuccess, form])

  const handleChange = async () => {
    console.log('Form test, vallues:', form.getValues())
    const isValid = await form.trigger([
      'local_positionX',
      'local_positionY',
      'local_positionZ'
    ]) // Manually trigger validation
    console.log('fieldstate', form.getFieldState('local_positionX'))
    console.log('fieldstate', form.getFieldState('local_positionY'))
    console.log('fieldstate', form.getFieldState('local_positionZ'))
    if (isValid) {
      const values = form.getValues() // Get current form values
      console.log('Form is valid, triggering submission:', values)
      onSubmit(values) // Manually call onSubmit after validation passes
    } else {
      console.log('form not valid', form)
    }
  }

  // Display loading state if data is still being fetched
  // if (isLoading) {
  //   return (
  //     <Skeleton
  //       className={cn(
  //         'w-full dark:bg-transparent border-none text-lg shadow-none'
  //       )}
  //     />
  //   )
  // }

  return (
    <>
      <FormProvider {...form}>
        <form
          onBlur={form.handleSubmit(onSubmit)} // Trigger submission on blur as fallback
          onSubmit={(values) => console.log('Submitted values:', values)}
        >
          <div className="flex flex-col gap-1">
            <SyncedTextInput
              className="pl-0"
              fieldName="name"
              form={form} // Provided by FormProvider context
              handleChange={handleChange} // Handled internally by SyncedForm
              triggerOnChange={true} // Triggers submission on each change
            />
            <Separator />
            <p className="text-sm">Position</p>
            <SyncedVec3Input
              className="pl-1"
              fieldNameX="local_positionX"
              fieldNameY="local_positionY"
              fieldNameZ="local_positionZ"
              form={form} // Provided by FormProvider context
              handleChange={handleChange} // Handled internally by SyncedForm
              triggerOnChange={true} // Triggers submission on each change
            />
            <p className="text-sm">Rotation</p>
            <SyncedVec3Input
              className="pl-1"
              fieldNameX="local_rotationX"
              fieldNameY="local_rotationY"
              fieldNameZ="local_rotationZ"
              form={form} // Provided by FormProvider context
              handleChange={handleChange} // Handled internally by SyncedForm
              triggerOnChange={true} // Triggers submission on each change
            />
            <p className="text-sm">Scale</p>
            <SyncedVec3Input
              className="pl-1"
              fieldNameX="local_scaleX"
              fieldNameY="local_scaleY"
              fieldNameZ="local_scaleZ"
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
