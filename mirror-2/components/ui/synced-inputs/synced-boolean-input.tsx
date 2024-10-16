import { SyncedFormField } from '@/components/ui/synced-inputs/synced-form-field'
import clsx from 'clsx'

interface SyncedBooleanInputProps<T> {
  fieldName: keyof T
  form: any
  handleChange: () => void
  className?: string
  triggerOnChange?: boolean
  label?: string // Optional label for the checkbox
}

export function SyncedBooleanInput<T>({
  fieldName,
  form,
  handleChange,
  className,
  triggerOnChange = false,
  label
}: SyncedBooleanInputProps<T>) {
  return (
    <SyncedFormField
      fieldName={fieldName}
      form={form}
      handleChange={handleChange}
      className={className}
      triggerOnChange={triggerOnChange}
      renderComponent={(field, fieldName) => (
        <div className={clsx('form-control', className)}>
          <label className="flex items-center space-x-3">
            <input
              type="checkbox"
              {...field} // Sync field with react-hook-form
              checked={field.value || false} // Ensure the field is treated as a boolean
              onChange={(e) => {
                field.onChange(e.target.checked) // Update the form with the boolean value
                if (triggerOnChange) {
                  handleChange()
                }
              }}
              className="form-checkbox h-5 w-5 text-primary focus:ring-primary"
            />
            {label && <span>{label}</span>}
          </label>
        </div>
      )}
    />
  )
}
