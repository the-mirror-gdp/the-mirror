import { Checkbox } from '@/components/ui/checkbox'
import { SyncedFormField } from '@/components/ui/synced-inputs/synced-form-field'
import clsx from 'clsx'

interface SyncedBooleanInputProps<T> {
  fieldName: string
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
  triggerOnChange = true,
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
            <Checkbox
              checked={field.value || false} // Ensure the field is treated as a boolean
              onCheckedChange={(newValue) => {
                field.onChange(newValue) // Update the form with the boolean value
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
