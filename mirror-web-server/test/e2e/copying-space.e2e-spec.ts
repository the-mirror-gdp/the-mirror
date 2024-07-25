import { INestApplication } from '@nestjs/common'
import { Test } from '@nestjs/testing'
import { AppModule } from '../../src/app.module'
import request from 'supertest'

import { deleteFirebaseTestAccount, getFirebaseToken } from './e2e-auth'

import {
  initTestMongoDbWithSeed,
  safetyCheckDatabaseForTest,
  clearTestDatabase,
  createTestAccountOnFirebaseAndDb
} from './e2e-db-util'
import { ObjectId } from 'mongodb'
import jwt_decode from 'jwt-decode'
import { afterAll, beforeAll, expect, it, describe } from 'vitest'
import { CreateSpaceDto } from '../../src/space/dto/create-space.dto'
import { SPACE_TYPE } from '../../src/option-sets/space'
import { SPACE_TEMPLATE } from '../../src/option-sets/space-templates'
import { BUILD_PERMISSIONS } from '../../src/option-sets/build-permissions'
import { CreateTerrainDto } from '../../src/terrain/dto/create-terrain.dto'
import { CreateSpaceObjectDto } from '../../src/space-object/dto/create-space-object.dto'
import { CreateAssetDto } from '../../src/asset/dto/create-asset.dto'
import { ASSET_TYPE } from '../../src/option-sets/asset-type'
import { CreateScriptEntityDto } from '../../src/script-entity/dto/create-script-entity.dto'
import { ROLE } from '../../src/roles/models/role.enum'
import { create } from 'lodash'
/**
 * E2E Walkthrough: https://www.loom.com/share/cea8701390bf4e7ba234cc0689830399?from_recorder=1&focus_title=1
 */

