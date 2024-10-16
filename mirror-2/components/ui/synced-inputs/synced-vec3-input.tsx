import { Input } from '@/components/ui/input'
import { SyncedFormField } from '@/components/ui/synced-inputs/synced-form-field'
import { AxisLabelCharacter } from '@/components/ui/text/axis-label-character'
import { cn } from '@/utils/cn'
import clsx from 'clsx'
import { useFieldArray, useForm } from 'react-hook-form'

interface SyncedVec3InputProps<T> {
  fieldNameX: string
  fieldNameY: string
  fieldNameZ: string
  form: any
  handleChange: () => void
  className?: string
  triggerOnChange?: boolean
}

export function SyncedVec3Input<T>({
  fieldNameX,
  fieldNameY,
  fieldNameZ,
  form,
  handleChange,
  className,
  triggerOnChange = false
}: SyncedVec3InputProps<T>) {
  // TODO could be refactored to use useFieldArray, but felt like a massive pain and waste of time with shadcn's defaults of abstracting the rhf <Controller out already. Not worth the time at the moment. Tried on a /save branch and it was buggy, timebox expired

  return (
    <div className={cn('flex', className)}>
      <SyncedFormField
        fieldName={fieldNameX}
        form={form}
        handleChange={handleChange}
        triggerOnChange={triggerOnChange}
        renderComponent={(field, fieldName) => (
          <>
            <div className="flex items-center space-x-2">
              <AxisLabelCharacter axis={'x'} className="my-auto mr-3" />
              <Input
                type="number"
                autoComplete="off"
                className={cn(
                  'dark:bg-transparent px-1 py-0 pb-1 border-none shadow-none text-lg text-white'
                )}
                {...field}
                onChange={(e) => {
                  field.onChange(parseFloat(e.target.value)) // Convert to number before updating form state
                  if (triggerOnChange) {
                    handleChange() // Notify the form if changes should trigger submission
                  }
                }}
              />
            </div>
          </>
        )}
      />
      <SyncedFormField
        fieldName={fieldNameY}
        form={form}
        handleChange={handleChange}
        triggerOnChange={triggerOnChange}
        renderComponent={(field, fieldName) => (
          <>
            <div className="flex items-center space-x-2">
              <AxisLabelCharacter axis={'y'} className="my-auto mr-3" />
              <Input
                type="number"
                autoComplete="off"
                className={cn(
                  'dark:bg-transparent px-1 py-0 pb-1 border-none shadow-none text-lg text-white'
                )}
                {...field}
              />
            </div>
          </>
        )}
      />
      <SyncedFormField
        fieldName={fieldNameZ}
        form={form}
        handleChange={handleChange}
        triggerOnChange={triggerOnChange}
        renderComponent={(field, fieldName) => (
          <>
            <div className="flex items-center space-x-2">
              <AxisLabelCharacter axis={'z'} className="my-auto mr-3" />
              <Input
                type="number"
                autoComplete="off"
                className={cn(
                  'dark:bg-transparent px-1 py-0 pb-1 border-none shadow-none text-lg text-white'
                )}
                {...field}
              />
            </div>
          </>
        )}
      />
    </div>
  )
}
