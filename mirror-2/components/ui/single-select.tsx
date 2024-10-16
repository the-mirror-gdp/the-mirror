import * as React from 'react'
import { SyncedFormField } from '@/components/ui/synced-inputs/synced-form-field'
import {
  Popover,
  PopoverTrigger,
  PopoverContent
} from '@/components/ui/popover'
import { CheckIcon, ChevronDown } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'
import {
  Command,
  CommandGroup,
  CommandItem,
  CommandInput,
  CommandList,
  CommandEmpty
} from '@/components/ui/command'

interface SingleSelectProps<T> {
  options: {
    label: string
    value: string
  }[]
  placeholder?: string
  defaultValue?: string
  handleChange: (value: string) => void
  className?: string
}

export const SingleSelect = React.forwardRef<
  HTMLButtonElement,
  SingleSelectProps<any>
>(
  (
    {
      options,
      defaultValue,
      handleChange,
      placeholder = 'Select Option',
      className,
      ...props
    },
    ref
  ) => {
    const [selectedValue, setSelectedValue] = React.useState<
      string | undefined
    >(defaultValue)
    const [isPopoverOpen, setIsPopoverOpen] = React.useState(false)

    const toggleOption = (option: string) => {
      setSelectedValue(option)
      handleChange(option)
      setIsPopoverOpen(false) // Close the popover on selection
    }

    return (
      <Popover open={isPopoverOpen} onOpenChange={setIsPopoverOpen}>
        <PopoverTrigger asChild>
          <Button
            ref={ref}
            {...props}
            onClick={() => setIsPopoverOpen((prev) => !prev)}
            className={cn(
              'flex w-full p-1 rounded-md border min-h-10 h-auto items-center justify-between bg-inherit hover:bg-inherit',
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
    )
  }
)

SingleSelect.displayName = 'SingleSelect'
