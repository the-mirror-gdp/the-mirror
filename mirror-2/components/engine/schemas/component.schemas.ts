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
export const render3DModelSchema = z.object({
  enabled: z.boolean(),
  type: z.string(),
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
  type: '',
  asset: null,
  materialAssets: [],
  layers: [],
  batchGroupId: null,
  castShadows: false,
  castShadowsLightmap: false,
  receiveShadows: false,
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
  orthoHeight: z.number(),
  offscreen: z.boolean().optional(),
  clearDepthBuffer: z.boolean(),
  projection: z.number(),
  clearColor: z.array(z.number()).length(4),
  fov: z.number(),
  priority: z.number(),
  farClip: z.number(),
  nearClip: z.number(),
  rect: z.array(z.number()).length(4),
  clearColorBuffer: z.boolean(),
  frustumCulling: z.boolean(),
  layers: z.array(z.number()),
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
  bakeArea: z.number(),
  bakeNumSamples: z.number(),
  bakeDir: z.boolean(),
  affectDynamic: z.boolean(),
  affectLightmapped: z.boolean(),
  affectSpecularity: z.boolean(),
  color: z.array(z.number()).length(3),
  intensity: z.number(),
  castShadows: z.boolean(),
  shadowUpdateMode: z.number(),
  shadowType: z.number(),
  vsmBlurMode: z.number(),
  vsmBlurSize: z.number(),
  vsmBias: z.number(),
  shadowDistance: z.number(),
  shadowIntensity: z.number(),
  shadowResolution: z.number(),
  numCascades: z.number(),
  cascadeDistribution: z.number(),
  shadowBias: z.number(),
  normalOffsetBias: z.number(),
  range: z.number(),
  falloffMode: z.number(),
  innerConeAngle: z.number(),
  outerConeAngle: z.number(),
  shape: z.number(),
  cookieAsset: z.any().nullable(),
  cookieIntensity: z.number(),
  cookieFalloff: z.boolean(),
  cookieChannel: z.string(),
  cookieAngle: z.number(),
  cookieScale: z.array(z.number()).length(2),
  cookieOffset: z.array(z.number()).length(2),
  isStatic: z.boolean(),
  layers: z.array(z.number())
})

//
// Collision Component
//
export const collisionSchema = z.object({
  enabled: z.boolean(),
  type: z.enum(['box', 'sphere', 'capsule', 'mesh', 'cylinder']),
  halfExtents: z.array(z.number()).length(3).optional(),
  radius: z.number().optional(),
  axis: z.number().optional(),
  height: z.number().optional(),
  convexHull: z.boolean().optional(),
  asset: z.any().nullable(),
  renderAsset: z.number().nullable(),
  linearOffset: z.array(z.number()).length(3),
  angularOffset: z.array(z.number()).length(3)
})

//
// Rigidbody Component
//
export const rigidbodySchema = z.object({
  enabled: z.boolean(),
  type: z.enum(['static', 'dynamic', 'kinematic']),
  mass: z.number(),
  linearDamping: z.number(),
  angularDamping: z.number(),
  linearFactor: z.array(z.number()).length(3),
  angularFactor: z.array(z.number()).length(3),
  friction: z.number(),
  restitution: z.number()
})

//
// Screen Component
//
export const screenSchema = z.object({
  enabled: z.boolean(),
  screenSpace: z.boolean(),
  scaleMode: z.enum(['none', 'blend']),
  scaleBlend: z.number(),
  resolution: z.array(z.number()).length(2),
  referenceResolution: z.array(z.number()).length(2),
  priority: z.number()
})

