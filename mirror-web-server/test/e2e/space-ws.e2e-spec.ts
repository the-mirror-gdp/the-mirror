import { INestApplication } from '@nestjs/common'
import { Test, TestingModule } from '@nestjs/testing'
import request from 'supertest'
import { AppModule } from '../../src/app.module'
import { deleteFirebaseTestAccount, getFirebaseToken } from './e2e-auth'
import {
  clearTestDatabase,
  createTestAccountOnFirebaseAndDb,
  initTestMongoDbWithSeed,
  safetyCheckDatabaseForTest
} from './e2e-db-util'
import { afterAll, beforeAll, expect, it, describe } from 'vitest'
import { ObjectId } from 'mongodb'
import { isValidObjectId } from 'mongoose'
import { WsAdapter } from '@nestjs/platform-ws'
import WebSocket from 'ws'
import { space7ToBeCreatedPrivateIndividualOwner } from '../stubs/space.model.stub'
import { ROLE } from '../../src/roles/models/role.enum'
import { sub } from 'date-fns'
import { isAfter } from 'date-fns'
import { SPACE_TEMPLATE } from '../../src/option-sets/space-templates'
import { spaceObject3ToBeCreatedInPrivateSpace } from '../stubs/spaceObject.model.stub'

/**
 * E2E Walkthrough: https://www.loom.com/share/cea8701390bf4e7ba234cc0689830399?from_recorder=1&focus_title=1
 */

