import { useAppSelector } from '@/hooks/hooks'
import { DatabaseEntity, useGetAllEntitiesQuery } from '@/state/api/entities'
import { useGetSingleSpaceQuery } from '@/state/api/spaces'
import { selectCurrentScene } from '@/state/local.slice'
import { skipToken } from '@reduxjs/toolkit/query'
import { useEffect, useState } from 'react'
import * as pc from 'playcanvas'
import { SceneId } from '@/state/api/scenes'
import { getApp } from '@/components/engine/__start-custom__'

export const setUpSpace = (
  currentScene: SceneId,
  entities: DatabaseEntity[]
) => {
  // const [hasSetUpEntities, setHasSetUpEntities] = useState(false)
  // const {
  //   data: space,
  //   error: spaceError,
  //   isSuccess: isSuccessGetSingleSpace,
  //   isLoading,
  //   isUninitialized,
  //   isError
  // } = useGetSingleSpaceQuery(spaceId || skipToken)
  // const currentScene = useAppSelector(selectCurrentScene)
  // if (!currentScene) {
  //   return
  // }
  // const { data: entities, error } = useGetAllEntitiesQuery(currentScene.id)

  // useEffect(() => {
  // only run setup once
  // if (hasSetUpEntities) {
  //   return
  // }

  // add the entities to the scene/engine
  // if (entities && entities.length > 0) {
  // Initialize PlayCanvas app
  // const app = new pc.Application(document.getElementById('canvas'), {});
  const app = getApp()
  // Create a camera
  const camera = new pc.Entity('camera')
  camera.addComponent('camera', {
    clearColor: new pc.Color(0.1, 0.1, 0.1)
  })
  camera.setPosition(0, 0, 25)
  app.root.addChild(camera)

  // Create a directional light
  const light = new pc.Entity('light')
  light.addComponent('light', {
    type: 'directional',
    color: new pc.Color(1, 1, 1),
    intensity: 1
  })
  light.setEulerAngles(45, 0, 0)
  app.root.addChild(light)

  // Create a sphere
  const sphere = new pc.Entity('sphere')
  sphere.setLocalScale(0.1, 0.1, 0.1)
  sphere.addComponent('render', {
    type: 'sphere'
  })
  app.root.addChild(sphere)

  // Start the application
  // app.start();

  // Set up entities in the scene
  // entities.forEach(entity => {
  //   // Add custom logic to set up each entity
  // });

  // setHasSetUpEntities(true)
  // }
  // }, [entities, hasSetUpEntities])
}
