import { forwardRef, useEffect, useState } from 'react'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'
import {
  Popover,
  PopoverTrigger,
  PopoverContent
} from '@/components/ui/popover'
import {
  Command,
  CommandGroup,
  CommandItem,
  CommandInput,
  CommandList,
  CommandEmpty
} from '@/components/ui/command'
import { CheckIcon, ChevronDown } from 'lucide-react'

interface SingleSelectProps<T> {
  options: {
    label: string
    value: string
  }[]
  placeholder?: string
  handleChange: (value: string) => void
  className?: string
  form: any
  fieldName: any
}

export const SingleSelect = forwardRef<
  HTMLButtonElement,
  SingleSelectProps<any>
>(
  (
    {
      options,
      handleChange,
      placeholder = 'Select Option',
      className,
      form,
      fieldName,
      ...props
    },
    ref
  ) => {
    const [selectedValue, setSelectedValue] = useState<string | undefined>()

    useEffect(() => {
      const defaultValue = form.getValues(fieldName)
      setSelectedValue(defaultValue)
    }, [form, fieldName])

    const [isPopoverOpen, setIsPopoverOpen] = useState(false)

    const toggleOption = (option: string) => {
      setSelectedValue(option)
      handleChange(option)
      setIsPopoverOpen(false) // Close the popover on selection
    }

    return (
      <>
        <Popover open={isPopoverOpen} onOpenChange={setIsPopoverOpen}>
          <PopoverTrigger asChild>
            <Button
              ref={ref}
              {...props}
              onClick={() => setIsPopoverOpen((prev) => !prev)}
              className={cn(
                'flex w-full p-1 rounded-md  min-h-10 h-auto items-center justify-between bg-inherit hover:bg-inherit',
                className
              )}
            >
              {selectedValue ? (
                <span className="mx-3 text-sm">
                  {options.find((opt) => opt.value === selectedValue)?.label}
                </span>
              ) : (
                <span className="mx-3 text-sm text-muted-foreground">
                  {placeholder}
                </span>
              )}
              <ChevronDown className="h-4 w-4 mx-2 text-muted-foreground" />
            </Button>
          </PopoverTrigger>
          <PopoverContent className="w-auto p-0" align="start">
            <Command>
              <CommandInput placeholder="Search..." />
              <CommandList>
                <CommandEmpty>No results found.</CommandEmpty>
                <CommandGroup>
                  {options.map((option) => (
                    <CommandItem
                      key={option.value}
                      onSelect={() => toggleOption(option.value)}
                      className="cursor-pointer"
                    >
                      <div
                        className={cn(
                          'mr-2 flex h-4 w-4 items-center justify-center rounded-sm border border-primary',
                          selectedValue === option.value
                            ? 'bg-primary text-primary-foreground'
                            : 'opacity-50 [&_svg]:invisible'
                        )}
                      >
                        <CheckIcon className="h-4 w-4" />
                      </div>
                      <span>{option.label}</span>
                    </CommandItem>
                  ))}
                </CommandGroup>
              </CommandList>
            </Command>
          </PopoverContent>
        </Popover>
      </>
    )
  }
)

SingleSelect.displayName = 'SingleSelect'
