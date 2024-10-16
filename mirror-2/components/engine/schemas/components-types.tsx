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

export enum ComponentType {
  Anim = 'anim',
  AudioListener = 'audiolistener',
  Button = 'button',
  Camera = 'camera',
  Collision = 'collision',
  Element = 'element',
  GSplat = 'gsplat',
  LayoutChild = 'layoutchild',
  LayoutGroup = 'layoutgroup',
  Light = 'light',
  ParticleSystem = 'particlesystem',
  Model3D = 'render', // different from engine naming for simplicity
  RigidBody = 'rigidbody',
  Screen = 'screen',
  Script = 'script',
  Scrollbar = 'scrollbar',
  ScrollView = 'scrollview',
  Sound = 'sound',
  Sprite2D = 'sprite' // different from engine naming for simplicity
  // Legacy
  // Animation = 'animation', // legacy; commented out here for reference
  // Model = 'model', // legacy; commented out here for reference
}

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
    case ComponentType.Element:
      return <Proportions className={iconClassName} />
    default:
      return null
  }
}
