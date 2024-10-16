'use client'
import { EntityFormGroupOld } from '@/components/ui/inspector/entity.formgroup-old'
import { Button } from '@/components/ui/button'
import { CreateComponentButton } from '@/components/ui/custom-buttons/create-component.button'
import { useAppSelector } from '@/hooks/hooks'
import { selectCurrentEntity } from '@/state/local.slice'
import { cn } from '@/utils/cn'
import { PlusCircleIcon } from 'lucide-react'
import { EntityFormGroup } from '@/components/ui/inspector/entity.formgroup'

export default function Inspector({ className }) {
  const entity = useAppSelector(selectCurrentEntity)

  return (
    <div className={cn(className, 'flex flex-col p-3')}>
      {entity && (
        <>
          <EntityFormGroup entity={entity} />
          {/* Create Component Button */}
          <CreateComponentButton entity={entity} />
        </>
      )}
    </div>
  )
}
