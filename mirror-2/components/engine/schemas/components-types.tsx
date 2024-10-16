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
