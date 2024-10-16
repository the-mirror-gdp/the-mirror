import { getApp } from '@/components/engine/__start-custom__'
import { DatabaseEntity } from '@/state/api/entities'
import * as pc from 'playcanvas'

// No clue why but ComponentType is getting imported as a full module so just redeclaring here for now :/. Maybe a TSBug? TODO watch for fix

enum ComponentType {
  Sprite2D = 'sprite', // different from engine naming for simplicity
  Model3D = 'render', // different from engine naming for simplicity
  Anim = 'anim',
  AudioListener = 'audiolistener',
  Button = 'button',
  Camera = 'camera',
  Collision = 'collision',
  GSplat = 'gsplat',
  LayoutChild = 'layoutchild',
  LayoutGroup = 'layoutgroup',
  Light = 'light',
  ParticleSystem = 'particlesystem',
  RigidBody = 'rigidbody',
  Screen = 'screen',
  Script = 'script',
  Scrollbar = 'scrollbar',
  ScrollView = 'scrollview',
  Sound = 'sound',
  Element = 'element'
}

// Singleton PlayCanvas instance manager. Primary engine class that makes PlayCanvas updates based on the Redux store
let playCanvasApp: pc.Application | null = null

export function setApp(app: pc.Application) {
  playCanvasApp = app
}

const optimisticEntities = new Map<string, pc.Entity>()

export function updateEngineApp<T extends { id: string }>(
  entities: DatabaseEntity[],
  options: { isOptimistic?: boolean; isReverted?: boolean } = {}
) {
  const app = getApp()

  if ('istemp' === 'istemp') {
    console.warn('bypassing engine update')
    return
  }

  if (!app) {
    console.warn('PlayCanvas app is not initialized.')
    return
  }

  if (options.isOptimistic) {
    console.log('Applying optimistic updates to PlayCanvas', entities)

    entities.forEach((entityData) => {
      let pcEntity = app.root.findByName(entityData.id)

      if (!pcEntity) {
        // Create a new PlayCanvas entity
        pcEntity = new pc.Entity(entityData.id)
        app.root.addChild(pcEntity)

        // Store the entity for potential reverts
        optimisticEntities.set(entityData.id, pcEntity as pc.Entity)
      }

      // Ensure pcEntity is of type Entity
      const entity: pc.Entity = pcEntity as pc.Entity // Cast to Entity if safe
      updateEngineEntity(entity, entityData)

      // Remove from optimisticEntities if it was added optimistically
    })
  } else if (options.isReverted) {
    console.log('Reverting PlayCanvas state', entities)

    entities.forEach((entityData) => {
      const pcEntity = optimisticEntities.get(entityData.id)
      if (pcEntity) {
        // Remove the entity from the scene
        pcEntity.destroy()
        optimisticEntities.delete(entityData.id)
      }
    })
  } else {
    console.log('Applying confirmed updates to PlayCanvas', entities)

    entities.forEach((entityData) => {
      let pcEntity = app.root.findByName(entityData.id)

      if (!pcEntity) {
        pcEntity = new pc.Entity(entityData.id)
        app.root.addChild(pcEntity)
      }

      // Ensure pcEntity is of type Entity
      const entity = pcEntity
      updateEngineEntity(entity, entityData)

      // Remove from optimisticEntities if it was added optimistically
      if (optimisticEntities.has(entityData.id)) {
        optimisticEntities.delete(entityData.id)
      }
    })

    // Optionally remove entities not present in the confirmed data
    removeStaleEntities(app, entities)
  }
}

function updateEngineEntity(pcEntity: pc.Entity, entityData: DatabaseEntity) {
  if ('position' in entityData && Array.isArray(entityData.position)) {
    const [x, y, z] = entityData.position
    pcEntity.setPosition(x, y, z)
  }

  if ('rotation' in entityData && Array.isArray(entityData.rotation)) {
    const [x, y, z] = entityData.rotation
    pcEntity.setEulerAngles(x, y, z)
  }

  if ('scale' in entityData && Array.isArray(entityData.scale)) {
    const [x, y, z] = entityData.scale
    pcEntity.setLocalScale(x, y, z)
  }

  // Add or update other properties as needed based on your entity schema
  // Update tags if present in entityData
  if ('tags' in entityData && Array.isArray(entityData.tags)) {
    const existingTags = new Set(pcEntity.tags.list())
    entityData.tags.forEach((tag: string) => {
      if (!existingTags.has(tag)) {
        pcEntity.tags.add(tag)
      }
    })
  }

  // Handle entity components
  if ('components' in entityData && typeof entityData.components === 'object') {
    const components = entityData.components
    if (components) {
      const componentKeys = Object.keys(components)

      componentKeys.forEach((componentKey) => {
        const componentData = components[componentKey]
        if (Object.keys(componentData).length === 0) {
          return
        }
        // Abstract logic for updating or adding components based on their type
        const updateOrAddComponent = (
          entity: pc.Entity,
          // key: typeof ComponentType,
          key: any,
          data: any
        ) => {
          switch (key) {
            case ComponentType.Model3D:
              const componentData = {
                enabled: data.enabled,
                type: data.type,
                asset: data.asset,
                materialAssets: data.materialAssets,
                layers: data.layers,
                // batchGroupId: data.batchGroupId, TODO add/fix
                castShadows: data.castShadows,
                castShadowsLightmap: data.castShadowsLightmap,
                receiveShadows: data.receiveShadows,
                lightmapped: data.lightmapped,
                lightmapSizeMultiplier: data.lightmapSizeMultiplier,
                isStatic: data.isStatic,
                rootBone: data.rootBone,
                customAabb: data.customAabb,
                aabbCenter: data.aabbCenter,
                aabbHalfExtents: data.aabbHalfExtents
              }
              if (entity.render) {
                Object.assign(entity.render, componentData)
              } else {
                var checkType = ComponentType.Model3D // for some reason, having to declare this here or else ComponentType is imported incorrectly
                entity.addComponent(checkType, componentData)
              }
              break
            case ComponentType.Sprite2D:
              if (entity.sprite) {
                Object.assign(entity.sprite, data)
              } else {
                entity.addComponent('sprite', data)
              }
              break
            // Add more cases for other component types as needed
            default:
              // if (entity[key]) {
              //   Object.assign(entity[key], data)
              // } else {
              //   entity.addComponent(key, data)
              // }
              break
          }
        }

        // Iterate over component keys and update or add components
        componentKeys.forEach((componentKey) => {
          // if (!Object.values(ComponentType).includes(componentKey)) {
          //   console.error(
          //     `Component key ${componentKey} does not exist in ComponentType`
          //   )
          //   throw new Error(
          //     `Component key ${componentKey} does not exist in ComponentType`
          //   )
          // }
          const componentData = components[componentKey]
          updateOrAddComponent(
            pcEntity,
            componentKey as ComponentType,
            componentData
          )
        })
      })
    }
  }
}

function removeStaleEntities<T extends { id: string }>(
  app: pc.Application,
  entities: T[]
) {
  const currentEntityIds = new Set(entities.map((e) => e.id))

  app.root.children.forEach((child) => {
    if (!currentEntityIds.has(child.name)) {
      // Remove entities not present in the current data
      child.destroy()
    }
  })
}
