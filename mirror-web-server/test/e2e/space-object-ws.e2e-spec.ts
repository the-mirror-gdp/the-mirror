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
import { WsAdapter } from '@nestjs/platform-ws'
import WebSocket from 'ws'
import { spaceObject1InPrivateSpace } from '../stubs/spaceObject.model.stub'
import { ObjectId } from 'mongodb'
import { isValidObjectId } from 'mongoose'

/**
 * E2E Walkthrough: https://www.loom.com/share/cea8701390bf4e7ba234cc0689830399?from_recorder=1&focus_title=1
 */

describe('WS-E2E : Space object', () => {
  let app: INestApplication
  let mongoDbUrl
  let dbName
  let userXAuthToken
  let createdUserXId
  let userXAccountEmail
  let userXAccountPassword
  let createdSpaceObject
  let WSC: WebSocket
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
  })

  afterAll(async () => {
    await clearTestDatabase(mongoDbUrl, dbName)
    await deleteFirebaseTestAccount(app, userXAccountEmail)

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

  it('should create  the space object', async () => {
    const spaceObjectToBeCreated: any = spaceObject1InPrivateSpace
    spaceObjectToBeCreated._id = new ObjectId()
    spaceObjectToBeCreated.creatorUserId = spaceObject1InPrivateSpace.creator

    const eventData = {
      event: 'zone_create_space_object',
      data: { dto: spaceObjectToBeCreated }
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
    await new Promise((resolve) => {
      WSC.on('message', (message) => {
        expect(message).toBeDefined()
        if (message) {
          const responseData = JSON.parse(message.toString())
          expect(responseData.status).toBe(200)
          expect(isValidObjectId(responseData.result._id)).toBeTruthy()
          expect(responseData.result.name).toEqual(spaceObjectToBeCreated.name)
          expect(responseData.result.creator).toEqual(
            spaceObjectToBeCreated.creatorUserId
          )
          expect(responseData.result.space).toEqual(
            spaceObjectToBeCreated.space
          )
          expect(responseData.result.position).toEqual(
            spaceObjectToBeCreated.position
          )
          expect(responseData.result.rotation).toEqual(
            spaceObjectToBeCreated.rotation
          )
          createdSpaceObject = responseData.result
          resolve(true)

          WSC.close()
        }
      })
    })
  })

  it('should get  the space object', async () => {
    const eventData = {
      event: 'zone_get_space_object',
      data: {
        id: createdSpaceObject._id,
        populateParent: true,
        recursiveParentPopulate: true,
        recursiveChildrenPopulate: true
      }
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
    await new Promise((resolve) => {
      WSC.on('message', (message) => {
        expect(message).toBeDefined()
        if (message) {
          const responseData = JSON.parse(message.toString())
          expect(responseData.status).toBe(200)
          expect(responseData.status).toBe(200)
          expect(isValidObjectId(responseData.result._id)).toBeTruthy()
          expect(responseData.result.name).toEqual(createdSpaceObject.name)
          expect(responseData.result.creator).toEqual(
            createdSpaceObject.creator
          )
          expect(responseData.result.space).toEqual(createdSpaceObject.space)
          expect(responseData.result.position).toEqual(
            createdSpaceObject.position
          )
          expect(responseData.result.rotation).toEqual(
            createdSpaceObject.rotation
          )
          WSC.close()
          resolve(true)
        }
      })
    })
  })

  it('should update  the space object', async () => {
    const eventData = {
      event: 'zone_update_space_object',
      data: {
        id: createdSpaceObject._id,
        dto: {
          name: 'demo',
          description: 'demo description'
        }
      }
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
    await new Promise((resolve) => {
      WSC.on('message', (message) => {
        expect(message).toBeDefined()
        if (message) {
          const responseData = JSON.parse(message.toString())
          expect(responseData.status).toBe(200)
          expect(responseData.status).toBe(200)
          expect(isValidObjectId(responseData.result._id)).toBeTruthy()
          expect(responseData.result.name).toEqual('demo')
          expect(responseData.result.description).toEqual('demo description')

          WSC.close()
          resolve(true)
        }
      })
    })
  })

  it('should get  page data', async () => {
    const eventData = {
      event: 'zone_get_space_objects_page',
      data: {
        id: createdSpaceObject.space,
        page: 1,
        perPage: 10
      }
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
    await new Promise((resolve) => {
      WSC.on('message', (message) => {
        expect(message).toBeDefined()
        if (message) {
          const responseData = JSON.parse(message.toString())
          expect(responseData.status).toBe(200)
          expect(Array.isArray(responseData.result)).toBeTruthy()
          WSC.close()
          resolve(true)
        }
      })
    })
  })

  it('should get  batch_space_objects', async () => {
    const eventData = {
      event: 'zone_get_batch_space_objects',
      data: {
        batch: [createdSpaceObject._id],
        page: 1,
        perPage: 10
      }
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
    await new Promise((resolve) => {
      WSC.on('message', (message) => {
        expect(message).toBeDefined()
        if (message) {
          const responseData = JSON.parse(message.toString())
          expect(responseData.status).toBe(200)
          expect(Array.isArray(responseData.result)).toBeTruthy()
          WSC.close()
          resolve(true)
        }
      })
    })
  })

  it('should get preload_space_objects', async () => {
    const eventData = {
      event: 'zone_get_preload_space_objects',
      data: {
        id: createdSpaceObject._id,
        page: 1,
        perPage: 10
      }
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
    await new Promise((resolve) => {
      WSC.on('message', (message) => {
        expect(message).toBeDefined()
        if (message) {
          const responseData = JSON.parse(message.toString())
          expect(responseData.status).toBe(200)
          expect(Array.isArray(responseData.result)).toBeTruthy()
          WSC.close()
          resolve(true)
        }
      })
    })
  })

  it('should update batch_space_objects', async () => {
    const eventData = {
      event: 'zone_update_batch_space_objects',
      data: {
        batch: [
          {
            id: createdSpaceObject._id.toString()
          }
        ]
      }
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
    await new Promise((resolve) => {
      WSC.on('message', (message) => {
        expect(message).toBeDefined()
        if (message) {
          const responseData = JSON.parse(message.toString())
          expect(responseData.status).toBe(200)
          expect(responseData.result.modifiedCount).toBeGreaterThan(0)
          WSC.close()
          resolve(true)
        }
      })
    })
  })

  it('should delete  the space object', async () => {
    const eventData = {
      event: 'zone_delete_space_object',
      data: {
        id: createdSpaceObject._id
      }
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
    await new Promise((resolve) => {
      WSC.on('message', (message) => {
        expect(message).toBeDefined()
        if (message) {
          const responseData = JSON.parse(message.toString())
          expect(responseData.status).toBe(200)
          expect(responseData.result._id).toEqual(createdSpaceObject._id)
          WSC.close()
          return resolve(true)
        }
      })
    })
  })

  it('should delete  batch space object', async () => {
    const eventData = {
      event: 'zone_delete_batch_space_objects',
      data: {
        batch: []
      }
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
    await new Promise((resolve) => {
      WSC.on('message', (message) => {
        expect(message).toBeDefined()
        if (message) {
          const responseData = JSON.parse(message.toString())
          expect(responseData.status).toBe(200)
          WSC.close()
          return resolve(true)
        }
      })
    })
  })
})
