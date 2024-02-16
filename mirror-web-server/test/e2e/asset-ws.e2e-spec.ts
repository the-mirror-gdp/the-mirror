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
import { asset503ToBeCreated } from '../stubs/asset.model.stub'
import { isAfter, sub } from 'date-fns'
import { ObjectId } from 'mongodb'

/**
 * E2E Walkthrough: https://www.loom.com/share/cea8701390bf4e7ba234cc0689830399?from_recorder=1&focus_title=1
 */

describe('WS-E2E: Asset websocket', () => {
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
  let createdAssets
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

  describe('should get and update the assets', () => {
    it('should create a private asset', () => {
      return request(app.getHttpServer())
        .post(`/asset`)
        .send({
          ...asset503ToBeCreated
        })
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(201)
        .then((res) => {
          expect(res.body._id.length).toBe(24) // mongo objectID length
          expect(res.body.name).toEqual(asset503ToBeCreated.name)
          expect(res.body.creator).toEqual(createdUserXId)

          // ensure createdAt/updatedAt exist
          expect(res.body.createdAt).toBeTruthy()
          expect(res.body.updatedAt).toBeTruthy()
          // ensure createdAt/updatedAt is in the past minute
          const createdAtDate = new Date(res.body.createdAt)
          const updatedAtDate = new Date(res.body.updatedAt)
          const oneMinAgo = sub(new Date(), { minutes: 1 })
          expect(isAfter(createdAtDate, oneMinAgo)).toBeTruthy()
          expect(isAfter(updatedAtDate, oneMinAgo)).toBeTruthy()

          // note that roles is checked later in another test. To return the role data in MongoDB, we would have to run a separate query because it's a different collection

          // important to set for rest of tests
          createdAssets = res.body
        })
    })
  })

  it('should get the asset details', async () => {
    const eventData = {
      event: 'zone_get_asset',
      data: { id: createdAssets._id }
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
        const messageData = JSON.parse(message.toString())
        const responseData = messageData.result
        expect(messageData.status).toBe(200)
        expect(responseData.name).toBe(asset503ToBeCreated.name)
        expect(responseData.assetType).toBe(asset503ToBeCreated.assetType)
        expect(responseData.description).toBe(asset503ToBeCreated.description)
        expect(responseData.mirrorPublicLibrary).toBe(
          asset503ToBeCreated.mirrorPublicLibrary
        )
        // checking created tagsv2
        const tagsv2 = responseData?.tagsV2?.map((ids) => new ObjectId(ids._id))
        expect(tagsv2).toEqual(asset503ToBeCreated.tagsV2)
        expect(responseData._id.length).toBe(24) // mongo objectID length
        expect(responseData.createdAt).toBeTruthy()
        expect(responseData.updatedAt).toBeTruthy()
        const createdAtDate = new Date(responseData.createdAt)
        const updatedAtDate = new Date(responseData.updatedAt)
        const oneMinAgo = sub(new Date(), { minutes: 1 })
        expect(isAfter(createdAtDate, oneMinAgo)).toBeTruthy()
        expect(isAfter(updatedAtDate, oneMinAgo)).toBeTruthy()
        WSC.close()
      }
    })
  })

  it('should update asset', async () => {
    try {
      const dataToUpdateAsset = {
        name: 'demo asset',
        mirrorPublicLibrary: true,
        public: false
      }

      const eventData = {
        event: 'zone_update_asset',
        data: {
          id: createdAssets._id,
          dto: dataToUpdateAsset
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
          const messageData = JSON.parse(message.toString())
          const updatedResult = messageData.result
          expect(messageData.status).toBe(200)
          expect(updatedResult.name).toEqual(dataToUpdateAsset.name)
          expect(updatedResult.mirrorPublicLibrary).toEqual(
            dataToUpdateAsset.mirrorPublicLibrary
          )
          expect(updatedResult.public).toEqual(dataToUpdateAsset.public)
          WSC.close()
        }
      })
    } catch (error) {
      console.log(error)
    }
  })
})
