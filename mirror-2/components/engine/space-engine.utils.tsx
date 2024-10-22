import { getApp } from '@/components/engine/__start-custom__'
import { createBuildModeCameraScript } from '@/components/engine/non-game-context/camera-build-mode'
import { createEntityPickerScript } from '@/components/engine/non-game-context/entity-select'
import { DatabaseEntity } from '@/state/api/entities'
import { SceneId } from '@/state/api/scenes'
import * as pc from 'playcanvas'
// import '@/components/engine/non-game-context/camera-build-mode.ts'

export const setUpSpace = async (
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

  // skydome
  const atlas = new pc.Asset(
    'env-atlas',
    'texture',
    { url: '/helipad-env-atlas.png' },
    { type: pc.TEXTURETYPE_RGBP, mipmaps: false }
  )
  const assetListLoader = new pc.AssetListLoader([atlas], app.assets)
  assetListLoader.load(() => {
    app.scene.envAtlas = atlas.resource
    app.scene.skyboxMip = 1
    app.scene.exposure = 2
  })

  // Create a camera
  const camera = new pc.Entity('camera')
  camera.addComponent('camera', {
    clearColor: new pc.Color(0.1, 0.1, 0.1)
  })
  camera.setPosition(0, 0, 7.5)

  camera.addComponent('script')
  const BuildModeCamera = createBuildModeCameraScript(camera)
  const EntitySelect = createEntityPickerScript()
  camera.script.create(BuildModeCamera)
  camera.script.create(EntitySelect)
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
  const sphere = new pc.Entity('spheretest')
  sphere.setLocalScale(1.1, 1.1, 1.1)
  sphere.setLocalPosition(0.1, 1.1, 0.1)
  sphere.addComponent('render', {
    type: 'sphere'
  })
  sphere.addComponent('collision', {
    type: 'sphere',
    halfExtents: new pc.Vec3(0.55, 0.55, 0.55)
  })
  sphere.addComponent('rigidbody', {
    type: 'static'
  })
  app.root.addChild(sphere)

  const sphere2 = new pc.Entity('spheretest2')
  sphere2.setLocalScale(1.1, 1.1, 1.1)
  sphere2.setLocalPosition(2.1, 1.1, 0.1)
  sphere2.addComponent('render', {
    type: 'box'
  })
  sphere2.addComponent('collision', {
    type: 'box',
    halfExtents: new pc.Vec3(0.55, 0.55, 0.55)
  })
  sphere2.addComponent('rigidbody', {
    type: 'static'
  })
  app.root.addChild(sphere2)

  // create gizmos
  const gizmoLayer = new pc.Layer({
    name: 'Gizmo',
    clearDepthBuffer: true,
    opaqueSortMode: pc.SORTMODE_NONE,
    transparentSortMode: pc.SORTMODE_NONE
  })
  const layers = app.scene.layers
  layers.push(gizmoLayer)
  camera.camera.layers = camera.camera.layers.concat(gizmoLayer.id)

  const translateGizmo = new pc.TranslateGizmo(app, camera.camera, gizmoLayer)
  const rotateGizmo = new pc.RotateGizmo(app, camera.camera, gizmoLayer)
  const scaleGizmo = new pc.ScaleGizmo(app, camera.camera, gizmoLayer)
  translateGizmo.attach([sphere])
  // rotateGizmo.attach([sphere])
  // scaleGizmo.attach([sphere])

  // // Create a sphere
  // const sphere = new pc.Entity('spheretest')
  // sphere.setLocalScale(1.1, 1.1, 1.1)
  // sphere.setLocalPosition(0.1, 1.1, 0.1)
  // sphere.addComponent('render', {
  //   type: 'sphere'
  // })
  // app.root.addChild(sphere)
  app.mouse.disableContextMenu()
  // Start the application
  // app.start()
  // Set up entities in the scene
  entities.forEach((entity) => {
    // Add custom logic to set up each entity
  })
  // setHasSetUpEntities(true)
  // }
  // }, [entities, hasSetUpEntities])
  // }, [])
}
