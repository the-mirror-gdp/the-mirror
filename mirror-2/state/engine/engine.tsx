import { getApp } from '@/components/engine/__start-custom__'
import { ComponentType } from '@/components/engine/schemas/component-type'
import { render3DModelSchemaDefaultValues } from '@/components/engine/schemas/component.schemas'
import { entitySchema } from '@/components/engine/schemas/entity.schema'
import { DatabaseEntity } from '@/state/api/entities'
import * as pc from 'playcanvas'

// No clue why but ComponentType is getting imported as a full module so just redeclaring here for now :/. Maybe a TSBug? TODO watch for fix

// enum ComponentType {
//   Sprite2D = 'sprite', // different from engine naming for simplicity
//   Model3D = 'render', // different from engine naming for simplicity
//   Anim = 'anim',
//   AudioListener = 'audiolistener',
//   Button = 'button',
//   Camera = 'camera',
//   Collision = 'collision',
//   GSplat = 'gsplat',
//   LayoutChild = 'layoutchild',
//   LayoutGroup = 'layoutgroup',
//   Light = 'light',
//   ParticleSystem = 'particlesystem',
//   RigidBody = 'rigidbody',
//   Screen = 'screen',
//   Script = 'script',
//   Scrollbar = 'scrollbar',
//   ScrollView = 'scrollview',
//   Sound = 'sound',
//   Element = 'element'
// }

// Singleton PlayCanvas instance manager. Primary engine class that makes PlayCanvas updates based on the Redux store
let playCanvasApp: pc.Application | null = null
const optimisticEntities = new Map<string, pc.Entity>()

export function setApp(app: pc.Application) {
  playCanvasApp = app
}

/**
 * Primary update method for the whole engine: pass in entities and it does the rest.
 */
// TODO do we want this to handle optimistic/reverts? Yes, important because we may add visual effects for optimistic updates/reverts. Otherwise, the engine just gets the latest full state of entities/components
export function updateEngineApp<T extends { id: string }>(
  entities: DatabaseEntity[],
  options: { isOptimistic?: boolean; isReverted?: boolean } = {}
) {
  const app = getApp()

  if (!app) {
    console.warn('Engine app is not initialized.')
    return
  }

  // TODO add optimistic updates
  // console.warn('skipping optimistic updates')
  // if (options.isOptimistic) {
  //   applyOptimisticEngineUpdates(app, entities)
  // } else if (options.isReverted) {
  //   revertOptimisticEngineUpdates(app, entities)
  // } else {
  // if (!options.isOptimistic && !options.isReverted) {
  applyConfirmedEngineUpdates(entities)
  // }
  // }
}

function applyConfirmedEngineUpdates(databaseEntities: DatabaseEntity[]) {
  const app = getApp()
  console.log('Applying confirmed updates to engine', databaseEntities)

  databaseEntities.forEach((databaseEntity) => {
    // app.root.addChild(entity)
    // pcEntity.enabled = true
    // entity.setLocalScale(33.1, 5.1, 5.1)
    // pcEntity.setLocalPosition(
    //   Math.random() * 1.2,
    //   Math.random() * 1.2,
    //   Math.random() * 1.2
    // )
    // console.log('Adding entity! updated log', entity)
    // entity.addComponent('render', {
    //   type: 'cylinder',
    //   castShadows: true,
    //   receiveShadows: true
    // })

    // note: works
    // const sphere = new pc.dEntity('spheretest')
    // sphere.setLocalScale(0.1, 0.1, 0.1)
    // sphere.enabled = true
    // sphere.setLocalPosition(
    //   Math.random() * 1.2,
    //   Math.random() * 1.2,
    //   Math.random() * 1.2
    // )
    // sphere.addComponent('render', {
    //   type: 'sphere',
    //   castShadows: true,
    //   receiveShadows: true
    // })
    // app.root.addChild(sphere)

    // console.log('children added confirmed')

    // Ensure pcEntity is of type Entity
    updateEngineEntity(databaseEntity)

    // Remove from optimisticEntities if it was added optimistically
    // console.warn('skipping optimistic removes!!!!!!')
    // if (optimisticEntities.has(entityData.id)) {
    //   optimisticEntities.delete(entityData.id)
    // }
  })

  // Optionally remove entities not present in the confirmed data
  // console.warn('Skipping stale remove')
  // removeStaleEntities(app, entities)
}

