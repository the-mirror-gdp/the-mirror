'use client'
import { entitySchema } from '@/components/engine/schemas/entity.schema'
import { SpaceEngineNonGameContext } from '@/components/engine/space-engine-non-game-context'
import useReduxInputSync from '@/components/ui/synced-inputs/new-with-pc-ui/redux-input-sync'

import { cn } from '@/utils/cn'
import { BindingTwoWay, TextInput } from '@playcanvas/pcui/react'
import { FC, useContext, useEffect, useRef } from 'react'

export interface TextInputPcTwoWayProps {
  // super important: the path to the generalEntity's property here, e.g. <uid>.name, <uid>.nestedSomething.someInput
  path: string
  entityId: string
  className: any
  schema: any
  schemaFieldName: any
}

const TextInputPcTwoWay: FC<TextInputPcTwoWayProps> = ({
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
    <TextInput
      input={(() => {
        const inputElement = document.createElement('input')
        inputElement.className = cn(
          'flex h-full w-full border-slate-200 bg-white pl-4 pr-3 py-2 text-sm ring-offset-white file:border-0 file:bg-transparent file:text-sm file:font-medium file:text-slate-950 placeholder:text-slate-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-950 focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 dark:border-slate-800 dark:bg-slate-950 dark:ring-offset-slate-950 dark:file:text-slate-50 dark:placeholder:text-slate-400 dark:focus-visible:ring-accent rounded-sm',
          className
        )
        inputElement.onblur = () => {
          const value = inputElement.value
          const validation = schemaWithOnlyField.safeParse({
            [schemaFieldName]: value
          })

          if (validation.success) {
            updateReduxWithDebounce(entityId, { [path]: value })
          }
        }
        return inputElement
      })()}
      onValidate={(val) => {
        const test = schemaWithOnlyField.safeParse({
          [schemaFieldName]: val
        })
        console.log('validation', test, 'path: ', path, 'info', test)
        return test.success
      }}
      binding={new BindingTwoWay()}
      link={link}
      {...props}
    />
  )
}
TextInputPcTwoWay.displayName = 'TextInputPcTwoWay'

export { TextInputPcTwoWay }
