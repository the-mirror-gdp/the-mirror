import { TabItem } from '@/components/ui/tabs/tab-item'
import { useAppSelector } from '@/hooks/hooks'
import { DatabaseEntity } from '@/state/api/entities'
import {
  UserIcon,
  LayoutDashboardIcon,
  SettingsIcon,
  ContactIcon,
  XCircleIcon
} from 'lucide-react'
import { useFormContext } from 'react-hook-form'
import { useState } from 'react'
import { selectCurrentEntityComponents } from '@/state/local.slice'

export function VerticalTabs({
  components
}: {
  components: DatabaseEntity['components']
}) {
  const form = useFormContext()

  const [selectedTab, setSelectedTab] = useState<string | null>(null)

  const handleTabClick = (key: string) => {
    setSelectedTab(key)
  }

  return (
    <div className="md:flex">
      <div className="flex-column space-y-4 text-sm font-medium text-gray-500 dark:text-gray-400 md:me-4 mb-4 md:mb-0">
        {components &&
          Object.keys(components).map((key) => {
            return (
              <div key={key}>
                <TabItem
                  href="#"
                  isActive={selectedTab === key}
                  icon={<UserIcon className="w-4 h-4 me-2 text-white" />}
                  label={key}
                  onClick={() => handleTabClick(key)}
                />
              </div>
            )
          })}
      </div>

      <div className="p-6 bg-gray-50 text-medium text-gray-500 dark:text-gray-400 dark:bg-gray-800 rounded-lg w-full">
        <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-2">
          Profile Tab
        </h3>
        <p className="mb-2">
          This is some placeholder content the Profile tab's associated content,
          clicking another tab will toggle the visibility of this one for the
          next.
        </p>
        <p>
          The tab JavaScript swaps classes to control the content visibility and
          styling.
        </p>
      </div>
    </div>
  )
}