// TODO add back
describe('E2E: Check copying space', () => {
  let app: INestApplication
  let mongoDbUrl
  let dbName
  let userXAccountEmail: string
  let privateSpaceCreatedByUserXSpaceId
  let privateSpaceCreatedByUserX
  let user1Id
  let userYAuthToken
  let userYEmail
  let userYPassword

  let userZId
  let userZAuthToken
  let userZEmail
  let userZPassword

  //space 1
  let space1
  let terrain1
  let environment1
  const space1Assets = []
  const space1SpaceObjects = []
  const space1Scripts = []
  // space 2 (copied space)
  let space2
  let terrain2
  let environment2
  const space2Assets = []
  const space2SpaceObjects = []

  beforeAll(async () => {
    const dbSetup = await initTestMongoDbWithSeed()
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule]
    }).compile()
    mongoDbUrl = dbSetup.mongoDbUrl
    dbName = dbSetup.dbName

    // extra safety check
    safetyCheckDatabaseForTest()
    // create the full app
    app = moduleRef.createNestApplication()
    await app.init()

    // create user 1
    const { email, password } = await createTestAccountOnFirebaseAndDb(app)
    // set the test-level variables
    userYEmail = email
    userYPassword = password
    const tokenResponse = await getFirebaseToken(email, password)
    user1Id = tokenResponse.localId
    userYAuthToken = tokenResponse.idToken

    // create user 2
    const { email: email2, password: password2 } =
      await createTestAccountOnFirebaseAndDb(app)
    // set the test-level variables
    userZEmail = email2
    userZPassword = password2
    const tokenResponse2 = await getFirebaseToken(userZEmail, userZPassword)
    userZId = tokenResponse2.localId
    userZAuthToken = tokenResponse2.idToken

    const decoded1: any = jwt_decode(userYAuthToken)
    const decoded2: any = jwt_decode(userZAuthToken)
    expect(decoded1.email).not.toEqual(decoded2.user1Email)
  })

  afterAll(async () => {
    await clearTestDatabase(mongoDbUrl, dbName)
    await deleteFirebaseTestAccount(app, userXAccountEmail)
  })

  it('alive test: should get the version of the app', async () => {
    return request(app.getHttpServer())
      .get(`/util/version`)
      .expect(200)
      .then((res) => {
        expect(res.text).toEqual(require('../../package.json').version)
      })
  })

  it('User Y creates a space with space-objects', async () => {
    // create terrain for space
    const terrainToCreate: CreateTerrainDto = {
      name: 'terrain for space coping test ',
      description: 'Mirror Terrain Description'
    }

    const terrain = await request(app.getHttpServer())
      .post(`/terrain`)
      .set('Authorization', `Bearer ${userYAuthToken}`)
      .send(terrainToCreate)
      .expect(201)
      .then((res) => {
        terrain1 = res.body
        return res.body
      })

    // create environment for space
    const environment = await request(app.getHttpServer())
      .post(`/environment`)
      .set('Authorization', `Bearer ${userYAuthToken}`)
      .expect(201)
      .then((res) => {
        environment1 = res.body
        return res.body
      })

    const spaceToCreate: CreateSpaceDto = {
      name: 'space 1 for space coping test',
      publicBuildPermissions: BUILD_PERMISSIONS.OBSERVER,
      template: SPACE_TEMPLATE.MARS,
      type: SPACE_TYPE.OPEN_WORLD,
      terrain: terrain._id.toString(),
      environment: environment._id.toString(),
      users: { [userZId]: ROLE.OWNER }
    }

    // create the space
    const space = await request(app.getHttpServer())
      .post(`/space`)
      .set('Authorization', `Bearer ${userYAuthToken}`)
      .send(spaceToCreate)
      .expect(201)
      .then((res) => {
        privateSpaceCreatedByUserXSpaceId = res.body._id
        privateSpaceCreatedByUserX = res.body
        space1 = res.body
        return res.body
      })

    // add space-objects with assets to the space
    for (let i = 0; i < 10; i++) {
      const assetToCreate: CreateAssetDto = {
        name: `asset ${i} for space 1 coping test`,
        description: 'Mirror Asset Description',
        assetType: ASSET_TYPE.IMAGE
      }

      const asset = await request(app.getHttpServer())
        .post(`/asset`)
        .set('Authorization', `Bearer ${userYAuthToken}`)
        .send(assetToCreate)
        .expect(201)
        .then((res) => {
          return res.body
        })
      space1Assets.push(asset)

      const spaceObjectToCreate: CreateSpaceObjectDto = {
        name: `space object ${i} for space 1 coping test`,
        spaceId: space._id.toString(),
        asset: asset._id.toString()
      }

      const spaceObject = await request(app.getHttpServer())
        .post(`/space-object`)
        .set('Authorization', `Bearer ${userYAuthToken}`)
        .send(spaceObjectToCreate)
        .expect(201)
        .then((res) => {
          return res.body
        })
      space1SpaceObjects.push(spaceObject)

      // add script to the space
      const scriptToCreate: CreateScriptEntityDto = {
        blocks: [
          { type: 'start', next: 'end' },
          { type: 'end', next: null }
        ],
        defaultRole: ROLE.OBSERVER
      }

      const script = await request(app.getHttpServer())
        .post(`/script-entity`)
        .set('Authorization', `Bearer ${userYAuthToken}`)
        .send(scriptToCreate)
        .expect(201)
        .then((res) => {
          return res.body
        })
      space1Scripts.push(script)
    }
    // update space 1 to add scripts
    const spaceToUpdate = {
      scriptIds: space1Scripts
        .map((script) => script._id.toString())
        .slice(0, 5),
      scriptInstances: space1Scripts.slice(4).map((script) => {
        return {
          script_id: script._id.toString(),
          enabled: true,
          execute_in_editor: true
        }
      })
    }
    // update space 1
    const updatedSpace1 = await request(app.getHttpServer())
      .patch(`/space/${space1._id.toString()}`)
      .set('Authorization', `Bearer ${userYAuthToken}`)
      .send(spaceToUpdate)
      .expect(200)
      .then((res) => {
        return res.body
      })

    space1 = updatedSpace1

    return
  }, 40000)

  it('User Z copies space 1', async () => {
    // copy space
    const copiedSpace = await request(app.getHttpServer())
      .post(`/space/copy/${space1._id.toString()}`)
      .set('Authorization', `Bearer ${userZAuthToken}`)
      .expect(201)
      .then((res) => {
        space2 = res.body
        return res.body
      })

    // get the copied space space-objects
    const spaceObjects = await request(app.getHttpServer())
      .get(`/space-object/space/${copiedSpace._id.toString()}`)
      .set('Authorization', `Bearer ${userZAuthToken}`)
      .expect(200)
      .then((res) => {
        space2SpaceObjects = res.body
        return res.body
      })

    // get the copied space assets
    space2SpaceObjects.forEach(async (spaceObject) => {
      const asset = await request(app.getHttpServer())
        .get(`/asset/${spaceObject.asset.toString()}`)
        .set('Authorization', `Bearer ${userZAuthToken}`)
        .expect(200)
        .then((res) => {
          space2Assets.push(res.body)
          return res.body
        })
    })

    //get the copied space terrain
    const terrain = await request(app.getHttpServer())
      .get(`/terrain/${copiedSpace.terrain.toString()}`)
      .set('Authorization', `Bearer ${userZAuthToken}`)
      .expect(200)
      .then((res) => {
        terrain2 = res.body
        return res.body
      })

    //get the copied space environment
    const environment = await request(app.getHttpServer())
      .get(`/environment/${copiedSpace.environment.toString()}`)
      .set('Authorization', `Bearer ${userZAuthToken}`)
      .expect(200)
      .then((res) => {
        environment2 = res.body
        return res.body
      })
  }, 20000)

  it('User Z should have copied space with same space-objects and assets', async () => {
    // check if the copied space has the same space-objects and assets
    expect(space1Assets.length).toEqual(space2Assets.length)
    expect(space1SpaceObjects.length).toEqual(space2SpaceObjects.length)

    // check if terrain and environment are the same, but with different ids, owner, and created at, updated at
    expect({
      ...terrain1,
      _id: '',
      id: '',
      owner: '',
      createdAt: '',
      updatedAt: ''
    }).toEqual({
      ...terrain2,
      _id: '',
      id: '',
      owner: '',
      createdAt: '',
      updatedAt: ''
    })
    expect(terrain1._id).not.toEqual(terrain2._id)
    expect({
      ...environment1,
      id: '',
      _id: '',
      owner: '',
      createdAt: '',
      updatedAt: ''
    }).toEqual({
      ...environment2,
      id: '',
      _id: '',
      owner: '',
      createdAt: '',
      updatedAt: ''
    })
    expect(environment1._id).not.toEqual(environment2._id)

    // check if space 1 and space have the same scripts
    expect(space1.scriptIds.length).toEqual(space2.scriptIds.length)
    expect(space1.scriptInstances.length).toEqual(space2.scriptInstances.length)
    // check if copied scripts exists
    for (let i = 0; i < space2.scriptIds.length; i++) {
      const scriptId = space2.scriptIds[i]
      const script = await request(app.getHttpServer())
        .get(`/script-entity/${scriptId}`)
        .set('Authorization', `Bearer ${userZAuthToken}`)
        .expect(200)
        .then((res) => {
          return res.body
        })
      expect(script).toBeTruthy()
    }
    // check if copied script instances exists
    for (let i = 0; i < space2.scriptInstances.length; i++) {
      const scriptInstance = space2.scriptInstances[i]
      const script = await request(app.getHttpServer())
        .get(`/script-entity/${scriptInstance.script_id}`)
        .set('Authorization', `Bearer ${userZAuthToken}`)
        .expect(200)
        .then((res) => {
          return res.body
        })
      expect(script).toBeTruthy()
    }
  })
}, 20000)
