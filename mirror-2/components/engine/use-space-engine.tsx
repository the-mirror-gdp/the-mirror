import { useAppSelector } from '@/hooks/hooks'
import { selectCurrentScene } from '@/state/local.slice'
import { useGetAllEntitiesQuery } from '@/state/api/entities'
import { skipToken } from '@reduxjs/toolkit/query/react'
import { useEffect } from 'react'
import { updateEngineApp } from '@/state/engine/engine'

/**
 * Reacts to entities, scene changes and update the engine
 * This is a replacement for the original approach I did of using listeners with RTk. This is better though so it stays on a per-component basis, e.g. allows for multiple apps (not sure if we ever will, but makes sense to architect it correctly and not assume single global engine/app)
 */
export const useSpaceEngine = () => {
  const currentScene = useAppSelector(selectCurrentScene)
  const {
    data: entities,
    isSuccess: isSuccessGettingEntities,
    error
  } = useGetAllEntitiesQuery(currentScene?.id || skipToken)

  useEffect(() => {
    if (entities) {
      console.log('Running engine update for entities:', entities)
      // Add any additional logic you want to execute when entities change
      updateEngineApp(entities)
    }
  }, [entities])

  return {
    currentScene,
    entities,
    isSuccessGettingEntities,
    error
  }
}
