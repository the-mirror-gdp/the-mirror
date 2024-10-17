import * as React from 'react'
import { SingleSelect } from '@/components/ui/single-select'
import { SyncedFormField } from '@/components/ui/synced-inputs/synced-form-field'
import clsx from 'clsx'

interface SyncedSingleSelectProps<T> {
  fieldName: string
  form: any
  options: { label: string; value: string }[]
  placeholder?: string
  handleChange: () => void
  className?: string
  triggerOnChange?: boolean
}

export function SyncedSingleSelect<T>({
  fieldName,
  form,
  options,
  placeholder = 'Select option',
  handleChange,
  className,
  triggerOnChange = true
}: SyncedSingleSelectProps<T>) {
  return (
    <SyncedFormField
      fieldName={fieldName}
      form={form}
      handleChange={handleChange}
      className={clsx('form-single-select', className)}
      triggerOnChange={triggerOnChange}
      renderComponent={(field, fieldName) => (
        <>
          <SingleSelect
            options={options}
            form={form}
            fieldName={fieldName}
            handleChange={(value) => {
              field.onChange(value) // Update form state with selected value
              // if (triggerOnChange) {
              //   handleChange()
              // }
            }}
            placeholder={placeholder}
          />
        </>
      )}
    />
  )
}
