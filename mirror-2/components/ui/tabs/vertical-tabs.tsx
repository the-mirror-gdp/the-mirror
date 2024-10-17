import { TabItem } from '@/components/ui/tabs/tab-item'
import { useAppSelector } from '@/hooks/hooks'
import { DatabaseEntity, useGetSingleEntityQuery } from '@/state/api/entities'
import {
  UserIcon,
  LayoutDashboardIcon,
  SettingsIcon,
  ContactIcon,
  XCircleIcon
} from 'lucide-react'
import { useFormContext } from 'react-hook-form'
import { useState, useEffect } from 'react'

import {
  ComponentType,
  getDisplayNameForComponent,
  getIconForComponent
} from '@/components/engine/schemas/components-types'
import { selectCurrentEntity } from '@/state/local.slice'
import { skipToken } from '@reduxjs/toolkit/query'
import { Separator } from '@/components/ui/separator'
import Model3DRenderFormGroup from '@/components/ui/inspector/components/model-3d'

export function VerticalTabs() {
  const form = useFormContext()
  const currentEntity = useAppSelector(selectCurrentEntity)
  // This may seem odd to use this here instead of passing props, but this helps with rerendering. It was a huge pain earlier with not rerendering correctly since we're working with nested data
  const { data: entity } = useGetSingleEntityQuery(
    currentEntity?.id || skipToken
  )
  const [selectedTab, setSelectedTab] = useState<ComponentType | undefined>(
    undefined
  )
  const [componentKeys, setComponentKeys] = useState<string[]>([])

  useEffect(() => {
    if (!currentEntity?.id) {
      console.log('Skipping query with skipToken.')
    }
  }, [currentEntity?.id])

  useEffect(() => {
    if (entity && entity.components) {
      const keys = Object.keys(entity.components)
      keys.sort((a, b) => {
        const orderA = Object.values(ComponentType).indexOf(a as ComponentType)
        const orderB = Object.values(ComponentType).indexOf(b as ComponentType)
        return orderA - orderB
      })
      setComponentKeys(keys)

      // in a transition, if the new entity doesn't have the component of the previously selected tab, set selected tab to first
      if (keys.length > 0 && !keys.includes(selectedTab as string)) {
        setSelectedTab(keys[0] as ComponentType)
      }
    } else {
      setComponentKeys([])
    }
  }, [entity])

  const handleTabClick = (key: ComponentType) => {
    setSelectedTab(key)
  }

  return (
    <div className="flex flex-col h-full">
      <div className="flex flex-wrap gap-0 text-sm font-medium">
        {componentKeys.map((key) => {
          return (
            <TabItem
              key={key}
              isActive={selectedTab === key}
              icon={getIconForComponent(key as ComponentType)}
              label={getDisplayNameForComponent(key as ComponentType)}
              onClick={() => handleTabClick(key as ComponentType)}
            />
          )
        })}
      </div>

      <div className="mt-2 p-2 text-medium text-gray-400 text-center w-full">
        <h3 className="flex flex-row justify-center items-center text-lg font-bold text-white gap-2">
          <div className="flex justify-center items-center w-full">
            <div>
              {' '}
              {selectedTab && getIconForComponent(selectedTab as ComponentType)}
            </div>
            <div> {selectedTab && getDisplayNameForComponent(selectedTab)}</div>
          </div>
        </h3>
        <div className="flex flex-col">
          {selectedTab && entity && (
            <div className="mt-4">
              {(() => {
                switch (selectedTab) {
                  case ComponentType.Model3D:
                    return (
                      <Model3DRenderFormGroup
                        key={'Model3DRenderFormGroup' + entity.id}
                      />
                    )
                  // case ComponentType.TypeB:
                  //   return <ComponentB />;
                  // case ComponentType.TypeC:
                  //   return <ComponentC />;
                  // // Add more cases as needed
                  default:
                    return <div>Component Not Found</div>
                }
              })()}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
