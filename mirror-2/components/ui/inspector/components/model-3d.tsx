import { FormProvider, useForm, useFormContext } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'

import { SyncedTextInput } from '@/components/ui/synced-inputs/synced-text-input'

import { SyncedMultiSelect } from '@/components/ui/synced-inputs/synced-multi-select'
import { SyncedSingleSelect } from '@/components/ui/synced-inputs/synced-single-select'
import { SyncedVec3Input } from '@/components/ui/synced-inputs/synced-vec3-input'
import {
  Render3DModel,
  Render3DModelTypeValues,
  render3DModelSchema,
  render3DModelSchemaDefaultValues
} from '@/components/engine/schemas/component.schemas'
import { SyncedBooleanInput } from '@/components/ui/synced-inputs/synced-boolean-input'
import {
  DatabaseEntity,
  useGetSingleEntityQuery,
  useUpdateComponentOnEntityMutation
} from '@/state/api/entities'
import { selectCurrentEntity } from '@/state/local.slice'
import { useAppSelector } from '@/hooks/hooks'
import { skipToken } from '@reduxjs/toolkit/query'
import { z } from 'zod'

import { useEffect } from 'react'
import * as pc from 'playcanvas'
import { ComponentType } from '@/components/engine/schemas/component-type'

export default function Model3DRenderFormGroup() {
  const currentEntityForId = useAppSelector(selectCurrentEntity)
  // The useGetSingleEntityQuery may seem odd to use this here instead of passing props, but this helps with rerendering and ensuring having latest updated state since RTK manages cache. It was a huge pain earlier with not rerendering correctly since we're working with nested date
  const { data: entity, isSuccess: getEntitySuccess } = useGetSingleEntityQuery(
    currentEntityForId?.id || skipToken
  )
  const componentKey = ComponentType.Model3D
  const components =
    entity && entity.components ? { ...entity.components[componentKey] } : {}
  const [
    updateComponentOnEntity,
    { isLoading: isUpdating, isSuccess: isUpdated, error }
  ] = useUpdateComponentOnEntityMutation()

  const form = useForm<Render3DModel>({
    resolver: zodResolver(render3DModelSchema),
    mode: 'onBlur',
    defaultValues: render3DModelSchemaDefaultValues
  })

  useEffect(() => {
    if (entity && entity.components && getEntitySuccess) {
      // use safeParse to only reset the form with the values IF it matches the schema. Keeps data integrity
      const newData = entity.components[componentKey]
      const parseResult = render3DModelSchema.safeParse(newData)
      if (parseResult.success) {
        console.log('setting 3D model form data', newData)
        form.reset(newData)
      } else {
        // debugger // temp
      }
    }
  }, [entity, getEntitySuccess, form])

  async function onSubmit(v: z.infer<typeof render3DModelSchema>) {
    const validation = render3DModelSchema.safeParse(form.getValues())
    if (entity && validation.success) {
      const values = validation.data
      await updateComponentOnEntity({
        id: entity.id,
        componentKey: componentKey,
        updatedComponentData: values
      })
    }
  }

  const handleChange = async () => {
    onSubmit(form.getValues())
  }

  const { watch } = form
  const typeValue = watch('type')
  const lightmappedValue = watch('lightmapped')
  const customAabbValue = watch('customAabb')

  return (
    <FormProvider {...form}>
      <form
        // onBlur={form.handleSubmit(onSubmit)} // Trigger submission on blur as fallback
        onSubmit={(values) => console.log('Submitted values:', values)}
      >
        <div className="flex flex-col gap-2">
          {/* Enabled */}
          <SyncedBooleanInput
            fieldName="enabled"
            form={form}
            handleChange={handleChange}
            label="Enabled"
          />

          {/* Type */}
          {/* <SyncedTextInput
          fieldName="type"
          form={form}
          handleChange={handleChange}
          placeholder="Type"
        /> */}
          <SyncedSingleSelect
            fieldName="type"
            form={form}
            options={Render3DModelTypeValues.map(({ displayName, value }) => ({
              label: displayName, // Map displayName to label
              value: value
            }))}
            handleChange={handleChange}
            placeholder="Select Type"
          />

          {/* Asset (only show if type == 'asset') */}
          {typeValue === 'asset' && (
            <SyncedTextInput
              fieldName="asset"
              form={form}
              handleChange={handleChange}
              placeholder="Asset"
            />
          )}

          {/* Material Assets */}
          <SyncedMultiSelect
            fieldName="materialAssets"
            form={form}
            options={[
              { label: 'Material 1', value: '1' },
              { label: 'Material 2', value: '2' },
              { label: 'Material 3', value: '3' }
            ]}
            handleChange={handleChange}
            placeholder="Select material assets"
          />

          {/* Layers (Multi Select) */}
          <SyncedMultiSelect
            fieldName="layers"
            form={form}
            options={[
              { label: 'Material 1', value: '1' },
              { label: 'Material 2', value: '2' },
              { label: 'Material 3', value: '3' }
            ]}
            handleChange={handleChange}
            placeholder="Select layers"
          />

          {/* Batch Group Id (Single Select) */}
          <SyncedSingleSelect
            fieldName="batchGroupId"
            form={form}
            options={[
              { label: 'Material 1', value: '1' },
              { label: 'Material 2', value: '2' },
              { label: 'Material 3', value: '3' }
            ]}
            handleChange={handleChange}
            placeholder="Select batch group"
          />

          {/* Cast Shadows */}
          <SyncedBooleanInput
            fieldName="castShadows"
            form={form}
            handleChange={handleChange}
            label="Cast Shadows"
          />

          {/* Cast Shadows Lightmap */}
          <SyncedBooleanInput
            fieldName="castShadowsLightmap"
            form={form}
            handleChange={handleChange}
            label="Cast Shadows Lightmap"
          />

          {/* Receive Shadows */}
          <SyncedBooleanInput
            fieldName="receiveShadows"
            form={form}
            handleChange={handleChange}
            label="Receive Shadows"
          />

          {/* Lightmapped */}
          <SyncedBooleanInput
            fieldName="lightmapped"
            form={form}
            handleChange={handleChange}
            label="Lightmapped"
          />

          {/* Lightmap Size Multiplier (only show if lightmapped is true) */}
          {lightmappedValue && (
            <SyncedTextInput
              fieldName="lightmapSizeMultiplier"
              form={form}
              handleChange={handleChange}
              placeholder="Lightmap Size Multiplier"
            />
          )}

          {/* Is Static */}
          <SyncedBooleanInput
            fieldName="isStatic"
            form={form}
            handleChange={handleChange}
            label="Is Static"
          />

          {/* Custom AABB */}
          <SyncedBooleanInput
            fieldName="customAabb"
            form={form}
            handleChange={handleChange}
            label="Custom AABB"
          />

          {/* AABB Fields (only show if customAabb is true) */}
          {customAabbValue && (
            <>
              <SyncedVec3Input
                fieldName="aabbCenter"
                form={form}
                handleChange={handleChange}
                triggerOnChange={true}
              />
              <SyncedVec3Input
                fieldName="aabbHalfExtents"
                form={form}
                handleChange={handleChange}
                triggerOnChange={true}
              />
            </>
          )}
        </div>
      </form>
    </FormProvider>
  )
}
