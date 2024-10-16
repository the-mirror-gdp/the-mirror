// TabItem.tsx
import { ReactNode } from 'react'
import { cn } from '@/utils/cn'

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
    'inline-flex items-center px-4 py-3 rounded-lg w-full cursor-pointer'
  const activeClasses = 'text-white bg-primary dark:bg-blue-600'
  const defaultClasses =
    'hover:text-gray-900 bg-gray-50 hover:bg-gray-100 dark:bg-gray-800 dark:hover:bg-gray-700 dark:hover:text-white'
  const disabledClasses =
    'text-gray-400 cursor-not-allowed bg-gray-50 dark:bg-gray-800 dark:text-gray-500'

  if (isDisabled) {
    return (
      <div className={cn(baseClasses, disabledClasses)}>
        {icon}
        {label}
      </div>
    )
  }

  return (
    <div
      className={cn(baseClasses, isActive ? activeClasses : defaultClasses)}
      onClick={onClick}
    >
      {icon}
      {label}
    </div>
  )
}
