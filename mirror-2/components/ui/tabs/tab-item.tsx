// TabItem.tsx
import { ReactNode } from 'react'
import { cn } from '@/utils/cn'
import { getLongestDisplayName } from '@/components/engine/schemas/components-types'

interface TabItemProps {
  isActive?: boolean
  isDisabled?: boolean
  icon: ReactNode
  label: string
  onClick
}

export function TabItem({
  isActive = false,
  isDisabled = false,
  icon,
  label,
  onClick
}: TabItemProps) {
  const baseClasses =
    'flex flex-auto text-center justify-center items-center pl-1 pr-2 py-1 cursor-pointer h-12 border-b-2 border-gray-800'
  const activeClasses = 'text-primary border-b-2 border-primary'
  const defaultClasses =
    ' bg-gray-50 bg-transparent hover:text-accent hover:border-accent'
  const disabledClasses =
    'text-gray-400 cursor-not-allowed bg-gray-50 dark:bg-gray-800 dark:text-gray-500'

  if (isDisabled) {
    return (
      <div className={cn(baseClasses, disabledClasses)}>
        {icon}
        <span className="whitespace-nowrap">{label}</span>
      </div>
    )
  }

  return (
    <div
      className={cn(baseClasses, isActive ? activeClasses : defaultClasses)}
      onClick={onClick}
    >
      {icon}
      <span
        className={cn({
          'whitespace-nowrap': label !== getLongestDisplayName() // remove nowrap if longest name (Gaussian Splat)
        })}
      >
        {label}
      </span>
    </div>
  )
}
