'use client'
import {
  FormControl,
  FormField,
  FormItem,
  FormMessage
} from '@/components/ui/form'

interface SyncedFormFieldProps<T> {
  form: any
  handleChange: () => void
  fieldName: string
  renderComponent: (field: any, fieldName: string) => JSX.Element // Function to dynamically render input component
  triggerOnChange?: boolean // triggers the form component on change. Use for booleans or specific cases.
  className?: string // Optional className prop
}

export function SyncedFormField<T>({
  fieldName,
  form,
  className,
  renderComponent,
  handleChange,
  triggerOnChange = false
}: SyncedFormFieldProps<T>) {
  return (
    <FormField
      control={form.control} // Connect the field with react-hook-form control
      name={fieldName as string} // The name of the field to match with form schema
      render={({ field }) => (
        <FormItem>
          <FormControl>
            {/* Here we use renderComponent to render the actual input element */}
            {renderComponent &&
              renderComponent(
                {
                  ...field, // Spread all necessary field props
                  onChange: (e) => {
                    field.onChange(e) // Update form state on change
                    if (triggerOnChange) {
                      handleChange() // Trigger form submission if needed
                    }
                  },
                  onBlur: () => {
                    handleChange() // Trigger form submission on blur
                  }
                },
                fieldName as string
              )}
          </FormControl>
          <FormMessage /> {/* Display validation messages */}
        </FormItem>
      )}
    />
  )
}
