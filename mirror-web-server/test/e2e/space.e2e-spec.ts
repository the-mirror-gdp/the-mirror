import { UpdateSpaceDto } from './../../src/space/dto/update-space.dto'
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
/**
 * E2E Walkthrough: https://www.loom.com/share/cea8701390bf4e7ba234cc0689830399?from_recorder=1&focus_title=1
 */

// TODO add back
describe('E2E: Space', () => {
  let app: INestApplication
  let mongoDbUrl
  let dbName
  let userXAuthToken
  let createdUserXId
  let userXAccountEmail
  let userXAccountPassword

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

  it('should fail without firebase auth', () => {
    return request(app.getHttpServer()).get(`/space`).expect(403)
  })

  describe('Seeded Data: Individual Owner', () => {
    it('gets a public space from the seeded database', () => {
      return request(app.getHttpServer())
        .get(`/space/${publicSpaceId3}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body._id).toEqual(publicSpaceId3)
          expect(res.body.name).toEqual(publicSpace3Data.name)
          expect(res.body.role.defaultRole).toBeGreaterThanOrEqual(
            ROLE.DISCOVER
          )
          expect(res.body.createdAt).toEqual(publicSpace3Data.createdAt)
          expect(res.body.updatedAt).toEqual(publicSpace3Data.updatedAt)
          expect(res.body.environment._id).toEqual(environmentId)
          expect(res.body.environment._id).toEqual(environmentId)

          // ensure role is present
          expect(res.body.role).toBeTruthy()
        })
    })
    it('searches public spaces', () => {
      return request(app.getHttpServer())
        .get(`/space/search`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          res.body.forEach((space) => {
            // should be defined even if empty
            expect(space.role.users).toBeDefined()
            expect(space.role.userGroups).toBeDefined()

            // if user can see and user isn't in role.users, space defaultRole should be >= ROLE.DISCOVER
            if (!space.role.users[createdUserXId]) {
              expect(space.role.defaultRole).toBeDefined()
              expect(space.role.defaultRole).toBeGreaterThanOrEqual(
                ROLE.DISCOVER
              )
            }
          })
        })
    })
    it('returns a 404 for a private space where the user is NOT the individual owner & space is NOT group owned', () => {
      return request(app.getHttpServer())
        .get(`/space/${privateSpaceId1IndividualOwned}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(404)
    })
    it("denies an update to a public Space that the user doesn't own", () => {
      return request(app.getHttpServer())
        .patch(`/space/${publicSpaceId3}`)
        .send({
          name: 'hello'
        })
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(404) // 404 logic is also rejection so we don't give information that the entity exists
    })
    it("cannot delete to a public Space that the user doesn't own", () => {
      return request(app.getHttpServer())
        .delete(`/space/${publicSpaceId3}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(404)
    })
    it("cannot copy a space it doesn't have role.roleLevelRequiredToDuplicate for", () => {
      return request(app.getHttpServer())
        .post(`/space/copy/${publicSpaceId3}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(404)
    })
    it('can copy a space it DOES have roleLevelRequiredToDuplicate for', () => {
      return request(app.getHttpServer())
        .post(`/space/copy/${publicSpace21Data._id}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(201)
    })
    it("cannot publish a space it doesn't own", () => {
      return request(app.getHttpServer())
        .post(`/space/version/${publicSpaceId3}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(404)
    })
    it("cannot upload a file for a space it doesn't own", () => {
      return request(app.getHttpServer())
        .post(`/space/${publicSpaceId3}/upload/public`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(404)
    })
  })

  describe('Seeded Data: Group Owner', () => {
    it('does not get via 404 a private space where the space IS group owned ', () => {
      return request(app.getHttpServer())
        .get(`/space/${privateSpaceId4GroupOwned}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(404)
    })
  })

  describe('Private Space + Creation', () => {
    let privateCreatedSpaceId
    let spaceVersionIdForPublishedSpace
    // if this it() is updated, be sure to update the one in space-object.e2e-spec.ts too.
    it('creates a private space, individual owned, reads it, then deletes it', () => {
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
          // expect the `owners` virtual property to be populated
          expect(res.body.role.owners).toContain(createdUserXId)
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
    it('gets spaces from /discover-v2. Pagination: perPage: 10', () => {
      return request(app.getHttpServer())
        .get(`/space/discover-v2?perPage=10&page=2`)
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
            expect(space.role.users[createdUserXId]).toBeGreaterThanOrEqual(
              ROLE.DISCOVER
            )
            expect(space.role.userGroups).toBeDefined()
          })
        })
    })
    it('can see the new space when retrieving a list of spaces', () => {
      return request(app.getHttpServer())
        .get(`/space`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          // ensure length isn't 0
          expect(res.body.length).toBeGreaterThanOrEqual(1)
          // check a property: ensure that the id of the new space created is present in the list and the name lines up with what was just created
          res.body.forEach((space) => {
            expect(space._id).toBeDefined()
            // ensure a (seeded) private Space does NOT appear in the list of spaces for the user
            expect(space._id).not.toEqual(privateSpace1DataIndividualOwned._id)
            // check data for the space we just created
            if (space._id === privateCreatedSpaceId) {
              expect(space.name, space).toEqual(
                space7ToBeCreatedPrivateIndividualOwner.name
              )
              expect(space.role.defaultRole).toBeLessThanOrEqual(ROLE.DISCOVER)
              expect(space.environment._id).toBeTruthy()
              // ensure role is present as a populated document (unlike the return data from create above where we only check that .role is present as an _id, this is a new GET to the server and should return the populated document)
              expect(space.role._id).toBeTruthy()
            }
          })
        })
    })
    it('can copy the space it just created', () => {
      return request(app.getHttpServer())
        .post(`/space/copy/${privateCreatedSpaceId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(201)
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

  describe('Private Space Creation: Role access checks', () => {
    let privateSpaceCreatedByUserXSpaceId
    let privateSpaceCreatedByUserX
    let user1Id
    let userYAuthToken
    let userYEmail
    let userYPassword
    const userGroupId = new ObjectId().toString()
    let userZId
    let userZAuthToken
    let userZEmail
    let userZPassword
    const testWssSecret = 'testWssSecret'
    beforeAll(async () => {
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
      process.env.WSS_SECRET = testWssSecret
    })
    it('user X creates a private space, individual owned, reads it, then checks access for another user', () => {
      // clone so that we don't interfere with other tests
      const space = cloneDeep(space7ToBeCreatedPrivateIndividualOwner)
      space.users = {
        [user1Id]: ROLE.OBSERVER
      }
      space.userGroups = {
        [userGroupId]: ROLE.CONTRIBUTOR
      }
      return request(app.getHttpServer())
        .post(`/space`)
        .send({
          ...space
        })
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(201)
        .then((res) => {
          expect(res.body.groupOwned).toBeFalsy()
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
          privateSpaceCreatedByUserXSpaceId = res.body._id
          privateSpaceCreatedByUserX = res.body

          // ensure role is present as an _id (it won't be populated upon create)
          expect(res.body.role).toBeTruthy()

          // ensure customData is present as an _id (it won't be populated upon create)
          expect(res.body.customData).toBeTruthy()

          // ensure spaceVariablesData is present as an _id (it won't be populated upon create)
          expect(res.body.spaceVariablesData).toBeTruthy()
        })
    })
    it('can get the space it just created', () => {
      return request(app.getHttpServer())
        .get(`/space/${privateSpaceCreatedByUserXSpaceId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          // ensure that it was created with the correct role for a private space
          expect(res.body.role.defaultRole).toEqual(ROLE.NO_ROLE)
          expect(res.body.role.users).toBeTruthy()
          expect(res.body.role.userGroups).toBeTruthy()
          expect(res.body.role.users[user1Id]).toEqual(ROLE.OBSERVER)
          expect(res.body.role.userGroups[userGroupId]).toEqual(
            ROLE.CONTRIBUTOR
          )
          expect(res.body.role.users).toEqual(
            expect.objectContaining({
              [createdUserXId]: ROLE.OWNER
            })
          )
          // expect the `owners` virtual property to be populated
          expect(res.body.role.owners).toContain(createdUserXId)

          expect(res.body.customData).toBeTruthy()
          expect(res.body.customData.createdAt).toBeTruthy()
          expect(res.body.customData.updatedAt).toBeTruthy()
          // ensure at least .data is present (default should be {})
          expect(res.body.customData.data).toBeTruthy()
          // ensure object is empty (this can be adjusted in the future, but I don't see a reason it shouldn't default to an empty object right now, {}) 2023-04-05 22:50:20
          expect(Object.keys(res.body.customData.data).length).toBe(0)

          /**
           * Space variables. This is based on the same implementation as CustomData. We aren't using CustomData right now, so CustomData may be removed later.
           */
          expect(res.body.spaceVariablesData).toBeTruthy()
          expect(res.body.spaceVariablesData.createdAt).toBeTruthy()
          expect(res.body.spaceVariablesData.updatedAt).toBeTruthy()
          // ensure at least .data is present (default should be {})
          expect(res.body.spaceVariablesData.data).toBeTruthy()
          // ensure object is empty (this can be adjusted in the future, but I don't see a reason it shouldn't default to an empty object right now, {}) 2023-04-05 22:50:20
          expect(Object.keys(res.body.spaceVariablesData.data).length).toBe(0)
        })
    })
    it("user Y can retrieve information about the private space because it's in the role.users object", () => {
      return request(app.getHttpServer())
        .get(`/space/${privateSpaceCreatedByUserXSpaceId}`)
        .set('Authorization', `Bearer ${userYAuthToken}`) // note user 1
        .expect(200)
        .then((res) => {
          // ensure that it was created with the correct role for a private space
          expect(res.body.role.defaultRole).toEqual(ROLE.NO_ROLE)
          expect(res.body.role.users).toBeTruthy()
          expect(res.body.role.userGroups).toBeTruthy()
          expect(res.body.role.users[user1Id]).toEqual(ROLE.OBSERVER)
          expect(res.body.role.userGroups[userGroupId]).toEqual(
            ROLE.CONTRIBUTOR
          )
          expect(res.body.customData.data).toBeTruthy()
          expect(res.body.customData.createdAt).toBeTruthy()
          expect(res.body.customData.updatedAt).toBeTruthy()
          // SpaceVariablesData
          expect(res.body.spaceVariablesData.data).toBeTruthy()
          expect(res.body.spaceVariablesData.createdAt).toBeTruthy()
          expect(res.body.spaceVariablesData.updatedAt).toBeTruthy()
        })
    })
    it("user Z CANNOT retrieve information (404) about the private group because it's not in the role.users object", () => {
      return request(app.getHttpServer())
        .get(`/space/${privateSpaceCreatedByUserXSpaceId}`)
        .set('Authorization', `Bearer ${userZAuthToken}`) // note user 2
        .expect(404)
    })
    it('user X can add user Z to the role as a contributor', () => {
      return request(app.getHttpServer())
        .patch(`/space/${privateSpaceCreatedByUserXSpaceId}/role/set`)
        .send({
          targetUserId: userZId,
          role: ROLE.CONTRIBUTOR
        })
        .set('Authorization', `Bearer ${userXAuthToken}`) // note main auth token who created the space
        .expect(200)
    })
    it('main user X can set a key/value pair on customdata', () => {
      return request(app.getHttpServer())
        .patch(`/space/${privateSpaceCreatedByUserXSpaceId}`)
        .send({
          patchCustomData: {
            hello: 'world',
            helloNested: {
              nested: 'nestedWorld'
            },
            fooToRemove: 'barToRemove'
          }
        })
        .set('Authorization', `Bearer ${userXAuthToken}`) // note main auth token who created the space
        .expect(200)
    })
    it('main user X can set a key/value pair on SpaceVariablesData', () => {
      return request(app.getHttpServer())
        .patch(`/space/${privateSpaceCreatedByUserXSpaceId}`)
        .send({
          patchSpaceVariablesData: {
            helloPatchSpaceVariablesData: 'world patchSpaceVariablesData',
            helloNested: {
              nestedHelloPatchSpaceVariablesData:
                'nestedWorld helloPatchSpaceVariablesData'
            },
            fooToRemoveSpaceVariablesData: 'barToRemoveSpaceVariablesData'
          }
        })
        .set('Authorization', `Bearer ${userXAuthToken}`) // note main auth token who created the space
        .expect(200)
    })
    it('user Z can now access the Space', () => {
      return request(app.getHttpServer())
        .get(`/space/${privateSpaceCreatedByUserXSpaceId}`)
        .set('Authorization', `Bearer ${userZAuthToken}`) // note user 2
        .expect(200)
        .then((res) => {
          // ensure that this user can see the customData
          expect(res.body.customData.data).toBeTruthy()
          expect(res.body.customData.createdAt).toBeTruthy()
          expect(res.body.customData.updatedAt).toBeTruthy()
          expect(res.body.customData.data.hello).toBe('world')
          expect(res.body.customData.data.helloNested.nested).toBe(
            'nestedWorld'
          )
          expect(res.body.customData.data.fooToRemove).toBe('barToRemove')

          // ensure that this user can see the spaceVariablesData
          expect(res.body.spaceVariablesData.data).toBeTruthy()
          expect(res.body.spaceVariablesData.createdAt).toBeTruthy()
          expect(res.body.spaceVariablesData.updatedAt).toBeTruthy()
          expect(
            res.body.spaceVariablesData.data.helloPatchSpaceVariablesData
          ).toBe('world patchSpaceVariablesData')
          expect(
            res.body.spaceVariablesData.data.helloNested
              .nestedHelloPatchSpaceVariablesData
          ).toBe('nestedWorld helloPatchSpaceVariablesData')
          expect(
            res.body.spaceVariablesData.data.fooToRemoveSpaceVariablesData
          ).toBe('barToRemoveSpaceVariablesData')
        })
    })
    it('main user X can remove a key/value pair on customData', () => {
      const dto: UpdateSpaceDto = {
        removeCustomDataKeys: ['fooToRemove']
      }
      return request(app.getHttpServer())
        .patch(`/space/${privateSpaceCreatedByUserXSpaceId}`)
        .send(dto)
        .set('Authorization', `Bearer ${userXAuthToken}`) // note main auth token who created the space
        .expect(200)
    })
    it('main user X can remove a key/value pair on spaceVariablesData', () => {
      const dto: UpdateSpaceDto = {
        removeSpaceVariablesDataKeys: ['fooToRemoveSpaceVariablesData']
      }
      return request(app.getHttpServer())
        .patch(`/space/${privateSpaceCreatedByUserXSpaceId}`)
        .send(dto)
        .set('Authorization', `Bearer ${userXAuthToken}`) // note main auth token who created the space
        .expect(200)
    })
    it('user Z sees the correct remaining customData and spaceVariablesData', () => {
      return request(app.getHttpServer())
        .get(`/space/${privateSpaceCreatedByUserXSpaceId}`)
        .set('Authorization', `Bearer ${userZAuthToken}`) // note user 2
        .expect(200)
        .then((res) => {
          expect(res.body.customData.data.fooToRemove).toBeUndefined()
          // ensure other nested properties weren't removed
          expect(res.body.customData.data.helloNested.nested).toBe(
            'nestedWorld'
          )

          expect(
            res.body.spaceVariablesData.data.fooToRemoveSpaceVariablesData
          ).toBeUndefined()
          // ensure other nested properties weren't removed
          expect(
            res.body.spaceVariablesData.data.helloNested
              .nestedHelloPatchSpaceVariablesData
          ).toBe('nestedWorld helloPatchSpaceVariablesData')
        })
    })
    it('main user X can delete the role for user Z', () => {
      return request(app.getHttpServer())
        .patch(`/space/${privateSpaceCreatedByUserXSpaceId}/role/unset`)
        .send({
          targetUserId: userZId
        })
        .set('Authorization', `Bearer ${userXAuthToken}`) // note main auth token who created the space
        .expect(200)
    })
    it('user Z can no longer access the Space', () => {
      return request(app.getHttpServer())
        .get(`/space/${privateSpaceCreatedByUserXSpaceId}`)
        .set('Authorization', `Bearer ${userZAuthToken}`) // note user 2
        .expect(404)
    })

    it('user X can publish the space it created', () => {
      return request(app.getHttpServer())
        .post(`/space/version/${privateSpaceCreatedByUserXSpaceId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(201)
    })

    it(`user Y can get the published space (published spaces are fully public)`, () => {
      return request(app.getHttpServer())
        .get(`/space/latest-published/${privateSpaceCreatedByUserXSpaceId}`)
        .set('Authorization', `Bearer ${userYAuthToken}`)
        .expect(200)
    })

    it('/space-godot-server/latest. it can be accessed by the godot server from /latest after publish', () => {
      return request(app.getHttpServer())
        .get(`/space-godot-server/latest/${privateSpaceCreatedByUserXSpaceId}`)
        .set('Authorization', `Bearer ${testWssSecret}`) // note the secret
        .expect(200)
        .then((res) => {
          expect(res.body).toBeTruthy()
        })
    })

    // This should eventually be removed since any server routes should use /space-godot-server, but I think GD client is consuming it 2023-04-05 17:05:53
    it('/space/latest. it can be accessed by the godot server from /latest after publish', () => {
      return request(app.getHttpServer())
        .get(`/space-godot-server/latest/${privateSpaceCreatedByUserXSpaceId}`)
        .set('Authorization', `Bearer ${testWssSecret}`)
        .expect(200)
        .then((res) => {
          expect(res.body).toBeTruthy()
        })
    })
  })

  describe('Public Space', () => {
    let publicSpaceIdToBeCreated
    it('creates a public space', () => {
      return request(app.getHttpServer())
        .post(`/space`)
        .send({
          ...space9ToBeCreatedPublic
        })
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(201)
        .then((res) => {
          expect(res.body._id.length).toBe(24) // mongo objectID length
          expect(res.body.name).toEqual(space9ToBeCreatedPublic.name)

          // ensure createdAt/updatedAt exist
          expect(res.body.createdAt).toBeTruthy()
          expect(res.body.updatedAt).toBeTruthy()
          // ensure createdAt/updatedAt is in the past minute
          const createdAtDate = new Date(res.body.createdAt)
          const updatedAtDate = new Date(res.body.updatedAt)
          const oneMinAgo = sub(new Date(), { minutes: 1 })
          expect(isAfter(createdAtDate, oneMinAgo)).toBeTruthy()
          expect(isAfter(updatedAtDate, oneMinAgo)).toBeTruthy()

          // ensure role is present
          expect(res.body.role).toBeTruthy()

          publicSpaceIdToBeCreated = res.body._id
        })
    })
    it('created a defaultRole of ROLE.OBSERVER for a public Space', () => {
      return request(app.getHttpServer())
        .get(`/space/${publicSpaceIdToBeCreated}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body.role.defaultRole).toEqual(ROLE.OBSERVER)
        })
    })
  })

  it('should get data in sorted order', async () => {
    const sortKey = 'name'
    const sortDirection = 1
    const perPage = 5
    const page = 1
    return request(app.getHttpServer())
      .get(
        `/space/discover-v2?perPage=${perPage}&page=${page}&sortKey=${sortKey}&sortDirection=${sortDirection}`
      )
      .set('Authorization', `Bearer ${userXAuthToken}`)
      .expect(200)
      .then((res) => {
        // ensure length isn't 0
        expect(res.body.data.length).toBeGreaterThanOrEqual(1)
        // check pagination properties
        expect(res.body.page).toEqual(page)
        expect(res.body.perPage).toEqual(perPage)

        res.body.data.forEach((space, inx, arr) => {
          // If Sort Direction in DESC order then first key should be greater than next key
          if (sortDirection == -1) {
            if (inx < arr.length - 1) {
              expect(
                space[sortKey].toLowerCase() >=
                  arr[inx + 1][sortKey].toLowerCase()
              ).toBeTruthy()
            }
          } else {
            // If Sort Direction in ASC order then first key should be less than next key
            if (inx < arr.length - 1) {
              expect(
                space[sortKey].toLowerCase() <=
                  arr[inx + 1][sortKey].toLowerCase()
              ).toBeTruthy()
            }
          }
        })
      })
  })
})
