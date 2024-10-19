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
import { zodResolver } from '@hookform/resolvers/zod'
import { skipToken } from '@reduxjs/toolkit/query'
import { useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { z } from 'zod'
import * as pc from 'playcanvas'
import { TextInputPcTwoWay } from '@/components/ui/synced-inputs/new-with-pc-ui/text-input-pc-two-way'
import { getJsonPathForObserverStructure } from '@/components/engine/space-engine-non-game-context'

export function EntityFormGroup() {
  const currentEntityForId = useAppSelector(selectCurrentEntity)
  const { data: entity, isSuccess: getEntitySuccess } = useGetSingleEntityQuery(
    currentEntityForId?.id || skipToken
  )
  const [updateEntity, { isLoading: isUpdating, isSuccess: isUpdated, error }] =
    useUpdateEntityMutation()

  const form = useForm<z.infer<typeof entitySchema>>({
    resolver: zodResolver(entitySchema),
    mode: 'onChange',
    defaultValues: entitySchemaUiFormDefaultValues,
    // values: <- dont do this here, use the useEffect so we have control over resets. Otherwise, weird behavior.
    resetOptions: {
      keepDefaultValues: true,
      keepDirtyValues: true
    }
  })

  // handle form reset on entity update
  useEffect(() => {
    if (entity && getEntitySuccess) {
      // Convert quaternion to Euler angles
      const quaternion = new pc.Quat(
        entity.local_rotation[0],
        entity.local_rotation[1],
        entity.local_rotation[2],
        entity.local_rotation[3]
      )
      const eulerAngles = new pc.Vec3()
      quaternion.getEulerAngles(eulerAngles)
      eulerAngles.x = (eulerAngles.x + 360) % 360
      eulerAngles.y = (eulerAngles.y + 360) % 360
      eulerAngles.z = (eulerAngles.z + 360) % 360

      // Prepare the entity with Euler angles for form reset
      const local_rotation_euler: [number, number, number] = [
        Number(eulerAngles.x.toFixed(2)),
        Number(eulerAngles.y.toFixed(2)),
        Number(eulerAngles.z.toFixed(2))
      ]
      const entityWithEuler = {
        ...entity,
        local_rotation_euler
      }
      // TODO update this with a safeParse (see model-3d component)
      form.reset(entityWithEuler)
    }
  }, [entity, getEntitySuccess, form])

  async function onSubmit(v: z.infer<typeof entitySchema>) {
    const validation = entitySchema.safeParse(v)

    // const isValid = await form.trigger() // FYI: NOT working. use safeParse instead
    if (validation.success) {
      const values = validation.data
      console.log('onSubmit validated values', values)
      // Convert local_rotation from Euler angles to a quaternion
      const convertToFixedArray = (angles: number[], precision: number) => {
        return angles.map((angle) => {
          if (!angle.toFixed) {
            debugger
          }
          return Number(angle.toFixed(precision))
        })
      }
      const eulerAnglesArray = convertToFixedArray(
        values.local_rotation_euler,
        10
      )
      const eulerAngles = new pc.Vec3(
        eulerAnglesArray[0],
        eulerAnglesArray[1],
        eulerAnglesArray[2]
      )
      const quaternion = new pc.Quat()
      quaternion.setFromEulerAngles(eulerAngles)
      const quaternionArray: [number, number, number, number] = [
        quaternion.x,
        quaternion.y,
        quaternion.z,
        quaternion.w
      ]

      const updatedValues = {
        ...values,
        local_rotation: quaternionArray,
        local_rotation_euler: undefined
      }

      console.log('Form is valid, updating entity:', updatedValues)
      await updateEntity({ id: entity?.id as string, ...updatedValues })
    } else {
      console.log('form not valid', form)
    }
  }

  const handleChange = async () => {
    onSubmit(form.getValues()) // Manually call onSubmit after validation passes
  }

  return (
    <>
      {entity && (
        <>
          {/* <FormProvider {...form}>
            <form
              onBlur={form.handleSubmit(onSubmit)} // Trigger submission on blur as fallback
            > */}
          <div className="flex flex-col gap-1">
            {/* <SyncedTextInput
              className="pl-0 font-bold"
              fieldName="name"
              form={form} // Provided by FormProvider context
              handleChange={handleChange} // Handled internally by SyncedForm
              triggerOnChange={true} // Triggers submission on each change
              /> */}
            <TextInputPcTwoWay
              path={getJsonPathForObserverStructure(entity.id, 'name')}
              entityId={entity.id}
              className="pl-0 font-bold"
              schema={entitySchema.pick({
                name: true
              })}
              schemaFieldName={'name'}
            />
            <Separator />
            <p className="text-sm">Position</p>
            {/* <SyncedVec3Input
              className="pl-1"
              fieldName="local_position"
              form={form} // Provided by FormProvider context
              handleChange={handleChange} // Handled internally by SyncedForm
              triggerOnChange={true} // Triggers submission on each change
            />
            <p className="text-sm">Rotation</p>
            <SyncedVec3Input
              className="pl-1"
              fieldName="local_rotation_euler"
              form={form} // Provided by FormProvider context
              handleChange={handleChange} // Handled internally by SyncedForm
              triggerOnChange={true} // Triggers submission on each change
            />
            <p className="text-sm">Scale</p>
            <SyncedVec3Input
              className="pl-1"
              fieldName="local_scale"
              form={form} // Provided by FormProvider context
              handleChange={handleChange} // Handled internally by SyncedForm
              triggerOnChange={true} /> // Triggers submission on each change */}
          </div>
          {/* </form>
          </FormProvider> */}
        </>
      )}
    </>
  )
}
