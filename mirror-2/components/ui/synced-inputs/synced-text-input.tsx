import { Input } from '@/components/ui/input'
import { SyncedFormField } from '@/components/ui/synced-inputs/synced-form-field'
import clsx from 'clsx'

interface SyncedTextInputProps<T> {
  fieldName: keyof T
  form: any
  handleChange: () => void
  className?: string
  triggerOnChange?: boolean
  placeholder?: any
}

export function SyncedTextInput<T>({
  fieldName,
  form,
  handleChange,
  className,
  triggerOnChange = false,
  placeholder
}: SyncedTextInputProps<T>) {
  return (
    <SyncedFormField
      fieldName={fieldName}
      form={form}
      handleChange={handleChange}
      className={className}
      triggerOnChange={triggerOnChange}
      renderComponent={(field, fieldName) => (
        <Input
          {...field} // Sync field with react-hook-form
          placeholder={placeholder}
          className={clsx('form-input', className)} // Add necessary styles and classes
          type="text"
          autoComplete="off"
        />
      )}
    />
  )
}
