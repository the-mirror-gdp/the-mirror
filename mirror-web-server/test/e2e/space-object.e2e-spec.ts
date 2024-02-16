import { INestApplication } from '@nestjs/common'
import { Test } from '@nestjs/testing'
import { isAfter, sub } from 'date-fns'
import { range } from 'lodash'
import request from 'supertest'
import { AppModule } from '../../src/app.module'
import {
  asset502ToBeCreated,
  asset503ToBeCreated,
  asset504ManyToBeCreated
} from '../stubs/asset.model.stub'
import {
  privateSpaceId4GroupOwned,
  space10WithManagerDefaultRole,
  space11WithContributorDefaultRole,
  space14WithNoRoleDefaultRole,
  space15ForSpaceObjectsCopiedToIt,
  space7ToBeCreatedPrivateIndividualOwner
} from '../stubs/space.model.stub'
import {
  spaceObject1InPrivateSpace,
  spaceObject2InPublicManagerSpace,
  spaceObject3ToBeCreatedInPrivateSpace,
  spaceObject4ToBeCreatedInManagerSpace,
  spaceObject5ToBeCreatedWithSpecifiedAssetNeedsAssetId,
  spaceObject6ToBeCreatedWithSpecifiedAssetNeedsAssetId,
  spaceObject7ForParentSpaceObjectInManagerSpace
} from './../stubs/spaceObject.model.stub'
import { deleteFirebaseTestAccount, getFirebaseToken } from './e2e-auth'
import {
  clearTestDatabase,
  createTestAccountOnFirebaseAndDb,
  initTestMongoDbWithSeed,
  safetyCheckDatabaseForTest
} from './e2e-db-util'
import { afterAll, beforeAll, expect, it, describe } from 'vitest'

/**
 * E2E Walkthrough: https://www.loom.com/share/cea8701390bf4e7ba234cc0689830399?from_recorder=1&focus_title=1
 */

