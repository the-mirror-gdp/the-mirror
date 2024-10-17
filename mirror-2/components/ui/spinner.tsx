import { Axis3D, LoaderCircle } from 'lucide-react'

import { cn } from '@/lib/utils'

export function Spinner({ children = null, className, ...props }) {
  return (
    <LoaderCircle
      className={cn('animate-pulse animate-spin transition-all', className)}
      {...props}
    >
      {children}
    </LoaderCircle>
  )
}
