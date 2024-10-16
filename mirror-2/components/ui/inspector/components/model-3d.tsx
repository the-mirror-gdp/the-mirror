import { FormProvider, useForm, useFormContext } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'

import { SyncedTextInput } from '@/components/ui/synced-inputs/synced-text-input'

import { SyncedMultiSelect } from '@/components/ui/synced-inputs/synced-multi-select'
import { SyncedSingleSelect } from '@/components/ui/synced-inputs/synced-single-select'
import { SyncedVec3Input } from '@/components/ui/synced-inputs/synced-vec3-input'
import { render3DModelSchema } from '@/components/engine/schemas/component.schemas'
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
import { ComponentType } from '@/components/engine/schemas/components-types'
import { convertVecNumbersToIndividual } from '@/utils/utils'
import { useEffect } from 'react'

export default function Model3DRenderFormGroup({ entity }) {
  const componentKey = ComponentType.Model3D
  const components = { ...entity.components[componentKey] }
  const [
    updateComponent,
    { isLoading: isUpdating, isSuccess: isUpdated, error }
  ] = useUpdateComponentOnEntityMutation()

  // The useGetSingleEntityQuery may seem odd to use this here instead of passing props, but this helps with rerendering. It was a huge pain earlier with not rerendering correctly since we're working with nested data
  // const currentEntity = useAppSelector(selectCurrentEntity)
  // const { data: entity } = useGetSingleEntityQuery(
  //   currentEntity?.id || skipToken
  // )
  const vecKeys = ['aabbCenter', 'aabbHalfExtents']
  const defaultValues = {
    ...components,
    ...vecKeys.reduce((acc, key) => {
      if (components[key]) {
        return {
          ...acc,
          ...convertVecNumbersToIndividual(components, key)
        }
      }
      return acc
    }, {})
  }

  const form = useForm({
    resolver: zodResolver(render3DModelSchema),
    defaultValues
  })

  async function onSubmit(values: z.infer<typeof render3DModelSchema>) {
    vecKeys.forEach((key) => {
      values[key] = [values[`${key}X`], values[`${key}Y`], values[`${key}Z`]]
      delete values[`${key}X`]
      delete values[`${key}Y`]
      delete values[`${key}Z`]
      delete values[`${key}W`]
    })
    console.log('onSubmit values', values)
    if (entity) {
      await updateComponent({
        id: entity.id,
        componentKey: componentKey,
        updatedComponentData: values
      })
    }
  }

  const handleChange = async () => {
    console.log('Form test, values:', form.getValues())
    const isValid = await form.trigger([]) // Manually trigger validation
    if (isValid) {
      const values = form.getValues() // Get current form values
      console.log('Form is valid, triggering submission:', values)
      onSubmit(values) // Manually call onSubmit after validation passes
    } else {
      console.log('form not valid', form)
    }
  }

  const { watch } = form
  const typeValue = watch('type')
  const lightmappedValue = watch('lightmapped')
  const customAabbValue = watch('customAabb')

  return (
    <FormProvider {...form}>
      <form
        onBlur={form.handleSubmit(onSubmit)} // Trigger submission on blur as fallback
        onSubmit={(values) => console.log('Submitted values:', values)}
      >
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
          options={[
            { label: 'Box', value: 'Box' },
            { label: 'Sphere', value: 'Sphere' },
            { label: 'Cylinder', value: 'Cylinder' }
          ]}
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
              fieldNameX="aabbCenterX"
              fieldNameY="aabbCenterY"
              fieldNameZ="aabbCenterZ"
              form={form}
              handleChange={handleChange}
              triggerOnChange={true}
            />
            <SyncedVec3Input
              fieldNameX="aabbHalfExtentsX"
              fieldNameY="aabbHalfExtentsY"
              fieldNameZ="aabbHalfExtentsZ"
              form={form}
              handleChange={handleChange}
              triggerOnChange={true}
            />
          </>
        )}
      </form>
    </FormProvider>
  )
}
