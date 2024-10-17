import * as React from 'react'

import { SyncedFormField } from '@/components/ui/synced-inputs/synced-form-field'
import clsx from 'clsx'
import { MultiSelect } from '@/components/ui/multi-select'

interface SyncedMultiSelectProps<T> {
  fieldName: string
  form: any
  options: { label: string; value: string }[]
  placeholder?: string
  maxCount?: number
  handleChange: () => void
  className?: string
  triggerOnChange?: boolean
  animation?: number
}

export function SyncedMultiSelect<T>({
  fieldName,
  form,
  options,
  placeholder = 'Select Options',
  maxCount = 3,
  handleChange,
  className,
  triggerOnChange = true,
  animation = 0
}: SyncedMultiSelectProps<T>) {
  return (
    <SyncedFormField
      fieldName={fieldName}
      form={form}
      handleChange={handleChange}
      className={clsx('form-multiselect', className)}
      triggerOnChange={triggerOnChange}
      renderComponent={(field, fieldName) => (
        <MultiSelect
          options={options}
          fieldName={fieldName}
          form={form}
          defaultValue={field.value || []} // Bind the selected values to form state
          handleChange={(values) => {
            field.onChange(values) // Update form state with selected values
            if (triggerOnChange) {
              handleChange()
            }
          }}
          placeholder={placeholder}
          maxCount={maxCount}
          animation={animation}
        />
      )}
    />
  )
}
