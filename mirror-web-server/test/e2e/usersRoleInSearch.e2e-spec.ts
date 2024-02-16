import { UpdateSpaceDto } from '../../src/space/dto/update-space.dto'
import { INestApplication } from '@nestjs/common'
import { Test } from '@nestjs/testing'
import { AppModule } from '../../src/app.module'
import request from 'supertest'
import { sub } from 'date-fns'
import { isAfter } from 'date-fns'

import { deleteFirebaseTestAccount, getFirebaseToken } from './e2e-auth'
import { print } from './e2e-util'
import {
  environmentId,
  privateSpace1DataIndividualOwned,
  privateSpaceId4GroupOwned,
  privateSpaceId1IndividualOwned,
  publicSpace3Data,
  publicSpaceId3,
  space7ToBeCreatedPrivateIndividualOwner,
  space9ToBeCreatedPublic,
  space16ToBeCreatedManyPrivateIndividualOwner,
  publicSpace21Data
} from '../stubs/space.model.stub'
import {
  initTestMongoDbWithSeed,
  safetyCheckDatabaseForTest,
  clearTestDatabase,
  createTestAccountOnFirebaseAndDb
} from './e2e-db-util'
import { ROLE } from '../../src/roles/models/role.enum'
import { cloneDeep, range } from 'lodash'
import { ObjectId } from 'mongodb'
import jwt_decode from 'jwt-decode'
import { afterAll, beforeAll, expect, it, describe } from 'vitest'
import { CreateSpaceDto } from '../../src/space/dto/create-space.dto'
import { SPACE_TYPE } from '../../src/option-sets/space'
import { SPACE_TEMPLATE } from '../../src/option-sets/space-templates'
import { BUILD_PERMISSIONS } from 'src/option-sets/build-permissions'
/**
 * E2E Walkthrough: https://www.loom.com/share/cea8701390bf4e7ba234cc0689830399?from_recorder=1&focus_title=1
 */

