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
import { ZoneDocument } from './../../src/zone/zone.schema'
import { space18SeededForSeededZone } from '../stubs/space.model.stub'

/**
 * E2E Walkthrough: https://www.loom.com/share/cea8701390bf4e7ba234cc0689830399?from_recorder=1&focus_title=1
 */

describe('WS-E2E: Zone', () => {
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
    const port = process.env.PORT || 9000
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

  describe('Zone Creation and should update throw ws', () => {
    let newBuildZone: ZoneDocument
    it('Should BUILD a zone with user X', () => {
      return request(app.getHttpServer())
        .get(`/zone/join-build-server/${space18SeededForSeededZone._id}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body._id.length).toBe(24) // mongo objectID length
          // ensure createdAt/updatedAt exist
          expect(res.body.createdAt).toBeTruthy()
          expect(res.body.updatedAt).toBeTruthy()

          newBuildZone = res.body
        })
    })
    it('Should update the zone with WS', async () => {
      const dataToUpdate = {
        uuid: newBuildZone.uuid,
        players: 1,
        secondsEmpty: 1,
        version: '4.5.1',
        usersPresent: [newBuildZone.usersPresent[0]]
      }

      const eventData = {
        event: 'zone_update_status',
        data: dataToUpdate
      }

      WSC = new WebSocket(WS_Url, {
        headers: { Authorization: createdUserXId }
      })

      await new Promise((resolve) => {
        WSC.onopen = () => {
          WSC.send(JSON.stringify(eventData))
          resolve(true)
        }
      })

      WSC.on('message', (message) => {
        expect(message).toBeDefined()
        if (message) {
          const responseMessage = JSON.parse(message.toString())
          expect(responseMessage.status).toBe(200)

          WSC.close()
        }
      })
    })
  })
})
