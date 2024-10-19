import { createContext, useContext, useEffect, useRef } from 'react'
import { useAppSelector } from '@/hooks/hooks'
import { selectCurrentScene } from '@/state/local.slice'
import { DatabaseEntity, useGetAllEntitiesQuery } from '@/state/api/entities'
import { skipToken } from '@reduxjs/toolkit/query/react'
import { updateEngineApp } from '@/state/engine/engine'
import { Observer } from '@playcanvas/observer'
import { entitySchemaUiFormDefaultValues } from '@/components/engine/schemas/entity.schema'

export const getJsonPathForObserverStructure = (firstKey: string) => {
  // TODO will be tweaked for nested (likely)
  return firstKey
}

// Define the type for the context value
type SpaceEngineContextType = {
  createObserverForEntity: (entity: DatabaseEntity) => any
  getObserverForEntity: (id: any) => any
  updateObserverForEntity: (id: any, newData: any) => void
}

// Create the context with a default value
export const SpaceEngineContext = createContext<SpaceEngineContextType>({
  createObserverForEntity: () => {},
  getObserverForEntity: () => {},
  updateObserverForEntity: () => {}
})

export const SpaceEngineProvider = ({ children }) => {
  const currentScene = useAppSelector(selectCurrentScene)
  const {
    data: entities,
    isSuccess: isSuccessGettingEntities,
    error
  } = useGetAllEntitiesQuery(currentScene?.id || skipToken)
  useEffect(() => {
    if (entities && isSuccessGettingEntities) {
      console.log('WIP Running engine update for entities:', entities)

      entities.forEach((entity) => {
        if (!observersRef.current.has(entity.id)) {
          createObserverForEntity(entity)
        } else {
          // TODO
        }
      })

      updateEngineApp(entities)
    }
  }, [entities, isSuccessGettingEntities])

  const observersRef = useRef(new Map())

  const createObserverForEntity = (entityData: DatabaseEntity) => {
    // if (!entityData) {
    //   return
    // }
    // handle empty obj case {}
    const observerData =
      Object.keys(entityData).length === 0
        ? { ...entitySchemaUiFormDefaultValues }
        : entityData

    const observer = new Observer(observerData)

    observer.on('*:set', (path, value) => {
      console.log('observer.on *:set unfinished', path, value)
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
      observer.set(newData)
    }
  }

  return (
    <SpaceEngineContext.Provider
      value={{
        createObserverForEntity,
        getObserverForEntity,
        updateObserverForEntity
      }}
    >
      {children}
    </SpaceEngineContext.Provider>
  )
}
