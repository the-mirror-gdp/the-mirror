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

export function VerticalTabs() {
  const form = useFormContext()
  const currentEntity = useAppSelector(selectCurrentEntity)
  // This may seem odd to use this here instead of passing props, but this helps with rerendering. It was a huge pain earlier with not rerendering correctly since we're working with nested data
  const { data: entity } = useGetSingleEntityQuery(
    currentEntity?.id || skipToken
  )
  const [selectedTab, setSelectedTab] = useState<ComponentType | null>(null)
  const [componentKeys, setComponentKeys] = useState<string[]>([])

  useEffect(() => {
    if (entity && entity.components) {
      const keys = Object.keys(entity.components)
      keys.sort((a, b) => {
        const orderA = Object.values(ComponentType).indexOf(a as ComponentType)
        const orderB = Object.values(ComponentType).indexOf(b as ComponentType)
        return orderA - orderB
      })
      setComponentKeys(keys)
    } else {
      setComponentKeys([])
    }
  }, [entity])

  const handleTabClick = (key: ComponentType) => {
    setSelectedTab(key)
  }

  return (
    <div className="flex">
      <div className="flex-column text-sm font-medium h-12">
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

      <div className="p-2 text-medium text-gray-400 text-center  w-full">
        <h3 className="flex flex-row justify-center items-center text-lg font-bold text-white gap-2">
          <div className="flex justify-center items-center">
            {selectedTab && getIconForComponent(selectedTab as ComponentType)}
          </div>
          <div> {selectedTab && getDisplayNameForComponent(selectedTab)}</div>
        </h3>
      </div>
    </div>
  )
}
