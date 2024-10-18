import { z } from 'zod'
/**
 * Source of truth for the schemas of JSONB data in the DB, e.g. components, scene settings.
 * Why? Postgres uses JSONSchema for JSON validation, which is fine, but it's a raw text string and hard to tweak/debug without tons of migrations and iterations.
 * We use zod elsewhere and there's a great zod-to-json schema library.
 * This allows us to use zod for JSON validation in the client AND we can copy-paste the JSONSchema conversion into our SQL definitions once it's hardened. (However, the client-side validation should take us pretty far bc it can be run right both at the form level and in the API request/RTK query before a DB insert in entitiesApi)
 */

//
// 3D Model/Render Component
//
export type Render3DModel = z.infer<typeof render3DModelSchema>
export enum Render3DModelType {
  Asset = 'asset',
  Box = 'box',
  Sphere = 'sphere',
  Capsule = 'capsule',
  Cylinder = 'cylinder',
  Cone = 'cone',
  Mesh = 'mesh',
  Compound = 'compound'
}
export const Render3DModelTypeValues = Object.entries(Render3DModelType).map(
  ([key, value]) => ({
    displayName: key,
    value: value
  })
)
export const render3DModelSchema = z.object({
  enabled: z.boolean(),
  type: z.nativeEnum(Render3DModelType),
  asset: z.coerce.number().nullable(), // only show if type == asset
  materialAssets: z.array(z.coerce.number().nullable()),
  layers: z.array(z.coerce.number()), // multi select
  batchGroupId: z.coerce.number().nullable(), // select
  castShadows: z.boolean(),
  castShadowsLightmap: z.boolean(),
  receiveShadows: z.boolean(),
  lightmapped: z.boolean(),
  lightmapSizeMultiplier: z.coerce.number(), // only show if lightmapped is true
  isStatic: z.boolean(),
  rootBone: z.any().nullable(), // don't include

  // For custom AABB
  customAabb: z.boolean().nullable(),
  aabbCenter: z
    .tuple([z.coerce.number(), z.coerce.number(), z.coerce.number()])
    .optional(),
  aabbHalfExtents: z
    .tuple([z.coerce.number(), z.coerce.number(), z.coerce.number()])
    .optional()
})

export const render3DModelSchemaDefaultValues = {
  enabled: true,
  type: 'box' as Render3DModelType,
  asset: null,
  materialAssets: [],
  layers: [0],
  batchGroupId: null,
  castShadows: true,
  castShadowsLightmap: true,
  receiveShadows: true,
  lightmapped: false,
  lightmapSizeMultiplier: 1,
  isStatic: false,
  rootBone: null,
  customAabb: null,
  aabbCenter: undefined,
  aabbHalfExtents: undefined
}

//
// Camera Component
//
export const cameraSchema = z.object({
  enabled: z.boolean(),
  orthoHeight: z.coerce.number(),
  offscreen: z.boolean().optional(),
  clearDepthBuffer: z.boolean(),
  projection: z.coerce.number(),
  clearColor: z.array(z.coerce.number()).length(4),
  fov: z.coerce.number(),
  priority: z.coerce.number(),
  farClip: z.coerce.number(),
  nearClip: z.coerce.number(),
  rect: z.array(z.coerce.number()).length(4),
  clearColorBuffer: z.boolean(),
  frustumCulling: z.boolean(),
  layers: z.array(z.coerce.number()),
  renderSceneDepthMap: z.boolean().optional(),
  renderSceneColorMap: z.boolean().optional()
})

//
// Script Component
//
export const scriptSchema = z.object({
  enabled: z.boolean(),
  order: z.array(z.string()),
  scripts: z.record(
    z.object({
      enabled: z.boolean(),
      attributes: z.record(z.any()).optional()
    })
  )
})

