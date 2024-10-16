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
import {
  ComponentType,
  getIconForComponent,
  getDisplayNameForComponent
} from '@/components/engine/schemas/components-types'

export function CreateComponentButton({ entity }: { entity: DatabaseEntity }) {
  const itemClassName = 'cursor-pointer'

  // Access the addComponentToEntity mutation hook
  const [addComponentToEntity] = useAddComponentToEntityMutation()

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
            onClick={() => handleAddComponent(ComponentType.Sprite2D, {})}
          >
            {getIconForComponent(ComponentType.Sprite2D)}
            <span>{getDisplayNameForComponent(ComponentType.Sprite2D)}</span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent(ComponentType.Model3D, {})}
          >
            {getIconForComponent(ComponentType.Model3D)}
            <span>{getDisplayNameForComponent(ComponentType.Model3D)}</span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent(ComponentType.Anim, {})}
          >
            {getIconForComponent(ComponentType.Anim)}
            <span>{getDisplayNameForComponent(ComponentType.Anim)}</span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent(ComponentType.Camera, {})}
          >
            {getIconForComponent(ComponentType.Camera)}
            <span>{getDisplayNameForComponent(ComponentType.Camera)}</span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent(ComponentType.GSplat, {})}
          >
            {getIconForComponent(ComponentType.GSplat)}
            <span>{getDisplayNameForComponent(ComponentType.GSplat)}</span>
          </DropdownMenuItem>

          {/* <DropdownMenuSeparator /> */}

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent(ComponentType.Light, {})}
          >
            {getIconForComponent(ComponentType.Light)}
            <span>{getDisplayNameForComponent(ComponentType.Light)}</span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent(ComponentType.ParticleSystem, {})}
          >
            {getIconForComponent(ComponentType.ParticleSystem)}
            <span>
              {getDisplayNameForComponent(ComponentType.ParticleSystem)}
            </span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent(ComponentType.Collision, {})}
          >
            {getIconForComponent(ComponentType.Collision)}
            <span>{getDisplayNameForComponent(ComponentType.Collision)}</span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent(ComponentType.Script, {})}
          >
            {getIconForComponent(ComponentType.Script)}
            <span>{getDisplayNameForComponent(ComponentType.Script)}</span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent(ComponentType.Sound, {})}
          >
            {getIconForComponent(ComponentType.Sound)}
            <span>{getDisplayNameForComponent(ComponentType.Sound)}</span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent(ComponentType.Element, {})}
          >
            {getIconForComponent(ComponentType.Element)}
            <span>{getDisplayNameForComponent(ComponentType.Element)}</span>
          </DropdownMenuItem>
        </DropdownMenuGroup>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
