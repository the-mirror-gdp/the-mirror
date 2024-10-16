'use client'

import { Button } from '@/components/ui/button'
import { CreateComponentButton } from '@/components/ui/custom-buttons/add-component.button'
import { useAppSelector } from '@/hooks/hooks'
import { selectCurrentEntity } from '@/state/local.slice'
import { cn } from '@/utils/cn'
import { PlusCircleIcon } from 'lucide-react'
import { EntityFormGroup } from '@/components/ui/inspector/entity.formgroup'
import { Separator } from '@/components/ui/separator'
import { VerticalTabs } from '@/components/ui/tabs/vertical-tabs'

export default function Inspector({ className }) {
  const entity = useAppSelector(selectCurrentEntity)
  return (
    <div className={cn(className, 'flex flex-col gap-3 p-2')}>
      {entity && (
        <>
          <EntityFormGroup
            entity={entity}
            key={'EntityFormGroup' + entity.id} // had to add key bc wasn't rerendering
          />

          <Separator />

          {/* Create Component Button */}
          <CreateComponentButton
            entity={entity}
            key={'CreateComponentButton' + entity.id}
          />

          <VerticalTabs key={'VerticalTabs' + entity.components} />
        </>
      )}
    </div>
  )
}
