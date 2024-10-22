import { createContext, useContext, useEffect, useRef } from 'react'
import { useAppSelector } from '@/hooks/hooks'
import { selectCurrentScene } from '@/state/local.slice'
import {
  DatabaseEntity,
  EntityId,
  useGetAllEntitiesQuery,
  useUpdateEntityMutation
} from '@/state/api/entities'
import { skipToken } from '@reduxjs/toolkit/query/react'
import { updateEngineApp } from '@/state/engine/engine'
import { Observer } from '@playcanvas/observer'
import { entitySchemaUiFormDefaultValues } from '@/components/engine/schemas/entity.schema'
import * as pc from 'playcanvas'
import { getApp } from '@/components/engine/__start-custom__'

// export const getJsonPathForObserverStructure = (
//   entityId: string,
//   key: string
// ) => {
//   /**
//    * If databaseEntity is:
//    * {
//    * name: <data>,
//    * ...
//    * }
//    * then the 'path' needs to be 'name'
//    */
//   return `${key}`
// }

export const extractEntityIdFromJsonPathForObserverStructure = (
  input: string
) => {
  const parts = input.split('.')
  return parts[0]
}

// Define the type for the context value
type SpaceEngineNonGameContextType = {
  createObserverForEntity: (entity: DatabaseEntity) => any
  getObserverForEntity: (id: EntityId) => Observer | undefined
  updateObserverForEntity: (id: any, newData: any) => void
}

// Create the context with a default value
export const SpaceEngineNonGameContext =
  createContext<SpaceEngineNonGameContextType>({
    createObserverForEntity: () => {},
    getObserverForEntity: (id) => {
      // Replace the following line with actual logic to return an Observer
      return {} as Observer // Assuming Observer is a known type
    },
    updateObserverForEntity: () => {}
  })

export const SpaceEngineNonGameProvider = ({ children }) => {
  const currentScene = useAppSelector(selectCurrentScene)
  const {
    data: entities,
    isSuccess: isSuccessGettingEntities,
    error
  } = useGetAllEntitiesQuery(currentScene?.id || skipToken)
  const app = getApp()

  useEffect(() => {
    if (entities && isSuccessGettingEntities) {
      entities.forEach((entity) => {
        if (!observersRef.current.has(entity.id)) {
          createObserverForEntity(entity)
        } else {
          updateObserverForEntity(entity.id, entity)
        }
      })
    }
  }, [entities, isSuccessGettingEntities])

  const observersRef = useRef(new Map<EntityId, Observer>())

  const createObserverForEntity = (entityData: DatabaseEntity) => {
    if (!entityData) {
      return
    }
    // handle empty obj case {}
    const observerData =
      Object.keys(entityData).length === 0
        ? { ...entitySchemaUiFormDefaultValues }
        : entityData

    const observer = new Observer(observerData)

    // handle changes/updates to entity
    // DO NOT update RTK/Redux here; it manages itself separately. Took a lot of hours trying to figure out a solution: it's much easier just to decouple it so that Redux "observes" the playcanvas app & makes changes instead of updates getting "pushed" from the Observer. This is doubly good with separation of concerns because the PlayCanvas app shoulnd't know Redux exists.
    observer.on('*:set', async (path, value) => {
      // const entityId = extractEntityIdFromJsonPathForObserverStructure(path)
      // TODO: try out key compare here to reduce calls to update engine, if needed. benchmark
      // console.log('path', path)
      // console.log('value', value)
      // console.log('json', )
      const jsonData: DatabaseEntity = observer.json() as DatabaseEntity
      const entityId = jsonData.id

      const engineEntity = app.root.findByGuid(entityId)

      if (engineEntity) {
        console.log('find: engine entity', engineEntity)
      }

      // const currentData = observer.get(id)
      // const updatedData = observer.get();
      // updateEngineApp(updatedData);
    })

    observersRef.current.set(entityData.id, observer)
    return observer
  }

  const getObserverForEntity = (id) => {
    return observersRef.current.get(id)
  }

  const updateObserverForEntity = (id, newData) => {
    const observer = observersRef.current.get(id)
    if (observer) {
      observer.set(id, newData)
    }
  }

  return (
    <SpaceEngineNonGameContext.Provider
      value={{
        createObserverForEntity,
        getObserverForEntity,
        updateObserverForEntity
      }}
    >
      {children}
    </SpaceEngineNonGameContext.Provider>
  )
}
