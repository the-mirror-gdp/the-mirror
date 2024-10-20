import { cn } from '@/utils/cn'

export const AxisLabelCharacter = ({
  axis,
  className
}: {
  axis: 'x' | 'y' | 'z' | 'w'
  className?: string
}) => {
  const axisColorClasses = {
    x: 'text-red-500', // Red color for X axis
    y: 'text-green-500', // Green color for Y axis
    z: 'text-blue-500' // Blue color for Z axis
  }

  return (
    <span
      className={cn(
        className,
        `font-bold ${axisColorClasses[axis.toLowerCase()]}`
      )}
    >
      {axis.toUpperCase()}
    </span>
  )
}
