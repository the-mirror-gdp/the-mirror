function applyOptimisticEngineUpdates(
  app: pc.Application,
  entities: DatabaseEntity[]
) {
  console.log('Applying optimistic updates to engine', entities)

  entities.forEach((entityData) => {
    let pcEntity = app.root.findByName(entityData.id)

    if (!pcEntity) {
      // Create a new PlayCanvas entity
      pcEntity = new pc.Entity(entityData.name)
      console.warn('add back')
      app.root.addChild(pcEntity)
      console.log('children added optimistic')
      // Store the entity for potential reverts
      optimisticEntities.set(entityData.id, pcEntity as pc.Entity)
    }

    // Ensure pcEntity is of type Entity
    const entity: pc.Entity = pcEntity as pc.Entity // Cast to Entity if safe
    updateEngineEntity(entity, entityData)

    // Remove from optimisticEntities if it was added optimistically
  })
}

function revertOptimisticEngineUpdates(
  app: pc.Application,
  entities: DatabaseEntity[]
) {
  console.log('Reverting engine state', entities)

  entities.forEach((entityData) => {
    const pcEntity = optimisticEntities.get(entityData.id)
    if (pcEntity) {
      // Remove the entity from the scene
      pcEntity.destroy()
      optimisticEntities.delete(entityData.id)
    }
  })
}
