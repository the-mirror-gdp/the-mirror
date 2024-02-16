import { INestApplication, Logger } from '@nestjs/common'
import { Test } from '@nestjs/testing'
import request from 'supertest'
import { AppModule } from '../../src/app.module'
import { deleteFirebaseTestAccount, getFirebaseToken } from './e2e-auth'
import {
  clearTestDatabase,
  createTestAccountOnFirebaseAndDb,
  initTestMongoDbWithSeed,
  safetyCheckDatabaseForTest
} from './e2e-db-util'
import { afterAll, beforeAll, expect, it, describe, vi, Mocked } from 'vitest'
import { ObjectId } from 'mongodb'
import { isValidObjectId } from 'mongoose'
import { USER_AVATAR_TYPE } from '../../src/option-sets/user-avatar-types'
import {
  ENTITY_TYPE,
  USER_ENTITY_ACTION_TYPE
} from '../../src/user/models/user-entity-action.schema'
import { ENTITY_TYPE_AVAILABLE_TO_PURCHASE } from '../../src/user/models/user-cart.schema'
import { CreateUserWithEmailPasswordDto } from '../../src/auth/dto/CreateUserWithEmailPasswordDto'
import { generateRandomE2EEmail, generateRandomName } from './e2e-util'

import { ExecutionContext } from '@nestjs/common'
import { Reflector } from '@nestjs/core'
import {
  AuthGuardFirebase,
  FirebaseTokenAuthGuard
} from '../../src/auth/auth.guard'
import { FirebaseAuthenticationService } from '../../src/firebase/firebase-authentication.service'
import { UserToken, UserTokenData } from '../../src/auth/get-user.decorator'

/**
 * E2E Walkthrough: https://www.loom.com/share/cea8701390bf4e7ba234cc0689830399?from_recorder=1&focus_title=1
 */

describe('E2E: Auth', () => {
  let app: INestApplication
  let mongoDbUrl
  let dbName
  let userXAuthToken
  let createdUserXId
  let userXAccountEmail
  let userXAccountPassword
  let profile1
  let profile2
  const email = generateRandomE2EEmail()
  const password = generateRandomName()

  const userToBeCreate: CreateUserWithEmailPasswordDto = {
    email,
    password,
    displayName: `E2E-Test-${email}`
  }

  let authGuardFirebase: AuthGuardFirebase

  beforeAll(async () => {
    // this is e2e, so we don't want to override ANYTHING if possible. We're only mocking the DB so that it doesn't hit a deployed intstance. You can use localhost if you wish (change useInMemoryMongo and dropMongoDatabaseAfterTest in jest-e2e.json)

    // initTestMongoDb needs to be run first so the mongodburl can be set for the app
    const dbSetup = await initTestMongoDbWithSeed()
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule]
    }).compile()
    mongoDbUrl = dbSetup.mongoDbUrl
    dbName = dbSetup.dbName

    authGuardFirebase = moduleRef.get<AuthGuardFirebase>(AuthGuardFirebase)

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

  it('should create user with email-password', async () => {
    return request(app.getHttpServer())
      .post(`/auth/email-password`)
      .send(userToBeCreate)
      .expect(201)
      .then((res) => {
        const { user } = res.body
        expect(user).toBeDefined()
        expect(user.email).toEqual(userToBeCreate.email)
        expect(user.displayName).toEqual(userToBeCreate.displayName)
        expect(user.password).toBeUndefined()
        expect(user.firebaseUID).toBeDefined()
        expect(isValidObjectId(user.firebaseUID)).toBeTruthy()
      })
  })

  describe('E2E: AuthGuardFirebase', async () => {
    it('should defined the AuthGuardFirebase', () => {
      expect(authGuardFirebase).toBeDefined()
    })

    it('should fail with empty jwt', async () => {
      const mockExecutionContext: ExecutionContext = {
        switchToHttp: () => ({
          getRequest: () => ({
            headers: {}
          })
        }),
        getClass: () => ({}),
        getHandler: () => ({})
      } as ExecutionContext

      const canActivate = await authGuardFirebase
        .canActivate(mockExecutionContext as ExecutionContext)
        .then((res) => res)
        .catch((error) => error)
      expect(canActivate).toBeFalsy()
    })

    it('should fail with invalid jwt', async () => {
      const mockExecutionContext: ExecutionContext = {
        switchToHttp: () => ({
          getRequest: () => ({
            headers: {
              authorization: 'Bearer invalidtoken'
            }
          })
        }),
        getClass: () => ({}),
        getHandler: () => ({})
      } as ExecutionContext

      const canActivate = await authGuardFirebase
        .canActivate(mockExecutionContext as ExecutionContext)
        .then((res) => res)
        .catch((error) => {
          expect(error.response.statusCode).toBe(405)
          return false
        })
      expect(canActivate).toBeFalsy()
    })

    it('should pass with valid jwt', async () => {
      const mockExecutionContext: ExecutionContext = {
        switchToHttp: () => ({
          getRequest: () => ({
            headers: { authorization: `Bearer ${userXAuthToken}` }
          })
        }),
        getClass: () => ({}),
        getHandler: () => ({})
      } as ExecutionContext

      const canActivate = await authGuardFirebase
        .canActivate(mockExecutionContext as ExecutionContext)
        .then((res) => res)
        .catch((error) => false)

      expect(canActivate).toBeTruthy()
    })
  })
})
