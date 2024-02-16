import { afterAll, beforeAll, expect, it, describe } from 'vitest'
import { INestApplication } from '@nestjs/common'
import { Test } from '@nestjs/testing'
import request from 'supertest'
import { AppModule } from '../../src/app.module'
import {
  clearTestDatabase,
  createTestAccountOnFirebaseAndDb,
  initTestMongoDbWithSeed,
  safetyCheckDatabaseForTest
} from './e2e-db-util'
import { deleteFirebaseTestAccount, getFirebaseToken } from './e2e-auth'
import jwt_decode from 'jwt-decode'
import { BLOCK_TYPE } from '../../src/option-sets/block-type'

describe('E2E: Block', () => {
  let app: INestApplication
  let mongoDbUrl
  let dbName
  let userXAuthToken
  let createdUserXId
  let userXAccountEmail
  let userXAccountPassword
  let userYAuthToken
  let createdUserYId
  let userYAccountEmail
  let userYAccountPassword

  beforeAll(async () => {
    // this is e2e, so we don't want to override ANYTHING if possible. We're only mocking the DB so that it doesn't hit a deployed intstance. You can use localhost if you wish (change useInMemoryMongo and dropMongoDatabaseAfterTest in jest-e2e.json)

    // initTestMongoDb needs to be run first so the mongodburl can be set for the app
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

    // create an account
    const { email, password } = await createTestAccountOnFirebaseAndDb(app)
    // set the test-level variables
    userXAccountEmail = email
    userXAccountPassword = password
    const tokenResponseX = await getFirebaseToken(email, password)
    createdUserXId = tokenResponseX.localId
    console.log('createdUserXId', createdUserXId)
    userXAuthToken = tokenResponseX.idToken

    // create an account for user Y
    const { email: email2, password: password2 } =
      await createTestAccountOnFirebaseAndDb(app)
    // set the test-level variables
    userYAccountEmail = email2
    userYAccountPassword = password2
    const tokenResponseY = await getFirebaseToken(email2, password2)
    createdUserYId = tokenResponseY.localId
    console.log('createdUserYId', createdUserYId)
    userYAuthToken = tokenResponseY.idToken

    const decoded2: any = jwt_decode(userXAuthToken)
    const decoded1: any = jwt_decode(userYAuthToken)
    expect(decoded1.email).not.toEqual(decoded2.user1Email)
  })

  afterAll(async () => {
    await clearTestDatabase(mongoDbUrl, dbName)
    await deleteFirebaseTestAccount(app, userXAccountEmail)
  })

  let createdBlockId: string

  it('should fail without firebase auth', () => {
    return request(app.getHttpServer()).get(`/asset`).expect(404)
  })

  it('should create a block', () => {
    return request(app.getHttpServer())
      .post('/block')
      .send({
        name: 'Test Block',
        blockType: BLOCK_TYPE.GENERIC
      })
      .set('Authorization', `Bearer ${userXAuthToken}`)
      .expect(201)
      .then((res) => {
        expect(res.body._id).toBeDefined()
        expect(res.body.name).toEqual('Test Block')
        expect(res.body.blockType).toEqual(BLOCK_TYPE.GENERIC)

        // Store the created block id for later use
        createdBlockId = res.body._id
      })
  })

  it('should get a block by its id', () => {
    return request(app.getHttpServer())
      .get(`/block/${createdBlockId}`)
      .set('Authorization', `Bearer ${userXAuthToken}`)
      .expect(200)
      .then((res) => {
        expect(res.body._id).toEqual(createdBlockId)
        expect(res.body.name).toEqual('Test Block')
        expect(res.body.blockType).toEqual(BLOCK_TYPE.GENERIC)
      })
  })

  it('should update a block', () => {
    return request(app.getHttpServer())
      .patch(`/block/${createdBlockId}`)
      .send({
        name: 'Updated Block'
      })
      .set('Authorization', `Bearer ${userXAuthToken}`)
      .expect(200)
      .then((res) => {
        expect(res.body._id).toEqual(createdBlockId)
        expect(res.body.name).toEqual('Updated Block')
        expect(res.body.blockType).toEqual(BLOCK_TYPE.GENERIC)
      })
  })

  it('should delete a block', () => {
    return request(app.getHttpServer())
      .delete(`/block/${createdBlockId}`)
      .set('Authorization', `Bearer ${userXAuthToken}`)
      .expect(200)
  })

  it('should not be able to get the block by its id after deletion', () => {
    return request(app.getHttpServer())
      .get(`/block/${createdBlockId}`)
      .set('Authorization', `Bearer ${userXAuthToken}`)
      .expect(404)
  })
})
