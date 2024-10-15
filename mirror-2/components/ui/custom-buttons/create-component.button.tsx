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

export function CreateComponentButton() {
  const iconClassName = 'mr-2 h-4 w-4'
  const itemClassName = 'cursor-pointer'

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant={'default'} type="button">
          {/* <PlusCircleIcon className="mr-2" /> */}
          Add Component <ChevronDown />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent className="w-56">
        <DropdownMenuGroup>
          <DropdownMenuItem className={itemClassName}>
            <BookImage className={iconClassName} />
            <span>2D Sprite</span>
          </DropdownMenuItem>
          <DropdownMenuItem className={itemClassName}>
            <Box className={iconClassName} />
            <span>3D Model</span>
          </DropdownMenuItem>
          <DropdownMenuItem className={itemClassName}>
            <PersonStanding className={iconClassName} />
            <span>Animation</span>
          </DropdownMenuItem>
          <DropdownMenuItem className={itemClassName}>
            <Cctv className={iconClassName} />
            <span>Camera</span>
          </DropdownMenuItem>

          {/* <DropdownMenuSeparator /> */}

          <DropdownMenuItem className={itemClassName}>
            <Lightbulb className={iconClassName} />
            <span>Light</span>
          </DropdownMenuItem>

          <DropdownMenuItem className={itemClassName}>
            <Orbit className={iconClassName} />
            <span>Physics</span>
          </DropdownMenuItem>

          <DropdownMenuItem className={itemClassName}>
            <Grip className={iconClassName} />
            <span>Gaussian Splat</span>
          </DropdownMenuItem>

          <DropdownMenuItem className={itemClassName}>
            <Atom className={iconClassName} />
            <span>Particles</span>
          </DropdownMenuItem>

          <DropdownMenuItem className={itemClassName}>
            <ScrollText className={iconClassName} />
            <span>Script</span>
          </DropdownMenuItem>

          <DropdownMenuItem className={itemClassName}>
            <Volume2 className={iconClassName} />
            <span>Sound</span>
          </DropdownMenuItem>

          <DropdownMenuItem className={itemClassName}>
            <Proportions className={iconClassName} />
            <span>UI</span>
          </DropdownMenuItem>
        </DropdownMenuGroup>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
