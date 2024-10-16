import { Input } from '@/components/ui/input'
import { SyncedFormField } from '@/components/ui/synced-inputs/synced-form-field'
import { AxisLabelCharacter } from '@/components/ui/text/axis-label-character'
import clsx from 'clsx'

interface SyncedVec3InputProps<T> {
  fieldName: string
  form: any
  handleChange: () => void
  className?: string
  triggerOnChange?: boolean
}

export function SyncedVec3Input<T>({
  fieldName,
  form,
  handleChange,
  className,
  triggerOnChange = false
}: SyncedVec3InputProps<T>) {
  const { register } = form

  return (
    <div className={clsx('flex', className)}>
      {['x', 'y', 'z'].map((axis, index) => (
        <div key={axis} className="flex items-center space-x-2">
          <AxisLabelCharacter
            axis={axis as 'x' | 'y' | 'z'}
            className="my-auto mr-3"
          />
          <SyncedFormField
            fieldName={`${fieldName}.${index}`}
            form={form}
            handleChange={handleChange}
            className={clsx(
              'dark:bg-transparent px-1 py-0 pb-1 border-none shadow-none text-lg text-white'
            )}
            triggerOnChange={triggerOnChange}
            renderComponent={() => (
              <Input
                {...register(`${fieldName}.${index}`)} // Register each input with react-hook-form
                className={clsx('form-input', className)}
                type="number"
                autoComplete="off"
              />
            )}
          />
        </div>
      ))}
    </div>
  )
}
