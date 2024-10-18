import {
  Atom,
  BookImage,
  Box,
  Camera,
  Cctv,
  ChevronDown,
  Grip,
  Lightbulb,
  MousePointer,
  Music,
  Orbit,
  PersonStanding,
  PlusCircleIcon,
  Proportions,
  ScrollText,
  Settings,
  Sliders,
  User,
  Volume2,
  Wind
} from 'lucide-react'

import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuTrigger
} from '@/components/ui/dropdown-menu'
import { DatabaseEntity } from '@/state/api/entities'
import { useAddComponentToEntityMutation } from '@/state/api/entities'

export function CreateComponentButton({ entity }: { entity: DatabaseEntity }) {
  const iconClassName = 'mr-2 h-4 w-4'
  const itemClassName = 'cursor-pointer'

  // Access the addComponentToEntity mutation hook
  const [addComponentToEntity] = useAddComponentToEntityMutation()

  // Function to handle adding a component when a menu item is clicked
  // Function to handle adding a component when a menu item is clicked
  const handleAddComponent = (componentKey: string, componentData: any) => {
    addComponentToEntity({
      id: entity.id,
      componentKey, // The specific component key (e.g., 'render', 'camera')
      componentData // The component data to be added
    })
  }

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant={'default'} type="button">
          Add Component <ChevronDown />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent className="w-56">
        <DropdownMenuGroup>
          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent('2D Sprite', {})}
          >
            <BookImage className={iconClassName} />
            <span>2D Sprite</span>
          </DropdownMenuItem>
          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent('3D Model', {})}
          >
            <Box className={iconClassName} />
            <span>3D Model</span>
          </DropdownMenuItem>
          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent('Animation', {})}
          >
            <PersonStanding className={iconClassName} />
            <span>Animation</span>
          </DropdownMenuItem>
          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent('Camera', {})}
          >
            <Cctv className={iconClassName} />
            <span>Camera</span>
          </DropdownMenuItem>

          {/* <DropdownMenuSeparator /> */}

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent('Light', {})}
          >
            <Lightbulb className={iconClassName} />
            <span>Light</span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent('Physics', {})}
          >
            <Orbit className={iconClassName} />
            <span>Physics</span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent('Gaussian Splat', {})}
          >
            <Grip className={iconClassName} />
            <span>Gaussian Splat</span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent('Particles', {})}
          >
            <Atom className={iconClassName} />
            <span>Particles</span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent('Script', {})}
          >
            <ScrollText className={iconClassName} />
            <span>Script</span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent('Sound', {})}
          >
            <Volume2 className={iconClassName} />
            <span>Sound</span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent('UI', {})}
          >
            <Proportions className={iconClassName} />
            <span>UI</span>
          </DropdownMenuItem>
        </DropdownMenuGroup>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