//
// Light Component
//
export const lightSchema = z.object({
  enabled: z.boolean(),
  type: z.enum(['directional', 'point', 'spot']),
  bake: z.boolean(),
  bakeArea: z.coerce.number(),
  bakeNumSamples: z.coerce.number(),
  bakeDir: z.boolean(),
  affectDynamic: z.boolean(),
  affectLightmapped: z.boolean(),
  affectSpecularity: z.boolean(),
  color: z.array(z.coerce.number()).length(3),
  intensity: z.coerce.number(),
  castShadows: z.boolean(),
  shadowUpdateMode: z.coerce.number(),
  shadowType: z.coerce.number(),
  vsmBlurMode: z.coerce.number(),
  vsmBlurSize: z.coerce.number(),
  vsmBias: z.coerce.number(),
  shadowDistance: z.coerce.number(),
  shadowIntensity: z.coerce.number(),
  shadowResolution: z.coerce.number(),
  numCascades: z.coerce.number(),
  cascadeDistribution: z.coerce.number(),
  shadowBias: z.coerce.number(),
  normalOffsetBias: z.coerce.number(),
  range: z.coerce.number(),
  falloffMode: z.coerce.number(),
  innerConeAngle: z.coerce.number(),
  outerConeAngle: z.coerce.number(),
  shape: z.coerce.number(),
  cookieAsset: z.any().nullable(),
  cookieIntensity: z.coerce.number(),
  cookieFalloff: z.boolean(),
  cookieChannel: z.string(),
  cookieAngle: z.coerce.number(),
  cookieScale: z.array(z.coerce.number()).length(2),
  cookieOffset: z.array(z.coerce.number()).length(2),
  isStatic: z.boolean(),
  layers: z.array(z.coerce.number())
})

//
// Collision Component
//
export const collisionSchema = z.object({
  enabled: z.boolean(),
  type: z.enum(['box', 'sphere', 'capsule', 'mesh', 'cylinder']),
  halfExtents: z.array(z.coerce.number()).length(3).optional(),
  radius: z.coerce.number().optional(),
  axis: z.coerce.number().optional(),
  height: z.coerce.number().optional(),
  convexHull: z.boolean().optional(),
  asset: z.any().nullable(),
  renderAsset: z.coerce.number().nullable(),
  linearOffset: z.array(z.coerce.number()).length(3),
  angularOffset: z.array(z.coerce.number()).length(3)
})

//
// Rigidbody Component
//
export const rigidbodySchema = z.object({
  enabled: z.boolean(),
  type: z.enum(['static', 'dynamic', 'kinematic']),
  mass: z.coerce.number(),
  linearDamping: z.coerce.number(),
  angularDamping: z.coerce.number(),
  linearFactor: z.array(z.coerce.number()).length(3),
  angularFactor: z.array(z.coerce.number()).length(3),
  friction: z.coerce.number(),
  restitution: z.coerce.number()
})

//
// Screen Component
//
export const screenSchema = z.object({
  enabled: z.boolean(),
  screenSpace: z.boolean(),
  scaleMode: z.enum(['none', 'blend']),
  scaleBlend: z.coerce.number(),
  resolution: z.array(z.coerce.number()).length(2),
  referenceResolution: z.array(z.coerce.number()).length(2),
  priority: z.coerce.number()
})

