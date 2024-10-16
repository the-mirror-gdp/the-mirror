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
import { useState } from 'react'

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

  const handleTabClick = (key: ComponentType) => {
    setSelectedTab(key)
  }

  return (
    <div className="md:flex">
      <div className="flex-column space-y-4 text-sm font-medium text-gray-500 dark:text-gray-400 md:me-4 mb-4 md:mb-0">
        {entity &&
          entity.components &&
          Object.keys(entity.components).map((key) => {
            return (
              <div key={key}>
                <TabItem
                  isActive={selectedTab === key}
                  icon={getIconForComponent(key as ComponentType)}
                  label={getDisplayNameForComponent(key as ComponentType)}
                  onClick={() => handleTabClick(key as ComponentType)}
                />
              </div>
            )
          })}
      </div>

      <div className="p-6 bg-gray-50 text-medium text-gray-500 dark:text-gray-400 dark:bg-gray-800 rounded-lg w-full">
        <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-2">
          {selectedTab && getDisplayNameForComponent(selectedTab)}
        </h3>
      </div>
    </div>
  )
}
