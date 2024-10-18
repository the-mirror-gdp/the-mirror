import { ComponentType } from '@/components/engine/schemas/component-type'
import {
  BookImage,
  Box,
  PersonStanding,
  Cctv,
  Grip,
  Lightbulb,
  Atom,
  Orbit,
  ScrollText,
  Volume2,
  Proportions
} from 'lucide-react'

export const getIconForComponent = (componentType: ComponentType) => {
  const iconClassName = 'mr-2 h-4 w-4'
  switch (componentType) {
    case ComponentType.Sprite2D:
      return <BookImage className={iconClassName} />
    case ComponentType.Model3D:
      return <Box className={iconClassName} />
    case ComponentType.Anim:
      return <PersonStanding className={iconClassName} />
    case ComponentType.Camera:
      return <Cctv className={iconClassName} />
    case ComponentType.GSplat:
      return <Grip className={iconClassName} />
    case ComponentType.Light:
      return <Lightbulb className={iconClassName} />
    case ComponentType.ParticleSystem:
      return <Atom className={iconClassName} />
    case ComponentType.Collision:
      return <Orbit className={iconClassName} />
    case ComponentType.Script:
      return <ScrollText className={iconClassName} />
    case ComponentType.Sound:
      return <Volume2 className={iconClassName} />
    case ComponentType.UI:
      return <Proportions className={iconClassName} />
    default:
      return null
  }
}

export const getDisplayNameForComponent = (componentType: ComponentType) => {
  switch (componentType) {
    case ComponentType.Sprite2D:
      return '2D Sprite'
    case ComponentType.Model3D:
      return '3D Model'
    case ComponentType.Anim:
      return 'Animation'
    case ComponentType.Camera:
      return 'Camera'
    case ComponentType.GSplat:
      return 'Gaussian Splat'
    case ComponentType.Light:
      return 'Light'
    case ComponentType.ParticleSystem:
      return 'Particles'
    case ComponentType.Collision:
      return 'Collision'
    case ComponentType.Script:
      return 'Script'
    case ComponentType.Sound:
      return 'Sound'
    case ComponentType.UI:
      return 'UI'
    default:
      return 'Component'
  }
}

export const getLongestDisplayName = () => {
  const displayNames = Object.values(ComponentType).map((componentType) =>
    getDisplayNameForComponent(componentType)
  )
  return displayNames.reduce(
    (longest, current) => (current.length > longest.length ? current : longest),
    ''
  )
}