//
// Element Component
//
export const elementSchema = z.object({
  enabled: z.boolean(),
  type: z.enum(['text', 'image', 'group']),
  anchor: z.array(z.number()).length(4),
  pivot: z.array(z.number()).length(2),
  text: z.string(),
  key: z.string().nullable(),
  fontAsset: z.number().nullable(),
  fontSize: z.number(),
  minFontSize: z.number(),
  maxFontSize: z.number(),
  autoFitWidth: z.boolean(),
  autoFitHeight: z.boolean(),
  maxLines: z.number().nullable(),
  lineHeight: z.number(),
  wrapLines: z.boolean(),
  spacing: z.number(),
  color: z.array(z.number()).length(3),
  opacity: z.number(),
  textureAsset: z.any().nullable(),
  spriteAsset: z.any().nullable(),
  spriteFrame: z.number(),
  pixelsPerUnit: z.number().nullable(),
  width: z.number(),
  height: z.number(),
  margin: z.array(z.number()).length(4),
  alignment: z.array(z.number()).length(2),
  outlineColor: z.array(z.number()).length(4),
  outlineThickness: z.number(),
  shadowColor: z.array(z.number()).length(4),
  shadowOffset: z.array(z.number()).length(2),
  rect: z.array(z.number()).length(4),
  materialAsset: z.any().nullable(),
  autoWidth: z.boolean(),
  autoHeight: z.boolean(),
  fitMode: z.enum(['none', 'stretch']),
  useInput: z.boolean(),
  batchGroupId: z.number().nullable(),
  mask: z.boolean(),
  layers: z.array(z.number()),
  enableMarkup: z.boolean()
})