//
// Element Component
//
export const elementSchema = z.object({
  enabled: z.boolean(),
  type: z.enum(['text', 'image', 'group']),
  anchor: z.array(z.coerce.number()).length(4),
  pivot: z.array(z.coerce.number()).length(2),
  text: z.string(),
  key: z.string().nullable(),
  fontAsset: z.coerce.number().nullable(),
  fontSize: z.coerce.number(),
  minFontSize: z.coerce.number(),
  maxFontSize: z.coerce.number(),
  autoFitWidth: z.boolean(),
  autoFitHeight: z.boolean(),
  maxLines: z.coerce.number().nullable(),
  lineHeight: z.coerce.number(),
  wrapLines: z.boolean(),
  spacing: z.coerce.number(),
  color: z.array(z.coerce.number()).length(3),
  opacity: z.coerce.number(),
  textureAsset: z.any().nullable(),
  spriteAsset: z.any().nullable(),
  spriteFrame: z.coerce.number(),
  pixelsPerUnit: z.coerce.number().nullable(),
  width: z.coerce.number(),
  height: z.coerce.number(),
  margin: z.array(z.coerce.number()).length(4),
  alignment: z.array(z.coerce.number()).length(2),
  outlineColor: z.array(z.coerce.number()).length(4),
  outlineThickness: z.coerce.number(),
  shadowColor: z.array(z.coerce.number()).length(4),
  shadowOffset: z.array(z.coerce.number()).length(2),
  rect: z.array(z.coerce.number()).length(4),
  materialAsset: z.any().nullable(),
  autoWidth: z.boolean(),
  autoHeight: z.boolean(),
  fitMode: z.enum(['none', 'stretch']),
  useInput: z.boolean(),
  batchGroupId: z.coerce.number().nullable(),
  mask: z.boolean(),
  layers: z.array(z.coerce.number()),
  enableMarkup: z.boolean()
})

//
// Anim Component
//
export const animSchema = z.object({
  enabled: z.boolean(),
  stateGraphAsset: z.any().nullable(),
  animationAssets: z.record(z.any()),
  speed: z.coerce.number(),
  activate: z.boolean(),
  playing: z.boolean(),
  rootBone: z.any().nullable(),
  masks: z.record(z.any()),
  normalizeWeights: z.boolean()
})

//
// Sprite Component
//
export const spriteSchema = z.object({
  enabled: z.boolean(),
  type: z.enum(['simple', 'animated']),
  width: z.coerce.number(),
  height: z.coerce.number(),
  color: z.array(z.coerce.number()).length(3),
  opacity: z.coerce.number(),
  flipX: z.boolean(),
  flipY: z.boolean(),
  spriteAsset: z.any().nullable(),
  frame: z.coerce.number(),
  speed: z.coerce.number(),
  batchGroupId: z.coerce.number().nullable(),
  layers: z.array(z.coerce.number()),
  drawOrder: z.coerce.number(),
  autoPlayClip: z.string().nullable(),
  clips: z.record(
    z.object({
      name: z.string(),
      fps: z.coerce.number(),
      loop: z.boolean(),
      autoPlay: z.boolean(),
      spriteAsset: z.any().nullable()
    })
  )
})

//
// Gsplat Component
//
export const gsplatSchema = z.object({
  enabled: z.boolean(),
  asset: z.any().nullable(),
  layers: z.array(z.coerce.number())
})

//
// Audio Listener Component
//
export const audiolistenerSchema = z.object({
  enabled: z.boolean()
})

//
// Sound Component
//
export const soundSchema = z.object({
  enabled: z.boolean(),
  volume: z.coerce.number(),
  pitch: z.coerce.number(),
  positional: z.boolean(),
  refDistance: z.coerce.number(),
  maxDistance: z.coerce.number(),
  rollOffFactor: z.coerce.number(),
  distanceModel: z.enum(['linear', 'inverse', 'exponential']),
  slots: z.record(
    z.object({
      name: z.string(),
      loop: z.boolean(),
      autoPlay: z.boolean(),
      overlap: z.boolean(),
      asset: z.any().nullable(),
      startTime: z.coerce.number(),
      duration: z.coerce.number().nullable(),
      volume: z.coerce.number(),
      pitch: z.coerce.number()
    })
  )
})

