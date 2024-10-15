// engine.ts
import { getApp } from '@/components/engine/__start-custom__'
import * as pc from 'playcanvas'
import { Entity } from 'playcanvas'

// Singleton PlayCanvas instance manager
let playCanvasApp: pc.Application | null = null

export function setApp(app: pc.Application) {
  playCanvasApp = app
}

const optimisticEntities = new Map<string, pc.Entity>()

export function updateEngineApp<T extends { id: string }>(
  entities: T[],
  options: { isOptimistic?: boolean; isReverted?: boolean } = {}
) {
  const app = getApp()

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
        optimisticEntities.set(entityData.id, pcEntity as Entity)
      }

      // Ensure pcEntity is of type Entity
      const entity: Entity = pcEntity as Entity // Cast to Entity if safe
      updatePlayCanvasEntity(entity, entityData)

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
      const entity: Entity = pcEntity as Entity // Cast to Entity if safe
      updatePlayCanvasEntity(entity, entityData)

      // Remove from optimisticEntities if it was added optimistically
      if (optimisticEntities.has(entityData.id)) {
        optimisticEntities.delete(entityData.id)
      }
    })

    // Optionally remove entities not present in the confirmed data
    removeStaleEntities(app, entities)
  }
}

function updatePlayCanvasEntity(pcEntity: pc.Entity, entityData: any) {
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
