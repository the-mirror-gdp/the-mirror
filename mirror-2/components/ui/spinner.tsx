import { Axis3D, LoaderCircle } from 'lucide-react'

import { cn } from '@/lib/utils'

export function Spinner({ children = null, className, ...props }) {
  return (
    <LoaderCircle
      className={cn('animate-pulse transition-all duration-100', className)}
      {...props}
    >
      {children}
    </LoaderCircle>
  )
}