//
// Anim Component
//
export const animSchema = z.object({
  enabled: z.boolean(),
  stateGraphAsset: z.any().nullable(),
  animationAssets: z.record(z.any()),
  speed: z.number(),
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
  width: z.number(),
  height: z.number(),
  color: z.array(z.number()).length(3),
  opacity: z.number(),
  flipX: z.boolean(),
  flipY: z.boolean(),
  spriteAsset: z.any().nullable(),
  frame: z.number(),
  speed: z.number(),
  batchGroupId: z.number().nullable(),
  layers: z.array(z.number()),
  drawOrder: z.number(),
  autoPlayClip: z.string().nullable(),
  clips: z.record(
    z.object({
      name: z.string(),
      fps: z.number(),
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
  layers: z.array(z.number())
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
  volume: z.number(),
  pitch: z.number(),
  positional: z.boolean(),
  refDistance: z.number(),
  maxDistance: z.number(),
  rollOffFactor: z.number(),
  distanceModel: z.enum(['linear', 'inverse', 'exponential']),
  slots: z.record(
    z.object({
      name: z.string(),
      loop: z.boolean(),
      autoPlay: z.boolean(),
      overlap: z.boolean(),
      asset: z.any().nullable(),
      startTime: z.number(),
      duration: z.number().nullable(),
      volume: z.number(),
      pitch: z.number()
    })
  )
})

//
// Particle System Component
//
export const particlesystemSchema = z.object({
  enabled: z.boolean(),
  autoPlay: z.boolean(),
  numParticles: z.number(),
  lifetime: z.number(),
  rate: z.number(),
  rate2: z.number(),
  startAngle: z.number(),
  startAngle2: z.number(),
  loop: z.boolean(),
  preWarm: z.boolean(),
  lighting: z.boolean(),
  halfLambert: z.boolean(),
  intensity: z.number(),
  depthWrite: z.boolean(),
  depthSoftening: z.number(),
  sort: z.number(),
  blendType: z.number(),
  stretch: z.number(),
  alignToMotion: z.boolean(),
  emitterShape: z.number(),
  emitterExtents: z.array(z.number()).length(3),
  emitterExtentsInner: z.array(z.number()).length(3),
  orientation: z.number(),
  particleNormal: z.array(z.number()).length(3),
  emitterRadius: z.number(),
  emitterRadiusInner: z.number(),
  initialVelocity: z.number(),
  animTilesX: z.number(),
  animTilesY: z.number(),
  animStartFrame: z.number(),
  animNumFrames: z.number(),
  animNumAnimations: z.number(),
  animIndex: z.number(),
  randomizeAnimIndex: z.boolean(),
  animSpeed: z.number(),
  animLoop: z.boolean(),
  wrap: z.boolean(),
  wrapBounds: z.array(z.number()).length(3),
  colorMapAsset: z.any().nullable(),
  normalMapAsset: z.any().nullable(),
  mesh: z.any().nullable(),
  renderAsset: z.any().nullable(),
  localSpace: z.boolean(),
  screenSpace: z.boolean(),
  localVelocityGraph: z.object({
    type: z.number(),
    keys: z.array(z.array(z.number())),
    betweenCurves: z.boolean()
  }),
  localVelocityGraph2: z.object({
    type: z.number(),
    keys: z.array(z.array(z.number()))
  }),
  velocityGraph: z.object({
    type: z.number(),
    keys: z.array(z.array(z.number())),
    betweenCurves: z.boolean()
  }),
  velocityGraph2: z.object({
    type: z.number(),
    keys: z.array(z.array(z.number()))
  }),
  rotationSpeedGraph: z.object({
    type: z.number(),
    keys: z.array(z.number()),
    betweenCurves: z.boolean()
  }),
  rotationSpeedGraph2: z.object({
    type: z.number(),
    keys: z.array(z.number())
  }),
  radialSpeedGraph: z.object({
    type: z.number(),
    keys: z.array(z.number()),
    betweenCurves: z.boolean()
  }),
  radialSpeedGraph2: z.object({
    type: z.number(),
    keys: z.array(z.number())
  }),
  scaleGraph: z.object({
    type: z.number(),
    keys: z.array(z.number()),
    betweenCurves: z.boolean()
  }),
  scaleGraph2: z.object({
    type: z.number(),
    keys: z.array(z.number())
  }),
  colorGraph: z.object({
    type: z.number(),
    keys: z.array(z.array(z.number())),
    betweenCurves: z.boolean()
  }),
  alphaGraph: z.object({
    type: z.number(),
    keys: z.array(z.number()),
    betweenCurves: z.boolean()
  }),
  alphaGraph2: z.object({
    type: z.number(),
    keys: z.array(z.number())
  }),
  layers: z.array(z.number())
})

//
// Button Component
//
export const buttonSchema = z.object({
  enabled: z.boolean(),
  active: z.boolean(),
  imageEntity: z.string(),
  hitPadding: z.array(z.number()).length(4),
  transitionMode: z.number(),
  hoverTint: z.array(z.number()).length(4),
  pressedTint: z.array(z.number()).length(4),
  inactiveTint: z.array(z.number()).length(4),
  fadeDuration: z.number(),
  hoverSpriteAsset: z.any().nullable(),
  hoverSpriteFrame: z.number(),
  pressedSpriteAsset: z.any().nullable(),
  pressedSpriteFrame: z.number(),
  inactiveSpriteAsset: z.any().nullable(),
  inactiveSpriteFrame: z.number(),
  hoverTextureAsset: z.any().nullable(),
  pressedTextureAsset: z.any().nullable(),
  inactiveTextureAsset: z.any().nullable()
})

//
// Layout Group Component
//
export const layoutgroupSchema = z.object({
  enabled: z.boolean(),
  orientation: z.number(),
  reverseX: z.boolean(),
  reverseY: z.boolean(),
  alignment: z.array(z.number()).length(2),
  padding: z.array(z.number()).length(4),
  spacing: z.array(z.number()).length(2),
  widthFitting: z.number(),
  heightFitting: z.number(),
  wrap: z.boolean()
})

//
// Layout Child Component
//
export const layoutchildSchema = z.object({
  enabled: z.boolean(),
  minWidth: z.number(),
  minHeight: z.number(),
  maxWidth: z.number().nullable(),
  maxHeight: z.number().nullable(),
  fitWidthProportion: z.number(),
  fitHeightProportion: z.number(),
  excludeFromLayout: z.boolean()
})

//
// Scrollbar Component
//
export const scrollbarSchema = z.object({
  enabled: z.boolean(),
  orientation: z.number(),
  value: z.number(),
  handleSize: z.number(),
  handleEntity: z.string()
})

//
// Scrollview Component
//
export const scrollviewSchema = z.object({
  enabled: z.boolean(),
  horizontal: z.boolean(),
  vertical: z.boolean(),
  scrollMode: z.number(),
  bounceAmount: z.number(),
  friction: z.number(),
  useMouseWheel: z.boolean(),
  mouseWheelSensitivity: z.array(z.number()).length(2),
  horizontalScrollbarVisibility: z.number(),
  verticalScrollbarVisibility: z.number(),
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