//
// Particle System Component
//
export const particlesystemSchema = z.object({
  enabled: z.boolean(),
  autoPlay: z.boolean(),
  numParticles: z.coerce.number(),
  lifetime: z.coerce.number(),
  rate: z.coerce.number(),
  rate2: z.coerce.number(),
  startAngle: z.coerce.number(),
  startAngle2: z.coerce.number(),
  loop: z.boolean(),
  preWarm: z.boolean(),
  lighting: z.boolean(),
  halfLambert: z.boolean(),
  intensity: z.coerce.number(),
  depthWrite: z.boolean(),
  depthSoftening: z.coerce.number(),
  sort: z.coerce.number(),
  blendType: z.coerce.number(),
  stretch: z.coerce.number(),
  alignToMotion: z.boolean(),
  emitterShape: z.coerce.number(),
  emitterExtents: z.array(z.coerce.number()).length(3),
  emitterExtentsInner: z.array(z.coerce.number()).length(3),
  orientation: z.coerce.number(),
  particleNormal: z.array(z.coerce.number()).length(3),
  emitterRadius: z.coerce.number(),
  emitterRadiusInner: z.coerce.number(),
  initialVelocity: z.coerce.number(),
  animTilesX: z.coerce.number(),
  animTilesY: z.coerce.number(),
  animStartFrame: z.coerce.number(),
  animNumFrames: z.coerce.number(),
  animNumAnimations: z.coerce.number(),
  animIndex: z.coerce.number(),
  randomizeAnimIndex: z.boolean(),
  animSpeed: z.coerce.number(),
  animLoop: z.boolean(),
  wrap: z.boolean(),
  wrapBounds: z.array(z.coerce.number()).length(3),
  colorMapAsset: z.any().nullable(),
  normalMapAsset: z.any().nullable(),
  mesh: z.any().nullable(),
  renderAsset: z.any().nullable(),
  localSpace: z.boolean(),
  screenSpace: z.boolean(),
  localVelocityGraph: z.object({
    type: z.coerce.number(),
    keys: z.array(z.array(z.coerce.number())),
    betweenCurves: z.boolean()
  }),
  localVelocityGraph2: z.object({
    type: z.coerce.number(),
    keys: z.array(z.array(z.coerce.number()))
  }),
  velocityGraph: z.object({
    type: z.coerce.number(),
    keys: z.array(z.array(z.coerce.number())),
    betweenCurves: z.boolean()
  }),
  velocityGraph2: z.object({
    type: z.coerce.number(),
    keys: z.array(z.array(z.coerce.number()))
  }),
  rotationSpeedGraph: z.object({
    type: z.coerce.number(),
    keys: z.array(z.coerce.number()),
    betweenCurves: z.boolean()
  }),
  rotationSpeedGraph2: z.object({
    type: z.coerce.number(),
    keys: z.array(z.coerce.number())
  }),
  radialSpeedGraph: z.object({
    type: z.coerce.number(),
    keys: z.array(z.coerce.number()),
    betweenCurves: z.boolean()
  }),
  radialSpeedGraph2: z.object({
    type: z.coerce.number(),
    keys: z.array(z.coerce.number())
  }),
  scaleGraph: z.object({
    type: z.coerce.number(),
    keys: z.array(z.coerce.number()),
    betweenCurves: z.boolean()
  }),
  scaleGraph2: z.object({
    type: z.coerce.number(),
    keys: z.array(z.coerce.number())
  }),
  colorGraph: z.object({
    type: z.coerce.number(),
    keys: z.array(z.array(z.coerce.number())),
    betweenCurves: z.boolean()
  }),
  alphaGraph: z.object({
    type: z.coerce.number(),
    keys: z.array(z.coerce.number()),
    betweenCurves: z.boolean()
  }),
  alphaGraph2: z.object({
    type: z.coerce.number(),
    keys: z.array(z.coerce.number())
  }),
  layers: z.array(z.coerce.number())
})

