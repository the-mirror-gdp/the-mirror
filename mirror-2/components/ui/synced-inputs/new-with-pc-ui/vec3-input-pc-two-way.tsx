'use client'
import { entitySchema } from '@/components/engine/schemas/entity.schema'
import { SpaceEngineNonGameContext } from '@/components/engine/space-engine-non-game-context'
import useReduxInputSync from '@/components/ui/synced-inputs/new-with-pc-ui/redux-input-sync'

import { cn } from '@/utils/cn'
import { BindingTwoWay, VectorInput } from '@playcanvas/pcui/react'
import { FC, useContext, useEffect, useRef } from 'react'

export interface Vec3InputPcTwoWayProps {
  // super important: the path to the generalEntity's property here, e.g. <uid>.name, <uid>.nestedSomething.someInput
  path: string
  entityId: string
  className: any
  schema: any
  schemaFieldName: any
}

const Vec3InputPcTwoWay: FC<Vec3InputPcTwoWayProps> = ({
  className,
  path,
  entityId,
  schema,
  schemaFieldName,
  ...props
}) => {
  const { getObserverForEntity } = useContext(SpaceEngineNonGameContext)
  const observer = getObserverForEntity(entityId)
  if (!observer) {
    throw new Error('Error finding observer for entity')
  }
  const link = { observer, path }
  const schemaWithOnlyField = schema.pick({
    [schemaFieldName]: true
  })
  const { updateReduxWithDebounce } = useReduxInputSync()
  return (
    <div className="w-full">
      <VectorInput
        // NOTE: see globals.css for style modifications since this wasn't doing the trick
        class={'w-full flex dark:bg-transparent border-none shadow-none dark:focus-visible:ring-accent rounded-sm'.split(
          ' '
        )}
        binding={new BindingTwoWay()}
        link={link}
        {...props}
      />
    </div>
  )
}
Vec3InputPcTwoWay.displayName = 'Vec3InputPcTwoWay'

export { Vec3InputPcTwoWay }