describe('WS-E2E: Space', () => {
  let app: INestApplication
  let mongoDbUrl
  let dbName
  let userXAuthToken
  let createdUserXId
  let userXAccountEmail
  let userXAccountPassword
  let profile1
  let profile2
  let WSC: WebSocket
  let privateCreatedSpace1Id
  let privateSpaceCreatedByUserX
  let privateCreatedSpaceObjectId
  let privateCreatedSpaceObject
  let WS_Url

  beforeAll(async () => {
    // this is e2e, so we don't want to override ANYTHING if possible. We're only mocking the DB so that it doesn't hit a deployed intstance. You can use localhost if you wish (change useInMemoryMongo and dropMongoDatabaseAfterTest in jest-e2e.json)

    // initTestMongoDb needs to be run first so the mongodburl can be set for the app
    const dbSetup = await initTestMongoDbWithSeed()
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule]
    }).compile()

    mongoDbUrl = dbSetup.mongoDbUrl
    dbName = dbSetup.dbName

    // extra safety check
    safetyCheckDatabaseForTest()
    // create the full app
    app = moduleRef.createNestApplication()
    app.useWebSocketAdapter(new WsAdapter(app))
    await app.init()
    // websocket setup
    const address = app.getHttpServer().listen().address()
    WS_Url = `ws://[${address.address}]:${address.port}`

    WSC = new WebSocket(WS_Url, {
      headers: { Authorization: process.env.WSS_SECRET }
    })

    // create an account
    const { email, password } = await createTestAccountOnFirebaseAndDb(app)
    // set the test-level variables
    userXAccountEmail = email
    userXAccountPassword = password
    const tokenResponse = await getFirebaseToken(email, password)
    createdUserXId = tokenResponse.localId
    userXAuthToken = tokenResponse.idToken

    // Creating two profiles
    let token
    let profile
    profile = await createTestAccountOnFirebaseAndDb(app)
    token = await getFirebaseToken(profile.email, profile.password)
    profile1 = { ...profile, ...token }
    profile = await createTestAccountOnFirebaseAndDb(app)
    token = await getFirebaseToken(profile.email, profile.password)
    profile2 = { ...profile, ...token }
  })

  afterAll(async () => {
    await clearTestDatabase(mongoDbUrl, dbName)
    await deleteFirebaseTestAccount(app, userXAccountEmail)

    // Deleting test account from firebase account
    await deleteFirebaseTestAccount(app, profile1.email)
    await deleteFirebaseTestAccount(app, profile2.email)

    WSC.close()
  })

  it('alive test: should get the version of the app', async () => {
    return request(app.getHttpServer())
      .get(`/util/version`)
      .expect(200)
      .then((res) => {
        expect(res.text).toEqual(require('../../package.json').version)
      })
  })

  it('should connect to the WebSocket server', () => {
    WSC.on('open', () => {
      expect(WSC.readyState).toEqual(WebSocket.OPEN)
    })
  })

  describe('should create,update,get and publish the space zone', () => {
    it('creates a private space (space 1)', () => {
      return request(app.getHttpServer())
        .post(`/space`)
        .send({
          ...space7ToBeCreatedPrivateIndividualOwner
        })
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(201)
        .then((res) => {
          expect(res.body._id.length).toBe(24) // mongo objectID length
          expect(res.body.name).toEqual(
            space7ToBeCreatedPrivateIndividualOwner.name
          )

          // ensure createdAt/updatedAt exist
          expect(res.body.createdAt).toBeTruthy()
          expect(res.body.updatedAt).toBeTruthy()
          // ensure createdAt/updatedAt is in the past minute
          const createdAtDate = new Date(res.body.createdAt)
          const updatedAtDate = new Date(res.body.updatedAt)
          const oneMinAgo = sub(new Date(), { minutes: 1 })
          expect(isAfter(createdAtDate, oneMinAgo)).toBeTruthy()
          expect(isAfter(updatedAtDate, oneMinAgo)).toBeTruthy()
          privateCreatedSpace1Id = res.body._id
          privateSpaceCreatedByUserX = res.body

          // ensure role is present as an _id (it won't be populated upon create)
          expect(res.body.role).toBeTruthy()

          // important: update our mock spaceobject to use this newly created Space's ID
          spaceObject3ToBeCreatedInPrivateSpace.spaceId = privateCreatedSpace1Id
        })
    })

    it('should get the created space by space ID', async () => {
      const eventData = {
        event: 'zone_get_space',
        data: { id: privateCreatedSpace1Id }
      }
      const WSC = new WebSocket(WS_Url, {
        headers: { Authorization: process.env.WSS_SECRET }
      })
      await new Promise((resolve) => {
        WSC.onopen = () => {
          WSC.send(JSON.stringify(eventData))
          resolve(true)
        }
      })
      WSC.on('message', (message) => {
        if (message) {
          const responseData = JSON.parse(message.toString())
          expect(responseData.status).toBe(200)
          expect(isValidObjectId(responseData.result._id)).toBeTruthy()
          expect(responseData.result.name).toEqual(
            privateSpaceCreatedByUserX.name
          )
          expect(responseData.result.type).toEqual(
            privateSpaceCreatedByUserX.type
          )
          expect(responseData.result.template).toEqual(
            privateSpaceCreatedByUserX.template
          )
          // ensure createdAt/updatedAt exist
          expect(responseData.result.createdAt).toBeTruthy()
          expect(responseData.result.updatedAt).toBeTruthy()
          // ensure createdAt/updatedAt is in the past minute
          const createdAtDate = new Date(responseData.result.createdAt)
          const updatedAtDate = new Date(responseData.result.updatedAt)
          const oneMinAgo = sub(new Date(), { minutes: 1 })
          expect(isAfter(createdAtDate, oneMinAgo)).toBeTruthy()
          expect(isAfter(updatedAtDate, oneMinAgo)).toBeTruthy()
          WSC.close()
        }
      })
    })

    it('should update the created space', async () => {
      const dataToUpdate = {
        name: 'Testing_Name',
        template: SPACE_TEMPLATE.GRASS
      }
      const eventData = {
        event: 'zone_update_space',
        data: { id: privateCreatedSpace1Id, dto: dataToUpdate }
      }
      WSC = new WebSocket(WS_Url, {
        headers: { Authorization: process.env.WSS_SECRET }
      })

      await new Promise((resolve) => {
        WSC.onopen = () => {
          WSC.send(JSON.stringify(eventData))
          resolve(true)
        }
      })

      WSC.on('message', (message) => {
        if (message) {
          const responseData = JSON.parse(message.toString())
          expect(responseData.status).toBe(200)
          expect(responseData.result.name).toEqual(dataToUpdate.name)
          expect(responseData.result.template).toEqual(dataToUpdate.template)

          WSC.close()
        }
      })
    })

    describe('should update the space variable', async () => {
      // creating space-object to update
      it('creates a private spaceobject in a private space', () => {
        return request(app.getHttpServer())
          .post(`/space-object`)
          .send({
            ...spaceObject3ToBeCreatedInPrivateSpace
          })
          .set('Authorization', `Bearer ${userXAuthToken}`)
          .expect(201)
          .then((res) => {
            expect(res.body._id.length).toBe(24) // mongo objectID length
            expect(res.body.name).toEqual(
              spaceObject3ToBeCreatedInPrivateSpace.name
            )

            // ensure createdAt/updatedAt exist
            expect(res.body.createdAt).toBeTruthy()
            expect(res.body.updatedAt).toBeTruthy()
            // ensure createdAt/updatedAt is in the past minute
            const createdAtDate = new Date(res.body.createdAt)
            const updatedAtDate = new Date(res.body.updatedAt)
            const oneMinAgo = sub(new Date(), { minutes: 1 })
            expect(isAfter(createdAtDate, oneMinAgo)).toBeTruthy()
            expect(isAfter(updatedAtDate, oneMinAgo)).toBeTruthy()

            // important to set for rest of tests
            privateCreatedSpaceObjectId = res.body._id
            privateCreatedSpaceObject = res.body

            // note that a role is optional for spaceobjects; they'll be default take the settings of the parent Space
          })
      })

      it('should update space variables', async () => {
        const eventData = {
          event: 'zone_update_space_variables',
          data: {
            id: privateCreatedSpace1Id,
            dto: spaceObject3ToBeCreatedInPrivateSpace
          }
        }
        WSC = new WebSocket(WS_Url, {
          headers: { Authorization: process.env.WSS_SECRET }
        })

        await new Promise((resolve) => {
          WSC.onopen = () => {
            WSC.send(JSON.stringify(eventData))
            resolve(true)
          }
        })

        WSC.on('message', (message) => {
          if (message) {
            const responseData = JSON.parse(message.toString())
            expect(
              isValidObjectId(responseData.result.spaceVariablesData)
            ).toBeTruthy()
            expect(responseData.result.name).toEqual(
              spaceObject3ToBeCreatedInPrivateSpace.name
            )
            WSC.close()
          }
        })
      })

      it('should publish space', async () => {
        const eventData = {
          event: 'zone_publish_space',
          data: {
            id: privateCreatedSpace1Id
          }
        }
        WSC = new WebSocket(WS_Url, {
          headers: { Authorization: process.env.WSS_SECRET }
        })

        await new Promise((resolve) => {
          WSC.onopen = () => {
            WSC.send(JSON.stringify(eventData))
            resolve(true)
          }
        })

        WSC.on('message', (message) => {
          if (message) {
            const responseData = JSON.parse(message.toString())
            expect(responseData.status).toBe(200)
            expect(isValidObjectId(responseData.result.spaceId)).toBeTruthy()
            WSC.close()
          }
        })
      })
    })
  })
})