//
// Button Component
//
export const buttonSchema = z.object({
  enabled: z.boolean(),
  active: z.boolean(),
  imageEntity: z.string(),
  hitPadding: z.array(z.coerce.number()).length(4),
  transitionMode: z.coerce.number(),
  hoverTint: z.array(z.coerce.number()).length(4),
  pressedTint: z.array(z.coerce.number()).length(4),
  inactiveTint: z.array(z.coerce.number()).length(4),
  fadeDuration: z.coerce.number(),
  hoverSpriteAsset: z.any().nullable(),
  hoverSpriteFrame: z.coerce.number(),
  pressedSpriteAsset: z.any().nullable(),
  pressedSpriteFrame: z.coerce.number(),
  inactiveSpriteAsset: z.any().nullable(),
  inactiveSpriteFrame: z.coerce.number(),
  hoverTextureAsset: z.any().nullable(),
  pressedTextureAsset: z.any().nullable(),
  inactiveTextureAsset: z.any().nullable()
})

//
// Layout Group Component
//
export const layoutgroupSchema = z.object({
  enabled: z.boolean(),
  orientation: z.coerce.number(),
  reverseX: z.boolean(),
  reverseY: z.boolean(),
  alignment: z.array(z.coerce.number()).length(2),
  padding: z.array(z.coerce.number()).length(4),
  spacing: z.array(z.coerce.number()).length(2),
  widthFitting: z.coerce.number(),
  heightFitting: z.coerce.number(),
  wrap: z.boolean()
})

//
// Layout Child Component
//
export const layoutchildSchema = z.object({
  enabled: z.boolean(),
  minWidth: z.coerce.number(),
  minHeight: z.coerce.number(),
  maxWidth: z.coerce.number().nullable(),
  maxHeight: z.coerce.number().nullable(),
  fitWidthProportion: z.coerce.number(),
  fitHeightProportion: z.coerce.number(),
  excludeFromLayout: z.boolean()
})

//
// Scrollbar Component
//
export const scrollbarSchema = z.object({
  enabled: z.boolean(),
  orientation: z.coerce.number(),
  value: z.coerce.number(),
  handleSize: z.coerce.number(),
  handleEntity: z.string()
})

//
// Scrollview Component
//
export const scrollviewSchema = z.object({
  enabled: z.boolean(),
  horizontal: z.boolean(),
  vertical: z.boolean(),
  scrollMode: z.coerce.number(),
  bounceAmount: z.coerce.number(),
  friction: z.coerce.number(),
  useMouseWheel: z.boolean(),
  mouseWheelSensitivity: z.array(z.coerce.number()).length(2),
  horizontalScrollbarVisibility: z.coerce.number(),
  verticalScrollbarVisibility: z.coerce.number(),
  viewportEntity: z.string(),
  contentEntity: z.string(),
  horizontalScrollbarEntity: z.string(),
  verticalScrollbarEntity: z.string()
})

// // Define the components schema as a flexible record
// export const componentsSchema = z.record(
//   z.union([
//     lightSchema.optional(), // Light component
//     renderSchema.optional(), // Render component
//     cameraSchema.optional(), // Camera component
//     scriptSchema.optional() // Script component
//     // Add other component schemas here...
//   ])
// )

// // Known components mapping for validation
// const knownComponentSchemas: Record<string, z.ZodSchema<any>> = {
//   light: lightSchema,
//   render: renderSchema,
//   camera: cameraSchema,
//   script: scriptSchema
//   // Add other known components here...
// }

// // Define the entity schema with dynamic components
// const entitySchema = z.object({
//   id: z.string().uuid(), // assuming entity ID is a UUID
//   name: z.string(),
//   components: z.record(z.string(), z.any()).refine(
//     (components) => {
//       // Validate known components
//       for (const key of Object.keys(components)) {
//         if (knownComponentSchemas[key]) {
//           const validation = knownComponentSchemas[key].safeParse(
//             components[key]
//           )
//           if (!validation.success) {
//             return false
//           }
//         }
//       }
//       return true
//     },
//     {
//       message: 'Invalid component schema'
//     }
//   )
// })
