'use client'
import { EntityFormGroupOld } from '@/components/ui/inspector/entity.formgroup-old'
import { Button } from '@/components/ui/button'
import { CreateComponentButton } from '@/components/ui/custom-buttons/create-component.button'
import { useAppSelector } from '@/hooks/hooks'
import { selectCurrentEntity } from '@/state/local.slice'
import { cn } from '@/utils/cn'
import { PlusCircleIcon } from 'lucide-react'
import { EntityFormGroup } from '@/components/ui/inspector/entity.formgroup'
import { Separator } from '@/components/ui/separator'

export default function Inspector({ className }) {
  const entity = useAppSelector(selectCurrentEntity)
  console.log('ins entity', entity)
  return (
    <div className={cn(className, 'flex flex-col gap-3 p-2')}>
      {entity && (
        <>
          <EntityFormGroup
            entity={entity}
            key={'EntityFormGroup' + entity.id} // had to add key bc wasn't rerendering
          />

          {/* Create Component Button */}
          <CreateComponentButton
            entity={entity}
            key={'CreateComponentButton' + entity.id}
          />
        </>
      )}
    </div>
  )
}