function updateEngineEntity(databaseEntity: DatabaseEntity) {
  const app = getApp()

  // TODO change to find by id so unique
  // TODO change to find by id so unique
  // TODO change to find by id so unique
  // TODO change to find by id so unique
  // TODO change to find by id so unique
  // TODO change to find by id so unique
  // TODO change to find by id so unique
  let pcEntity: pc.Entity | null = app.root.findByName(
    databaseEntity.name
  ) as pc.Entity | null // Entity is subclass of GraphNode

  let added = false
  // create if doesn't exist
  if (!pcEntity) {
    pcEntity = new pc.Entity(databaseEntity.name)
    pcEntity.setGuid(databaseEntity.id)
    app.root.addChild(pcEntity)
    added = true
    // pcEntity.addComponent('render', {
    //   type: 'sphere',
    //   castShadows: true,
    //   receiveShadows: true
    // })
    // TODO update parent-child
    // app.root.addChild(pcEntity)
  }
  // TODO add entity.reparent() methods

  if ('enabled' in databaseEntity) {
    pcEntity.enabled = databaseEntity.enabled
  }

  if (
    'local_position' in databaseEntity &&
    Array.isArray(databaseEntity.local_position)
  ) {
    const [x, y, z] = databaseEntity.local_position
    pcEntity.setPosition(x, y, z)
  }

  if (
    'local_rotation' in databaseEntity &&
    Array.isArray(databaseEntity.local_rotation)
  ) {
    const [x, y, z, w] = databaseEntity.local_rotation
    pcEntity.setLocalRotation(x, y, z, w)
  }

  if (
    'local_scale' in databaseEntity &&
    Array.isArray(databaseEntity.local_scale)
  ) {
    const [x, y, z] = databaseEntity.local_scale
    pcEntity.setLocalScale(x, y, z)
  }

  // Add or update other properties as needed based on your entity schema
  // Update tags if present in entityData
  if ('tags' in databaseEntity && Array.isArray(databaseEntity.tags)) {
    const existingTags = new Set(pcEntity.tags.list())
    databaseEntity.tags.forEach((tag: string) => {
      if (!existingTags.has(tag)) {
        pcEntity!.tags.add(tag)
      }
    })
  }

  // Handle entity components
  // if (databaseEntity?.components) {
  //   const components = databaseEntity.components
  //   const componentKeys = Object.keys(components)

  // if no components, ensure removed on entity
  if (!databaseEntity?.components) {
    // Remove all existing components from the pcEntity
    const existingComponents = pcEntity.c
    Object.keys(existingComponents).forEach((componentKey) => {
      pcEntity!.removeComponent(componentKey)
    })
  }

  // update the entity's components
  Object.entries(databaseEntity?.components || {}).forEach(
    ([componentKey, newComponentData]) => {
      // let componentData = cd // use let so we can manipulate
      switch (componentKey) {
        case ComponentType.Model3D: // render
          // pseudocode
          //1. check if componentData is falsey or empty object. if so, use defaults (this should only occur on first time component creation)

          if (!newComponentData || Object.keys(newComponentData).length === 0) {
            const updateComponentData = Object.assign(
              {},
              newComponentData,
              render3DModelSchemaDefaultValues
            )
            if (pcEntity && pcEntity[componentKey]) {
              Object.assign(pcEntity[componentKey]!, updateComponentData)
            } else {
              pcEntity!.addComponent(componentKey, updateComponentData)
            }
            return
          }
          // 2. apply changes from newComponentData (if not a new object)

          const updateComponentData = {
            enabled: newComponentData.enabled,
            type: newComponentData.type,
            asset: newComponentData.asset,
            materialAssets: newComponentData.materialAssets,
            // layers: newComponentData.layers,
            layers: [0],
            // batchGroupId: data.batchGroupId, TODO add/fix
            // castShadows: componenewComponentDatantData.castShadows,
            castShadows: true,
            // castShadowsLightmap: newComponentData.castShadowsLightmap,
            castShadowsLightmap: true,
            // receiveShadows: newComponentData.receiveShadows,
            receiveShadows: true,
            lightmapped: newComponentData.lightmapped,
            lightmapSizeMultiplier: newComponentData.lightmapSizeMultiplier,
            isStatic: newComponentData.isStatic,
            rootBone: newComponentData.rootBone,
            customAabb: newComponentData.customAabb,
            aabbCenter: newComponentData.aabbCenter,
            aabbHalfExtents: newComponentData.aabbHalfExtents
          }

          if (pcEntity && pcEntity[componentKey]) {
            Object.assign(pcEntity[componentKey]!, updateComponentData)
          } else {
            pcEntity!.addComponent(componentKey, updateComponentData)
          }

        // pcEntity?.addComponent(componentKey, updatedComponentData)
        // app.root.addChild(pcEntity)
        // added = true

        // if (entity.render) {
        //   Object.assign(entity.render, componentData)
        //   console.log(`1.1 updateEngineEntity: Obj. assign: entity`, entity)
        // } else {
        //   var checkType = ComponentType.Model3D // for some reason, having to declare this here or else ComponentType is imported incorrectly
        //   entity.addComponent(checkType, componentData)
        //   console.log(`2 updateEngineEntity: Component for entity`, entity)
        // }
        // console.log(
        //   `updateEngineEntity: Updated entity:`,
        //   entity[componentKey]
        // )
        //   break
        // case ComponentType.Sprite2D:
        //   if (entity.sprite) {
        //     Object.assign(entity.sprite, componentData)
        //   } else {
        //     entity.addComponent('sprite', componentData)
        //   }
        //   break
        // Add more cases for other component types as needed
        default:
          // if (entity[key]) {
          //   Object.assign(entity[key], data)
          // } else {
          //   entity.addComponent(key, data)
          // }
          break
      }

      if (added) {
        console.log('new pcEntity', pcEntity)
        console.log('from databaseEntity', databaseEntity)

        var pcEntityTemp = new pc.Entity('temp' + Math.random())
        pcEntityTemp.addComponent('render', {
          type: 'sphere',
          castShadows: true,
          receiveShadows: true
        })
        app.root.addChild(pcEntityTemp)
        console.log('new pcEntityTemp', pcEntityTemp)
      }

      // Log all entities in the scene
      // console.log('Entities in the scene:', app.root.children)
      // app.root.children.forEach((child) => {
      //   // console.log(`Entity Name: ${child.name}, Entity:`, child)
      // })
      // })
    }
  )
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