// TODO add back
describe('E2E: Check users role in serch', () => {
  let app: INestApplication
  let mongoDbUrl
  let dbName
  let userXAuthToken: string
  let createdUserXId
  let userXAccountEmail: string
  let userXAccountPassword: string

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

  describe('Private Space + Creation', () => {
    let privateCreatedSpaceId: string
    let spaceVersionIdForPublishedSpace: string
    // if this it() is updated, be sure to update the one in space-object.e2e-spec.ts too.
    it('creates a private space, individual owned, reads it, then deletes it', () => {
      const dto: CreateSpaceDto = {
        name: 'space7ToBeCreatedPrivateIndividualOwner',
        publicBuildPermissions: BUILD_PERMISSIONS.PRIVATE,
        template: SPACE_TEMPLATE.MARS,
        type: SPACE_TYPE.OPEN_WORLD,
        users: {} // will be set during test
        // createdAt and updatedAt should be populated by Mongoose
      }

      return request(app.getHttpServer())
        .post(`/space`)
        .send({
          ...dto
        })
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(201)
        .then((res) => {
          expect(res.body._id.length).toBe(24) // mongo objectID length
          expect(res.body.name).toEqual(dto.name)

          // ensure createdAt/updatedAt exist
          expect(res.body.createdAt).toBeTruthy()
          expect(res.body.updatedAt).toBeTruthy()
          // ensure createdAt/updatedAt is in the past minute
          const createdAtDate = new Date(res.body.createdAt)
          const updatedAtDate = new Date(res.body.updatedAt)
          const oneMinAgo = sub(new Date(), { minutes: 1 })
          expect(isAfter(createdAtDate, oneMinAgo)).toBeTruthy()
          expect(isAfter(updatedAtDate, oneMinAgo)).toBeTruthy()
          privateCreatedSpaceId = res.body._id

          // ensure role is present as an _id (it won't be populated upon create)
          expect(res.body.role).toBeTruthy()
        })
    })
    it('can get the space it just created', () => {
      return request(app.getHttpServer())
        .get(`/space/${privateCreatedSpaceId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          // ensure that it was created with the correct role for a private space
          expect(res.body.role.defaultRole).toEqual(ROLE.NO_ROLE)
          expect(res.body.role.users).toEqual({
            [createdUserXId]: ROLE.OWNER
          })

          expect(res.body._id).toEqual(privateCreatedSpaceId)
        })
    })
    it('gets only its own spaces from /me', () => {
      return request(app.getHttpServer())
        .get(`/space/me`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          // ensure length isn't 0
          expect(res.body.length).toBeGreaterThanOrEqual(1)
          res.body.forEach((space) => {
            // should be defined even if empty
            expect(space.role.users).toBeDefined()
            // Ensure only Spaces that the user owns are shown
            expect(space.role.users[createdUserXId]).toBe(ROLE.OWNER)
            expect(space.role.userGroups).toBeDefined()
          })
        })
    })
    it('creates 50 spaces', async () => {
      await Promise.all(
        // note: the below tests rely on at least 50 here being creatd
        range(0, 50).map(async (element, index) => {
          return request(app.getHttpServer())
            .post(`/space`)
            .send({
              ...space16ToBeCreatedManyPrivateIndividualOwner,
              name: 'space16ToBeCreatedManyPrivateIndividualOwner' + index
            })
            .set('Authorization', `Bearer ${userXAuthToken}`)
            .expect(201)
            .then((res) => {
              expect(res.body._id.length).toBe(24) // mongo objectID length
              expect(res.body.name).toEqual(
                space16ToBeCreatedManyPrivateIndividualOwner.name + index
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

              // ensure role is present as an _id (it won't be populated upon create)
              expect(res.body.role).toBeTruthy()
            })
        })
      )
    })
    it('gets only its own spaces from /me-v2. Pagination: default', () => {
      return request(app.getHttpServer())
        .get(`/space/me-v2`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          // ensure length isn't 0
          expect(res.body.data.length).toBeGreaterThanOrEqual(1)
          // check pagination properties
          expect(res.body.page).toBeGreaterThanOrEqual(1)
          expect(res.body.perPage).toBeGreaterThanOrEqual(1)
          expect(res.body.total).toBeGreaterThanOrEqual(51)
          expect(res.body.totalPage).toBeGreaterThanOrEqual(1)

          res.body.data.forEach((space) => {
            // should be defined even if empty
            expect(space.role).toBeDefined()
            expect(space.role.users).toBeDefined()
            // Ensure only Spaces that the user owns are shown
            if (space.role.defaultRole !== ROLE.OWNER) {
              expect(space.role.users[createdUserXId]).toBe(ROLE.OWNER)
            }
            expect(space.role.userGroups).toBeDefined()
          })
        })
    })
    it('gets only its own spaces from /me-v2. Pagination: perPage: 10', () => {
      return request(app.getHttpServer())
        .get(`/space/me-v2?perPage=10&page=2`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          // ensure length isn't 0
          expect(res.body.data.length).toBeGreaterThanOrEqual(1)
          // check pagination properties
          expect(res.body.page).toEqual(2)
          expect(res.body.perPage).toEqual(10)
          expect(res.body.total).toBeGreaterThanOrEqual(51)
          expect(res.body.totalPage).toBeGreaterThanOrEqual(4)

          res.body.data.forEach((space) => {
            // should be defined even if empty
            expect(space.role.users).toBeDefined()
            // Ensure only Spaces that the user owns are shown
            expect(space.role.users[createdUserXId]).toBe(ROLE.OWNER)
            expect(space.role.userGroups).toBeDefined()
          })
        })
    })

    it('can publish the space it just created', () => {
      return request(app.getHttpServer())
        .post(`/space/version/${privateCreatedSpaceId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(201)
    })
    it('does NOT have an updated activeSpaceVersion after publishing the Space because it wasnt in the dto', () => {
      return request(app.getHttpServer())
        .get(`/space/${privateCreatedSpaceId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body.activeSpaceVersion).toBeUndefined()
        })
    })
    it('can publish the space it just created with updateSpaceWithActiveSpaceVersion: true', () => {
      return request(app.getHttpServer())
        .post(`/space/version/${privateCreatedSpaceId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .send({
          updateSpaceWithActiveSpaceVersion: true,
          name: 'testSpaceVersionName'
        })
        .expect(201)
        .then((res) => {
          spaceVersionIdForPublishedSpace = res.body._id
        })
    })
    it('has an updated activeSpaceVersion after publishing the Space', () => {
      return request(app.getHttpServer())
        .get(`/space/${privateCreatedSpaceId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          // ensure that activeSpaceVersion is there for the space it just published
          expect(res.body.activeSpaceVersion).toEqual(
            spaceVersionIdForPublishedSpace
          )
        })
    })

    it('get a list of play spaces', () => {
      return request(app.getHttpServer())
        .get(`/space/get-published-spaces`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body).toBeTruthy()
          expect(res.body.page).toBeDefined()
          expect(res.body.perPage).toBeDefined()
          expect(res.body.total).toBeDefined()
          expect(res.body.totalPage).toBeDefined()
          expect(res.body.data).toBeTruthy()

          expect(res.body.data.length).toBeGreaterThanOrEqual(1)

          res.body.data.forEach((space) => {
            // should be defined even if empty
            expect(space.activeSpaceVersion).toBeTruthy()
          })
        })
    })
    it('can delete the space it just created', () => {
      return request(app.getHttpServer())
        .delete(`/space/${privateCreatedSpaceId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body._id).toBe(privateCreatedSpaceId)
        })
    })
    it('can no longer get the deleted space', () => {
      return request(app.getHttpServer())
        .get(`/space/${privateCreatedSpaceId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(404)
    })
  })

  it('should return only spaces with the defaultRole === OBSERVER for unauthorized users', async () => {
    return request(app.getHttpServer())
      .get(`/space/discover-v3`)
      .set('Origin', process.env.ALLOWED_DOMAINS.split(',')[0])
      .expect(200)
      .then((res) => {
        expect(res.body).toBeTruthy()
        res.body.data.forEach((space) => {
          expect(space.role.defaultRole === ROLE.OBSERVER).toBeTruthy()
        })
      })
  })

  it('should return spaces with the defaultRole greater than or equal to ROLE OBSERVER and must have one or more spaces with defaultRole greater than OBSERVER for authorized users', async () => {
    return request(app.getHttpServer())
      .get(`/space/discover-v3`)
      .set('Authorization', `Bearer ${userXAuthToken}`)
      .expect(200)
      .then((res) => {
        expect(res.body).toBeTruthy()

        res.body.data.forEach((space) => {
          expect(space.role.defaultRole >= ROLE.OBSERVER).toBeTruthy()
        })

        const spacesWithDefaultRoleGreaterThanObserver = res.body.data.filter(
          (space) => space.role.defaultRole > ROLE.OBSERVER
        )
        expect(
          spacesWithDefaultRoleGreaterThanObserver.length >= 1
        ).toBeTruthy()
      })
  })
})
