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
  getIconForComponent
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
            <span>2D Sprite</span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent(ComponentType.Model3D, {})}
          >
            {getIconForComponent(ComponentType.Model3D)}
            <span>3D Model</span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent(ComponentType.Anim, {})}
          >
            {getIconForComponent(ComponentType.Anim)}
            <span>Animation</span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent(ComponentType.Camera, {})}
          >
            {getIconForComponent(ComponentType.Camera)}
            <span>Camera</span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent(ComponentType.GSplat, {})}
          >
            {getIconForComponent(ComponentType.GSplat)}
            <span>Gaussian Splat</span>
          </DropdownMenuItem>

          {/* <DropdownMenuSeparator /> */}

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent(ComponentType.Light, {})}
          >
            {getIconForComponent(ComponentType.Light)}
            <span>Light</span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent(ComponentType.ParticleSystem, {})}
          >
            {getIconForComponent(ComponentType.ParticleSystem)}
            <span>Particles</span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent(ComponentType.Collision, {})}
          >
            {getIconForComponent(ComponentType.Collision)}
            <span>Physics</span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent(ComponentType.Script, {})}
          >
            {getIconForComponent(ComponentType.Script)}
            <span>Script</span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent(ComponentType.Sound, {})}
          >
            {getIconForComponent(ComponentType.Sound)}
            <span>Sound</span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className={itemClassName}
            onClick={() => handleAddComponent(ComponentType.Element, {})}
          >
            {getIconForComponent(ComponentType.Element)}
            <span>UI</span>
          </DropdownMenuItem>
        </DropdownMenuGroup>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
