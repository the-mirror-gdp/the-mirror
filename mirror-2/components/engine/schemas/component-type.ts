// this order determines the vertical sidebar order
import { z } from 'zod'

export enum ComponentType {
  Sprite2D = 'sprite', // Sprite2D, different display name for simplicity
  Model3D = 'render', // Model3D, different display name for simplicity
  Anim = 'anim', // Anim
  AudioListener = 'audiolistener', // AudioListener
  Button = 'button', // Button
  Camera = 'camera', // Camera
  Collision = 'collision', // Collision
  GSplat = 'gsplat', // GSplat
  LayoutChild = 'layoutchild', // LayoutChild
  LayoutGroup = 'layoutgroup', // LayoutGroup
  Light = 'light', // Light
  ParticleSystem = 'particlesystem', // ParticleSystem
  Rigidbody = 'rigidbody', // RigidBody
  Screen = 'screen', // Screen
  Script = 'script', // Script
  Scrollbar = 'scrollbar', // Scrollbar
  ScrollView = 'scrollview', // ScrollView
  Sound = 'sound', // Sound
  UI = 'element' // UI, different display name for simplicity
}

const componentTypeValues = Object.values(ComponentType)

// using zod enum instead of z.nativeEnum since it's the recommended approach:
export const ComponentTypeZodEnum = z.enum(
  componentTypeValues as [string, ...string[]]
)

export const ComponentTypeOptions = ComponentTypeZodEnum.options
