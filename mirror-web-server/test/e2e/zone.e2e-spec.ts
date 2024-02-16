import { INestApplication } from '@nestjs/common'
import { Test } from '@nestjs/testing'
import { isAfter, sub } from 'date-fns'
import request from 'supertest'
import { AppModule } from '../../src/app.module'
import { SpaceManagerExternalService } from './../../src/zone/space-manager-external.service'
import { ZoneDocument } from './../../src/zone/zone.schema'

import { afterAll, beforeAll, describe, expect, it } from 'vitest'
import { User } from '../../src/user/user.schema'
import { spaceManagerExternalServiceMock } from '../mocks/space-manager-external-service.mock'
import { space18SeededForSeededZone } from '../stubs/space.model.stub'
import { spaceVersion2ForSpace20WithActiveSpaceVersion } from '../stubs/spaceVersion.model.stub'
import { mockUser0, mockUser1OwnerOfZone } from '../stubs/user.model.stub'
import {
  zone1ToBeCreated,
  zone4UsersPresentSeeded
} from '../stubs/zone.model.stub'
import { deleteFirebaseTestAccount, getFirebaseToken } from './e2e-auth'
import {
  clearTestDatabase,
  createTestAccountOnFirebaseAndDb,
  initTestMongoDbWithSeed,
  safetyCheckDatabaseForTest
} from './e2e-db-util'

/**
 * E2E Walkthrough: https://www.loom.com/share/cea8701390bf4e7ba234cc0689830399?from_recorder=1&focus_title=1
 */

