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
/**
 * E2E Walkthrough: https://www.loom.com/share/cea8701390bf4e7ba234cc0689830399?from_recorder=1&focus_title=1
 */

describe('WS-E2E : script entity', () => {
  let app: INestApplication
  let mongoDbUrl
  let dbName
  let userXAuthToken
  let createdUserXId
  let userXAccountEmail
  let userXAccountPassword
  let WSC: WebSocket
  let WS_Url
  let createdScript

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

  it('should create script entity', async () => {
    const eventData = {
      event: 'zone_create_script_entity',
      data: {
        dto: {
          scripts: [{ say: 'Hellow' }]
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
        resolve(true)
        if (message) {
          const responseData = JSON.parse(message.toString())
          expect(responseData.status).toBe(200)
          expect(Array.isArray(responseData.result.scripts)).toBeTruthy()
          expect(responseData.result.scripts).toEqual(
            eventData.data.dto.scripts
          )
          createdScript = responseData.result
          WSC.close()
          resolve(true)
        }
      })
    })
  })

  it('should get script entity by id', async () => {
    const eventData = {
      event: 'zone_get_script_entity',
      data: {
        id: createdScript._id
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
        resolve(true)
        if (message) {
          const responseData = JSON.parse(message.toString())
          expect(responseData.status).toBe(200)
          expect(Array.isArray(responseData.result.scripts)).toBeTruthy()
          expect(responseData.result.scripts).toEqual(createdScript.scripts)
          WSC.close()
          resolve(true)
        }
      })
    })
  })

  it('should update script entity', async () => {
    const eventData = {
      event: 'zone_update_script_entity',
      data: {
        id: createdScript._id,
        dto: {
          scripts: [{ say: 'Happy coding :)' }]
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
        resolve(true)
        if (message) {
          const responseData = JSON.parse(message.toString())
          expect(responseData.status).toBe(200)
          expect(Array.isArray(responseData.result.scripts)).toBeTruthy()
          expect(responseData.result.scripts).toEqual(
            eventData.data.dto.scripts
          )
          WSC.close()
          resolve(true)
        }
      })
    })
  })

  it('should delete script entity', async () => {
    const eventData = {
      event: 'zone_delete_script_entity',
      data: {
        id: createdScript._id
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
        resolve(true)
        if (message) {
          const responseData = JSON.parse(message.toString())
          expect(responseData.status).toBe(200)
          WSC.close()
          resolve(true)
        }
      })
    })
  })
})