describe('E2E: Space Object', () => {
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
    it('gets a public space-object from the seeded database', () => {
      return request(app.getHttpServer())
        .get(`/space-object/${spaceObject2InPublicManagerSpace._id}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body._id).toEqual(spaceObject2InPublicManagerSpace._id)
          expect(res.body.name).toEqual(spaceObject2InPublicManagerSpace.name)

          expect(res.body.createdAt).toEqual(
            spaceObject2InPublicManagerSpace.createdAt
          )
          expect(res.body.updatedAt).toEqual(
            spaceObject2InPublicManagerSpace.updatedAt
          )

          // ensure role is present
          // expect(res.body.role).toBeTruthy()
        })
    })
    it("returns a 404 for a private space-object where the space's defaultRole is ROLE.NO_ROLE", () => {
      return request(app.getHttpServer())
        .get(`/space-object/${spaceObject1InPrivateSpace._id}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(404)
    })
    it('denies an update to a SpaceObject in a Space that has role.defaultRole == NO.ROLE', () => {
      return request(app.getHttpServer())
        .patch(`/space-object/${spaceObject1InPrivateSpace._id}`)
        .send({
          name: 'hello'
        })
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(404)
    })
    it('updates a spaceobject', () => {
      return request(app.getHttpServer())
        .patch(
          `/space-object/${spaceObject7ForParentSpaceObjectInManagerSpace._id}`
        )
        .send({
          description: 'updatedDescInTest'
        })
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
    })
    it('gets the updated spaceobject', () => {
      return request(app.getHttpServer())
        .get(
          `/space-object/${spaceObject7ForParentSpaceObjectInManagerSpace._id}`
        )
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body.description).toEqual('updatedDescInTest')
        })
    })
    it('updates a spaceobject parentSpaceObject with an id', () => {
      return request(app.getHttpServer())
        .patch(
          `/space-object/${spaceObject7ForParentSpaceObjectInManagerSpace._id}`
        )
        .send({
          parentSpaceObject: '64a38bc2b7b2c8cf75322671' // not a real id
        })
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
    })
    it('gets the updated spaceobject with parentSpaceObject', () => {
      return request(app.getHttpServer())
        .get(
          `/space-object/${spaceObject7ForParentSpaceObjectInManagerSpace._id}`
        )
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body.parentSpaceObject).toEqual('64a38bc2b7b2c8cf75322671')
        })
    })
    it('updates a spaceobject parentSpaceObject with removing the parentSpaceObject', () => {
      return request(app.getHttpServer())
        .patch(
          `/space-object/${spaceObject7ForParentSpaceObjectInManagerSpace._id}`
        )
        .send({
          parentSpaceObject: undefined
        })
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
    })
    it('gets the updated spaceobject without a parentSpaceObject', () => {
      return request(app.getHttpServer())
        .get(`/space-object/${spaceObject2InPublicManagerSpace._id}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body.parentSpaceObject).toBeUndefined()
        })
    })
    it('can create a spaceobject in a public space', () => {
      return request(app.getHttpServer())
        .post(`/space-object`)
        .send({
          ...spaceObject4ToBeCreatedInManagerSpace
        })
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(201)
        .then((res) => {
          expect(res.body._id.length).toBe(24) // mongo objectID length
          expect(res.body.name).toEqual(
            spaceObject4ToBeCreatedInManagerSpace.name
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

          expect(res.body.space).toEqual(
            spaceObject4ToBeCreatedInManagerSpace.spaceId
          )
        })
    })
    it("cannot delete a public SpaceObject that the user doesn't own", () => {
      return request(app.getHttpServer())
        .delete(`/space-object/${spaceObject1InPrivateSpace._id}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(404)
    })
    it("cannot copy a space's spaceObjects it doesn't own", () => {
      return request(app.getHttpServer())
        .post(`/space-object/copy`)
        .send({
          from: space14WithNoRoleDefaultRole._id,
          to: space10WithManagerDefaultRole._id
        })
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(404)
    })
  })

  // 2023-04-20 23:59:43 groups aren't implemented yet, so skipping this but leaving it here for the future
  // describe.skip('Seeded Data: Group Owner', () => {
  //   it('does not get via 404 a private space where the space IS group owned ', () => {
  //     return request(app.getHttpServer())
  //       .get(`/space-object/${privateSpaceId4GroupOwned}`)
  //       .set('Authorization', `Bearer ${userXAuthToken}`)
  //       .expect(404)
  //   })
  // })

  describe('Private Space SpaceObjects + Creation', () => {
    let privateCreatedSpaceObjectId
    let privateCreatedSpace1Id
    let privateCreatedSpace2Id
    // this it() is copied from space-e2e and should stay updated
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

          // ensure role is present as an _id (it won't be populated upon create)
          expect(res.body.role).toBeTruthy()

          // important: update our mock spaceobject to use this newly created Space's ID
          spaceObject3ToBeCreatedInPrivateSpace.spaceId = privateCreatedSpace1Id
        })
    })
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

          // note that a role is optional for spaceobjects; they'll be default take the settings of the parent Space
        })
    })
    it('can get the spaceObject it just created', () => {
      return request(app.getHttpServer())
        .get(`/space-object/${privateCreatedSpaceObjectId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          // TODO: add a separate test with a spaceobject with a .role
          // // ensure that it was created with the correct role for a private space
          // expect(res.body.role.defaultRole).toEqual(
          //   ROLE.NO_ROLE
          // )
          // expect(res.body.role.users).toEqual({
          //   [createdUserXId]: ROLE.OWNER
          // })
          // expect the `owners` virtual property to be populated
          // expect(res.body.role.owners).toContain(
          //   createdUserXId
          // )
          expect(res.body._id).toEqual(privateCreatedSpaceObjectId)
        })
    })

    it('can see the new spaceObject when retrieving a list of spaceObjects for a space', () => {
      return request(app.getHttpServer())
        .get(
          `/space-object/space/${spaceObject3ToBeCreatedInPrivateSpace.spaceId}`
        )
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          // ensure length isn't 0
          expect(res.body.length).toBeGreaterThanOrEqual(1)
          // check a property: ensure that the id of the new space created is present in the list and the name lines up with what was just created
          res.body.forEach((spaceObject) => {
            expect(spaceObject._id).toBeDefined()

            // check data for the spaceObject we just created
            if (spaceObject._id === privateCreatedSpaceObjectId) {
              expect(spaceObject.name).toEqual(
                spaceObject3ToBeCreatedInPrivateSpace.name
              )
              expect(spaceObject.description).toEqual(
                spaceObject3ToBeCreatedInPrivateSpace.description
              )
            }
          })
        })
    })

    it('creates a private space for testing copying (space 2)', () => {
      return request(app.getHttpServer())
        .post(`/space`)
        .send({
          ...space15ForSpaceObjectsCopiedToIt
        })
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(201)
        .then((res) => {
          privateCreatedSpace2Id = res.body._id
        })
    })
    it("can copy all a Space's SpaceObjects", () => {
      return request(app.getHttpServer())
        .post(`/space-object/copy`)
        .send({
          from: privateCreatedSpace1Id,
          to: privateCreatedSpace2Id
        })
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(201)
    })
    it("cannot copy all a Space's SpaceObjects FROM one it doesn't own", () => {
      return request(app.getHttpServer())
        .post(`/space-object/copy`)
        .send({
          from: space14WithNoRoleDefaultRole,
          to: privateCreatedSpace2Id
        })
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(404)
    })
    it("cannot copy all a Space's SpaceObjects TO one it doesn't own", () => {
      return request(app.getHttpServer())
        .post(`/space-object/copy`)
        .send({
          from: privateCreatedSpace1Id,
          to: space14WithNoRoleDefaultRole
        })
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(404)
    })
    it("cannot copy all a Space's SpaceObjects when not an owner for either", () => {
      return request(app.getHttpServer())
        .post(`/space-object/copy`)
        .send({
          from: space11WithContributorDefaultRole,
          to: space14WithNoRoleDefaultRole
        })
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(404)
    })
    it('can delete the spaceObject it just created', () => {
      return request(app.getHttpServer())
        .delete(`/space-object/${privateCreatedSpaceObjectId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body._id).toBe(privateCreatedSpaceObjectId)
        })
    })
    it('can no longer get the deleted spaceObject', () => {
      return request(app.getHttpServer())
        .get(`/space-object/${privateCreatedSpaceObjectId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(404)
    })
  })
  describe('SpaceObject Creation for newly-created asset + Recent Assets that factors in SpaceObject modification', () => {
    let privateCreatedAsset502Id
    let privateCreatedAsset503Id
    let privateCreatedSpaceObjectIdFromAsset502
    let privateCreatedSpaceObjectIdFromAsset503
    const asset502Rename = 'asset502Rename'

    it('creates an asset (to be later used for creating a spaceobject)', () => {
      return request(app.getHttpServer())
        .post(`/asset`)
        .send({
          ...asset502ToBeCreated
        })
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(201)
        .then((res) => {
          expect(res.body._id.length).toBe(24) // mongo objectID length
          expect(res.body.name).toEqual(asset502ToBeCreated.name)

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
          privateCreatedAsset502Id = res.body._id

          // note that a role is optional for spaceobjects; they'll be default take the settings of the parent Space
        })
    })

    it('creates a second asset (to be later used for creating a spaceobject)', () => {
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
          expect(res.body.description).toEqual(asset503ToBeCreated.description)

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
          privateCreatedAsset503Id = res.body._id

          // note that a role is optional for spaceobjects; they'll be default take the settings of the parent Space
        })
    })

    it('creates 50 assets', async () => {
      await Promise.all(
        range(0, 50).map(async (element, index) => {
          return request(app.getHttpServer())
            .post(`/asset`)
            .send({
              ...asset504ManyToBeCreated
            })
            .set('Authorization', `Bearer ${userXAuthToken}`)
            .expect(201)
            .then((res) => {
              expect(res.body._id.length).toBe(24) // mongo objectID length
              expect(res.body.name).toEqual(asset504ManyToBeCreated.name)
              expect(res.body.description).toEqual(
                asset504ManyToBeCreated.description
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
            })
        })
      )
    })
    it('checks that all assets have been created', () => {
      return request(app.getHttpServer())
        .get(`/asset/my-assets`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body.data.length).toBeGreaterThanOrEqual(50)
        })
    })

    it('creates a spaceobject for the newly-created asset 502', () => {
      return request(app.getHttpServer())
        .post(`/space-object`)
        .send({
          ...spaceObject5ToBeCreatedWithSpecifiedAssetNeedsAssetId,
          asset: privateCreatedAsset502Id
        })
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(201)
        .then((res) => {
          expect(res.body._id.length).toBe(24) // mongo objectID length
          expect(res.body.name).toEqual(
            spaceObject5ToBeCreatedWithSpecifiedAssetNeedsAssetId.name
          )
          expect(res.body.asset).toEqual(privateCreatedAsset502Id)

          // ensure createdAt/updatedAt exist
          expect(res.body.createdAt).toBeTruthy()
          expect(res.body.updatedAt).toBeTruthy()
          // ensure createdAt/updatedAt is in the past minute
          const createdAtDate = new Date(res.body.createdAt)
          const updatedAtDate = new Date(res.body.updatedAt)
          const oneMinAgo = sub(new Date(), { minutes: 1 })
          expect(isAfter(createdAtDate, oneMinAgo)).toBeTruthy()
          expect(isAfter(updatedAtDate, oneMinAgo)).toBeTruthy()

          privateCreatedSpaceObjectIdFromAsset502 = res.body._id

          // note that a role is optional for spaceobjects; they'll be default take the settings of the parent Space
        })
    })
    it('creates a spaceobject for the newly-created asset 503', () => {
      return request(app.getHttpServer())
        .post(`/space-object`)
        .send({
          ...spaceObject6ToBeCreatedWithSpecifiedAssetNeedsAssetId,
          asset: privateCreatedAsset503Id
        })
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(201)
        .then((res) => {
          expect(res.body._id.length).toBe(24) // mongo objectID length
          expect(res.body.name).toEqual(
            spaceObject6ToBeCreatedWithSpecifiedAssetNeedsAssetId.name
          )
          expect(res.body.description).toEqual(
            spaceObject6ToBeCreatedWithSpecifiedAssetNeedsAssetId.description
          )
          expect(res.body.asset).toEqual(privateCreatedAsset503Id)

          // ensure createdAt/updatedAt exist
          expect(res.body.createdAt).toBeTruthy()
          expect(res.body.updatedAt).toBeTruthy()
          // ensure createdAt/updatedAt is in the past minute
          const createdAtDate = new Date(res.body.createdAt)
          const updatedAtDate = new Date(res.body.updatedAt)
          const oneMinAgo = sub(new Date(), { minutes: 1 })
          expect(isAfter(createdAtDate, oneMinAgo)).toBeTruthy()
          expect(isAfter(updatedAtDate, oneMinAgo)).toBeTruthy()

          privateCreatedSpaceObjectIdFromAsset503 = res.body._id

          // note that a role is optional for spaceobjects; they'll be default take the settings of the parent Space
        })
    })
    it('can get the spaceObject it just created with a specified asset privateCreatedSpaceObjectIdFromAsset502', () => {
      return request(app.getHttpServer())
        .get(`/space-object/${privateCreatedSpaceObjectIdFromAsset502}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body.asset).toEqual(privateCreatedAsset502Id)
          expect(res.body._id).toEqual(privateCreatedSpaceObjectIdFromAsset502)
        })
    })
    it('can get the spaceObject it just created with a specified asset privateCreatedSpaceObjectIdFromAsset503', () => {
      return request(app.getHttpServer())
        .get(`/space-object/${privateCreatedSpaceObjectIdFromAsset503}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body.asset).toEqual(privateCreatedAsset503Id)
          expect(res.body._id).toEqual(privateCreatedSpaceObjectIdFromAsset503)
        })
    })
    // Note: some crossover with Asset tests here, but I think that's okay since they relate closely
    it('can get recent assets (limit 100 to check for the above created assets)', () => {
      return request(app.getHttpServer())
        .get(`/asset/recent?limit=100`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          // Use the expect function with the array.includes method to check if at least one of the IDs is present
          expect(
            res.body.some((obj) => obj._id === privateCreatedAsset502Id)
          ).toBe(true)
          expect(
            res.body.some((obj) => obj._id === privateCreatedAsset503Id)
          ).toBe(true)

          // TODO: check .role for these, also noting that Space role permissions cascade
          // // ensure that it was created with the correct role for a private space
          // expect(res.body.role.defaultRole).toEqual(
          //   ROLE.NO_ROLE
          // )
          // expect(res.body.role.users).toEqual({
          //   [createdUserXId]: ROLE.OWNER
          // })
          // expect the `owners` virtual property to be populated
          // expect(res.body.role.owners).toContain(
          //   createdUserXId
          // )
        })
    })
    it('creates 50 spaceobjects for the newly-created asset 502', async () => {
      await Promise.all(
        range(0, 50).map(async (element, index) => {
          return request(app.getHttpServer())
            .post(`/space-object`)
            .send({
              ...spaceObject6ToBeCreatedWithSpecifiedAssetNeedsAssetId,
              asset: privateCreatedAsset502Id
            })
            .set('Authorization', `Bearer ${userXAuthToken}`)
            .expect(201)
            .then((res) => {
              expect(res.body._id.length).toBe(24) // mongo objectID length
              expect(res.body.name).toEqual(
                spaceObject6ToBeCreatedWithSpecifiedAssetNeedsAssetId.name
              )
              expect(res.body.description).toEqual(
                spaceObject6ToBeCreatedWithSpecifiedAssetNeedsAssetId.description
              )
              expect(res.body.asset).toEqual(privateCreatedAsset502Id)

              // ensure createdAt/updatedAt exist
              expect(res.body.createdAt).toBeTruthy()
              expect(res.body.updatedAt).toBeTruthy()
              // ensure createdAt/updatedAt is in the past minute
              const createdAtDate = new Date(res.body.createdAt)
              const updatedAtDate = new Date(res.body.updatedAt)
              const oneMinAgo = sub(new Date(), { minutes: 1 })
              expect(isAfter(createdAtDate, oneMinAgo)).toBeTruthy()
              expect(isAfter(updatedAtDate, oneMinAgo)).toBeTruthy()

              // note that a role is optional for spaceobjects; they'll be default take the settings of the parent Space
            })
        })
      )
    })
    it('checks that all spaceobjects have been created', () => {
      return request(app.getHttpServer())
        .get(
          `/space-object/space/${spaceObject6ToBeCreatedWithSpecifiedAssetNeedsAssetId.spaceId}`
        )
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body.length).toBeGreaterThanOrEqual(50)
        })
    })

    it('updates asset 502', () => {
      return request(app.getHttpServer())
        .patch(`/asset/${privateCreatedAsset502Id}`)
        .send({
          name: asset502Rename
        })
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
    })
    it('gets the newly-updated asset 502', () => {
      return request(app.getHttpServer())
        .get(`/asset/${privateCreatedAsset502Id}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          // Use the expect function with the array.includes method to check if xat least one of the IDs is present
          expect(res.body.name).toBe(asset502Rename)
        })
    })
    it('can get recent assets that includes the latest spaceobjects and DOES now include asset502', () => {
      return request(app.getHttpServer())
        .get(`/asset/recent?limit=20`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          // Use the expect function with the array.includes method to check if xat least one of the IDs is present
          expect(res.body.length).toBe(20)
          expect(
            res.body.some((obj) => obj._id === privateCreatedAsset502Id)
          ).toBe(true)
          // important: ensure that 503 is NOT in there since this is retrieving the 20 most recent assets and we created 50
          expect(
            res.body.some((obj) => obj._id === privateCreatedAsset503Id)
          ).toBe(false)

          // TODO: check .role for these, also noting that Space role permissions cascade
          // // ensure that it was created with the correct role for a private space
          // expect(res.body.role.defaultRole).toEqual(
          //   ROLE.NO_ROLE
          // )
          // expect(res.body.role.users).toEqual({
          //   [createdUserXId]: ROLE.OWNER
          // })
          // expect the `owners` virtual property to be populated
          // expect(res.body.role.owners).toContain(
          //   createdUserXId
          // )
        })
    })
  })
})