// not working yet but partially implemented 2023-04-25 03:00:16
describe('E2E: Zone', () => {
  let app: INestApplication
  let mongoDbUrl
  let dbName
  let userXAuthToken
  let createdUserXId
  let userXAccountEmail
  let userXAccountPassword

  let userZId
  let userZAuthToken
  let userZEmail
  let userZPassword

  beforeAll(async () => {
    // this is e2e, so we don't want to override ANYTHING if possible. We're only mocking the DB so that it doesn't hit a deployed intstance. You can use localhost if you wish (change useInMemoryMongo and dropMongoDatabaseAfterTest in jest-e2e.json)

    // initTestMongoDb needs to be run first so the mongodburl can be set for the app
    const dbSetup = await initTestMongoDbWithSeed()
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule]
    })
      .overrideProvider(SpaceManagerExternalService)
      .useValue(spaceManagerExternalServiceMock)
      .compile()
    mongoDbUrl = dbSetup.mongoDbUrl
    dbName = dbSetup.dbName
    // extra safety check
    safetyCheckDatabaseForTest()
    // create the full app
    app = moduleRef.createNestApplication()
    await app.init()

    // create an account
    const { email, password } = await createTestAccountOnFirebaseAndDb(app)
    // set the test-level variables
    userXAccountEmail = email
    userXAccountPassword = password
    const tokenResponse = await getFirebaseToken(email, password)
    createdUserXId = tokenResponse.localId
    userXAuthToken = tokenResponse.idToken

    // create user 2
    const { email: email2, password: password2 } =
      await createTestAccountOnFirebaseAndDb(app)
    // set the test-level variables
    userZEmail = email2
    userZPassword = password2
    const tokenResponse2 = await getFirebaseToken(userZEmail, userZPassword)
    userZId = tokenResponse2.localId
    userZAuthToken = tokenResponse2.idToken
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

  it('should fail without firebase auth', () => {
    return request(app.getHttpServer())
      .get(`/zone/join-build-server/fakeId`)
      .expect(403)
  })

  describe('Zone Creation', () => {
    let newBuildZone: ZoneDocument
    let playServerToJoin: ZoneDocument
    let playServers: ZoneDocument[] = []
    it('requests to join a BUILD zone with user Z', () => {
      return request(app.getHttpServer())
        .get(`/zone/join-build-server/${space18SeededForSeededZone._id}`)
        .set('Authorization', `Bearer ${userZAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body._id.length).toBe(24) // mongo objectID length
          // ensure createdAt/updatedAt exist
          expect(res.body.createdAt).toBeTruthy()
          expect(res.body.updatedAt).toBeTruthy()

          newBuildZone = res.body
        })
    })
    it('can create a play server', () => {
      return request(app.getHttpServer())
        .post(
          `/zone/create-play-server/${spaceVersion2ForSpace20WithActiveSpaceVersion._id}`
        )
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(201)
        .then((res) => {
          expect(res.body).toBeDefined()
          playServerToJoin = res.body
        })
    })
    it('can get a list of play servers', () => {
      return request(app.getHttpServer())
        .get(`/zone/list-play-servers/${playServerToJoin.spaceVersion}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body).toBeDefined()
          expect(res.body.length).toBeGreaterThanOrEqual(1)
          playServers = res.body
        })
    })
    it('can update a play server', () => {
      return request(app.getHttpServer())
        .patch(`/zone/${playServers[0]._id}`)
        .send({
          name: 'new name',
          description: 'new desc'
        })
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body).toBeDefined()
          expect(res.body.name).toEqual('new name')
          expect(res.body.description).toEqual('new desc')

          // update the local variable for the other tests
          playServerToJoin.name = 'new name'
          playServerToJoin.description = 'new desc'
        })
    })
    it('requests to join a PLAY zone with a spaceVersion with user Z', () => {
      return request(app.getHttpServer())
        .get(`/zone/join-play-server/zone/${playServerToJoin._id}`)
        .set('Authorization', `Bearer ${userZAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body._id.length).toBe(24) // mongo objectID length
          expect(res.body.name).toEqual(playServerToJoin.name)
          expect(res.body.space).toEqual(playServerToJoin.space)
          expect(res.body.spaceVersion).toEqual(playServerToJoin.spaceVersion)

          // ensure createdAt/updatedAt exist
          expect(res.body.createdAt).toBeTruthy()
          expect(res.body.updatedAt).toBeTruthy()
          // ensure createdAt/updatedAt is in the past minute
          const createdAtDate = new Date(res.body.createdAt)
          const updatedAtDate = new Date(res.body.updatedAt)
          const oneMinAgo = sub(new Date(), { minutes: 1 })
          expect(isAfter(createdAtDate, oneMinAgo)).toBeTruthy()
          expect(isAfter(updatedAtDate, oneMinAgo)).toBeTruthy()
        })
    })
    it('can get the PLAY zone directly', () => {
      return request(app.getHttpServer())
        .get(`/zone/${newBuildZone._id}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body._id).toEqual(newBuildZone._id)
          expect(res.body.space).toBe(newBuildZone.space)
        })
    })
    it('can get the status of a zone via /zone/:id', () => {
      return request(app.getHttpServer())
        .get(`/zone/${newBuildZone._id}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body).toBeDefined()
          expect(res.body.name).toBe(newBuildZone.name)
          expect(res.body.space).toBe(newBuildZone.space)
          expect(res.body.description).toBe(newBuildZone.description)
        })
    })
    it('can publish a spaceVersion for that space', () => {
      return request(app.getHttpServer())
        .post(`/space/version/${zone1ToBeCreated.space}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(201)
    })
  })

  describe('Seeded Zone', () => {
    it('can check users present on the seeded zone', () => {
      return request(app.getHttpServer())
        .get(`/zone/${zone4UsersPresentSeeded._id}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body._id).toEqual(zone4UsersPresentSeeded._id?.toString())
          const usersPresent = res.body.usersPresent

          const user0 = usersPresent.find(
            (user: User) => user._id === mockUser0._id.toString()
          )
          expect(user0).toBeTruthy()
          expect(user0.displayName).toBe(mockUser0.displayName)
          expect(user0.email).toBe(mockUser0.email)

          const user1 = usersPresent.find(
            (user: User) => user._id === mockUser1OwnerOfZone._id.toString()
          )
          expect(user1).toBeTruthy()
        })
    })

    // TODO implement WS tests
    // it('should handle WebSocket messages', (done) => {
    //   ws.on('open', () => {
    //     // Send a message to the WebSocket server
    //     ws.send(
    //       JSON.stringify({
    //         event: 'your-event',
    //         data: {
    //           /* your data */
    //         }
    //       })
    //     )
    //   })

    //   ws.on('message', (message) => {
    //     const parsedMessage = JSON.parse(message.toString())

    //     // Add your test assertions here
    //     expect(parsedMessage).toBeDefined()

    //     // Signal that the test is done
    //     done()
    //   })
    // })
  })
})
