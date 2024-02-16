import { INestApplication } from '@nestjs/common'
import { Test } from '@nestjs/testing'
import { isAfter, sub } from 'date-fns'
import jwt_decode from 'jwt-decode'
import { isNil, range } from 'lodash'
import request from 'supertest'
import { afterAll, beforeAll, describe, expect, it } from 'vitest'
import { AppModule } from '../../src/app.module'
import { AddAssetPurchaseOptionDto } from '../../src/asset/dto/update-asset.dto'
import { ROLE } from '../../src/roles/models/role.enum'
import {
  asset502ToBeCreated,
  asset503ToBeCreated,
  asset504ManyToBeCreated,
  asset506Seeded,
  asset515ToBeCreatedDefaultRoleNoRole,
  asset516ToBeCreatedDefaultRoleObserver,
  asset517ToBeCreatedDefaultRoleDiscover
} from '../stubs/asset.model.stub'
import { mockTagAMirrorPublicLibrary } from '../stubs/tag.model.stub'
import { ASSET_TYPE } from './../../src/option-sets/asset-type'
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

describe('E2E: Asset', () => {
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
  let assetForTestPurchaseOption
  let purchaseOptionToBeCreatedId

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

  it('alive test: should get the version of the app', async () => {
    return request(app.getHttpServer())
      .get(`/util/version`)
      .expect(200)
      .then((res) => {
        expect(res.text).toEqual(require('../../package.json').version)
      })
  })

  it('should fail without firebase auth', () => {
    return request(app.getHttpServer()).get(`/asset`).expect(404)
  })

  describe('Asset CRUD', () => {
    let privateCreatedAsset502ToBeDeletedId
    let privateCreatedAsset503Id
    let privateCreatedAsset515NoRoleId
    let createdAsset516IdObserverId
    let createdAsset517IdDiscoverId
    const asset502Rename = 'asset502Rename'

    it('creates a private asset', () => {
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
          privateCreatedAsset502ToBeDeletedId = res.body._id
        })
    })

    it('creates a second private asset', () => {
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
          privateCreatedAsset503Id = res.body._id
        })
    })

    it('creates a private asset, ROLE.NO_ROLE', () => {
      return request(app.getHttpServer())
        .post(`/asset`)
        .send({
          ...asset515ToBeCreatedDefaultRoleNoRole
        })
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(201)
        .then((res) => {
          expect(res.body._id.length).toBe(24) // mongo objectID length
          expect(res.body.name).toEqual(
            asset515ToBeCreatedDefaultRoleNoRole.name
          )
          expect(res.body.description).toEqual(
            asset515ToBeCreatedDefaultRoleNoRole.description
          )
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
          privateCreatedAsset515NoRoleId = res.body._id
        })
    })

    it('creates an asset, ROLE.DISCOVER', () => {
      return request(app.getHttpServer())
        .post(`/asset`)
        .send({
          ...asset517ToBeCreatedDefaultRoleDiscover
        })
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(201)
        .then((res) => {
          expect(res.body._id.length).toBe(24) // mongo objectID length
          expect(res.body.name).toEqual(
            asset517ToBeCreatedDefaultRoleDiscover.name
          )
          expect(res.body.description).toEqual(
            asset517ToBeCreatedDefaultRoleDiscover.description
          )
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
          createdAsset517IdDiscoverId = res.body._id
        })
    })

    it('creates an asset, ROLE.OBSERVER', () => {
      return request(app.getHttpServer())
        .post(`/asset`)
        .send({
          ...asset516ToBeCreatedDefaultRoleObserver
        })
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(201)
        .then((res) => {
          expect(res.body._id.length).toBe(24) // mongo objectID length
          expect(res.body.name).toEqual(
            asset516ToBeCreatedDefaultRoleObserver.name
          )
          expect(res.body.description).toEqual(
            asset516ToBeCreatedDefaultRoleObserver.description
          )
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
          createdAsset516IdObserverId = res.body._id
        })
    })

    it('checks roles for newly created assets', async () => {
      const res = await request(app.getHttpServer())
        .get(`/asset/${privateCreatedAsset502ToBeDeletedId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
      expect.soft(res.status).toEqual(200) // 2023-07-04 22:40:39 better syntax so that the test doesnt stop here

      expect(res.body?.role?.defaultRole).toBeDefined()
      // check roles
      expect(res.body.role.defaultRole).toEqual(ROLE.NO_ROLE)
      expect(res.body.role.users[createdUserXId]).toEqual(ROLE.OWNER)

      await request(app.getHttpServer())
        .get(`/asset/${privateCreatedAsset503Id}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body?.role?.defaultRole).toBeDefined()
          // check roles
          expect(res.body.role.defaultRole).toEqual(ROLE.NO_ROLE)
          expect(res.body.role.users[createdUserXId]).toEqual(ROLE.OWNER)
        })
      await request(app.getHttpServer())
        .get(`/asset/${privateCreatedAsset515NoRoleId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body?.role?.defaultRole).toBeDefined()
          // check roles
          expect(res.body.role.defaultRole).toEqual(ROLE.NO_ROLE)
          expect(res.body.role.users[createdUserXId]).toEqual(ROLE.OWNER)
        })
      await request(app.getHttpServer())
        .get(`/asset/${createdAsset516IdObserverId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body?.role?.defaultRole).toBeDefined()
          // check roles
          expect(res.body.role.defaultRole).toEqual(ROLE.OBSERVER)
          expect(res.body.role.users[createdUserXId]).toEqual(ROLE.OWNER)
        })
      await request(app.getHttpServer())
        .get(`/asset/${createdAsset517IdDiscoverId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body?.role?.defaultRole).toBeDefined()
          // check roles
          expect(res.body.role.defaultRole).toEqual(ROLE.DISCOVER)
          expect(res.body.role.users[createdUserXId]).toEqual(ROLE.OWNER)
        })
    })

    it('finds all public assets for a user (requested by user X)', () => {
      return request(app.getHttpServer())
        .get(`/asset/user/${createdUserXId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body.length).toBeGreaterThanOrEqual(2)
          res.body.forEach((asset) => {
            expect(asset.role.users[createdUserXId]).toEqual(ROLE.OWNER)
          })
          // ensure that the default role is at least OBSERVER
          res.body.forEach((asset) => {
            if (!isNil(asset.role.users[createdUserXId])) {
              expect(asset.role.users[createdUserXId]).toBeGreaterThanOrEqual(
                ROLE.OWNER
              )
            } else {
              expect(asset.role.defaultRole).toBeGreaterThanOrEqual(
                ROLE.DISCOVER
              )
            }
          })
        })
    })

    it('finds all public assets for a user (requested by user Y)', () => {
      return request(app.getHttpServer())
        .get(`/asset/user/${createdUserXId}`)
        .set('Authorization', `Bearer ${userYAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body.length).toBeGreaterThanOrEqual(2)
          res.body.forEach((asset) => {
            expect(asset.role.users[createdUserXId]).toEqual(ROLE.OWNER)
          })
          // ensure that the default role is at least OBSERVER
          res.body.forEach((asset) => {
            if (!isNil(asset.role.users[createdUserXId])) {
              expect(asset.role.users[createdUserXId]).toBeGreaterThanOrEqual(
                ROLE.OWNER
              )
            } else {
              expect(asset.role.defaultRole).toBeGreaterThanOrEqual(
                ROLE.DISCOVER
              )
            }
          })
        })
    })

    it('creates 10 assets', async () => {
      return await Promise.all(
        range(0, 10).map(async (element, index) => {
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
              assetForTestPurchaseOption = res.body._id
            })
        })
      )
    })

    it('gets /my-assets', async () => {
      return request(app.getHttpServer())
        .get(`/asset/my-assets`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body.data.length).toBeGreaterThanOrEqual(11)
          // Use the expect function with the array.includes method to check if at least one of the IDs is present
          expect(
            res.body.data.some(
              (obj) => obj._id === privateCreatedAsset502ToBeDeletedId
            )
          ).toBe(true)
          expect(
            res.body.data.some((obj) => obj._id === privateCreatedAsset503Id)
          ).toBe(true)

          res.body.data.forEach((asset) => {
            if (!isNil(asset.role.users[createdUserXId])) {
              expect(asset.role.users[createdUserXId]).toBeGreaterThanOrEqual(
                ROLE.DISCOVER
              )
            } else {
              expect(asset.role.defaultRole).toBeGreaterThanOrEqual(
                ROLE.DISCOVER
              )
            }
          })
        })
    })

    it('can get recent assets (limit 100 to check for the above created assets)', () => {
      return request(app.getHttpServer())
        .get(`/asset/recent?limit=100`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body.length).toBeGreaterThanOrEqual(5)
          // Use the expect function with the array.includes method to check if at least one of the IDs is present
          expect(
            res.body.some(
              (obj) => obj._id === privateCreatedAsset502ToBeDeletedId
            )
          ).toBe(true)
          expect(
            res.body.some((obj) => obj._id === privateCreatedAsset503Id)
          ).toBe(true)

          res.body.forEach((asset) => {
            expect(asset.role.users).toBeTruthy()
            if (!isNil(asset.role.users[createdUserXId])) {
              expect(asset.role.users[createdUserXId]).toBeGreaterThanOrEqual(
                ROLE.DISCOVER
              )
            } else {
              expect(asset.role.defaultRole).toBeGreaterThanOrEqual(
                ROLE.DISCOVER
              )
            }
          })
        })
    })
    it('can get recent assets and does not include less-recent asset502, asset503', () => {
      return request(app.getHttpServer())
        .get(`/asset/recent?limit=8`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          // Use the expect function with the array.includes method to check if xat least one of the IDs is present
          expect(res.body.length).toBe(8)
          expect(
            res.body.some(
              (obj) => obj._id === privateCreatedAsset502ToBeDeletedId
            )
          ).toBe(false)
          // important: ensure that 503 is NOT in there since this is retrieving the 20 most recent assets and we created 50
          expect(
            res.body.some((obj) => obj._id === privateCreatedAsset503Id)
          ).toBe(false)

          res.body.forEach((asset) => {
            if (!isNil(asset.role.users[createdUserXId])) {
              expect(asset.role.users[createdUserXId]).toBeGreaterThanOrEqual(
                ROLE.DISCOVER
              )
            } else {
              expect(asset.role.defaultRole).toBeGreaterThanOrEqual(
                ROLE.DISCOVER
              )
            }
          })
        })
    })

    it('cannot update an asset the user does not own', () => {
      return request(app.getHttpServer())
        .patch(`/asset/${asset506Seeded._id}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .send({ name: 'new name' })
        .expect(404)
    })
    it('can update an asset the user does own', () => {
      return request(app.getHttpServer())
        .patch(`/asset/${privateCreatedAsset502ToBeDeletedId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .send({ name: 'new name' })
        .expect(200)
    })

    it('cannot delete an asset the user does not own', () => {
      return request(app.getHttpServer())
        .delete(`/asset/${asset506Seeded._id}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(404)
    })
    it('can delete an asset the user does own', () => {
      return request(app.getHttpServer())
        .delete(`/asset/${privateCreatedAsset502ToBeDeletedId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
    })
  })
  describe('Seeded Data: Individual Owner', () => {
    it('gets an asset from the seeded database', () => {
      return request(app.getHttpServer())
        .get(`/asset/${asset506Seeded._id}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body._id).toEqual(asset506Seeded._id)
          expect(res.body.name).toEqual(asset506Seeded.name)

          expect(res.body.createdAt).toEqual(asset506Seeded.createdAt)
          expect(res.body.updatedAt).toEqual(asset506Seeded.updatedAt)

          if (!isNil(res.body.role.users[createdUserXId])) {
            expect(res.body.role.users[createdUserXId]).toBeGreaterThanOrEqual(
              ROLE.DISCOVER
            )
          } else {
            expect(res.body.role.defaultRole).toBeGreaterThanOrEqual(
              ROLE.DISCOVER
            )
          }
        })
    })
    it('gets paginated mirror-assets of MATERIAL from the seeded database', () => {
      return request(app.getHttpServer())
        .get(`/asset/mirror-assets?assetTypes=${ASSET_TYPE.MATERIAL}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body.data.length).toBeGreaterThan(0)

          res.body.data.forEach((asset) => {
            expect(asset.assetType).toEqual(ASSET_TYPE.MATERIAL)
          })
        })
    })
    it('gets paginated mirror-assets of MATERIAL,MESH from the seeded database', () => {
      return request(app.getHttpServer())
        .get(
          `/asset/mirror-assets?assetTypes=${ASSET_TYPE.MATERIAL},${ASSET_TYPE.MESH}`
        )
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body.data.length).toBeGreaterThan(0)

          res.body.data.forEach((asset) => {
            expect(
              asset.assetType === ASSET_TYPE.MESH ||
                asset.assetType === ASSET_TYPE.MATERIAL
            ).toBeTruthy()
          })
        })
    })
    it('gets paginated mirror-assets with notContainAnyTagsV2 tagsV2 from the seeded database', () => {
      return request(app.getHttpServer())
        .get(
          `/asset/mirror-assets?notContainAnyTagsV2=${mockTagAMirrorPublicLibrary._id}`
        )
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body.data.length).toBeGreaterThan(0)

          res.body.data.forEach((asset) => {
            expect(
              asset.tagsV2.includes(mockTagAMirrorPublicLibrary._id.toString())
            ).toBeFalsy()
          })
        })
    })
    it('gets paginated mirror-assets with containAnyTagsV2 tagsV2 from the seeded database', () => {
      return request(app.getHttpServer())
        .get(
          `/asset/mirror-assets?containAnyTagsV2=${mockTagAMirrorPublicLibrary._id}`
        )
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body.data.length).toBeGreaterThan(0)

          res.body.data.forEach((asset) => {
            expect(
              asset.tagsV2.some(
                (tag) => tag._id === mockTagAMirrorPublicLibrary._id.toString()
              )
            ).toBeTruthy()
          })
        })
    })
  })

  it('should get paginated mirror-assets  by start-item', () => {
    return request(app.getHttpServer())
      .get(`/asset/by/start-item?startItem=1&numberOfItems=10`)
      .set('Authorization', `Bearer ${userXAuthToken}`)
      .expect(200)
      .then((res) => {
        expect(res.body.startItem).toBeDefined()
        expect(isNaN(res.body.startItem)).toBeFalsy()
        expect(res.body.startItem).toBe(1)
        expect(res.body.numberOfItems).toBeDefined()
        expect(isNaN(res.body.numberOfItems)).toBeFalsy()
        expect(res.body.numberOfItems).toBe(10)
        expect(res.body.totalPage).toBeDefined()
        expect(res.body.numberOfItems).toBeLessThanOrEqual(10)
        expect(res.body.data.length).toEqual(res.body.numberOfItems)
      })
  })

  const purchaseOptionToBeCreated = {
    enabled: false,
    price: 2,
    currency: 'usd',
    type: 'ONE_TIME',
    licenseType: 'MIRROR_REV_SHARE',
    description: 'string',
    startDate: new Date('2023-08-21T13:13:29.858Z'),
    endDate: new Date('2023-08-21T13:13:29.858Z')
  }

  it('should create purchase option', () => {
    return request(app.getHttpServer())
      .post(`/asset/${assetForTestPurchaseOption}/purchase-option`)
      .set('Authorization', `Bearer ${userXAuthToken}`)
      .send(purchaseOptionToBeCreated)
      .expect(201)
      .then((res) => {
        expect(res.body.purchaseOptions.length).toBeGreaterThan(0)
        const createPurchseOption = res.body.purchaseOptions[0]
        purchaseOptionToBeCreatedId = createPurchseOption._id
        expect(createPurchseOption.enabled).toBe(
          purchaseOptionToBeCreated.enabled
        )
        expect(createPurchseOption.price).toBe(purchaseOptionToBeCreated.price)
        expect(createPurchseOption.currency).toBe(
          purchaseOptionToBeCreated.currency
        )
        expect(createPurchseOption.type).toBe(purchaseOptionToBeCreated.type)
        expect(createPurchseOption.licenseType).toBe(
          purchaseOptionToBeCreated.licenseType
        )
        expect(createPurchseOption.description).toBe(
          purchaseOptionToBeCreated.description
        )
      })
  })

  it('should delete created purchase option', () => {
    return request(app.getHttpServer())
      .delete(
        `/asset/${assetForTestPurchaseOption}/purchase-option/${purchaseOptionToBeCreatedId}`
      )
      .set('Authorization', `Bearer ${userXAuthToken}`)
      .send(purchaseOptionToBeCreated)
      .expect(200)
      .then((res) => {
        expect(res.body.purchaseOptions.length).toEqual(0)
        expect(
          res.body.purchaseOptions.includes(
            (elem) => elem._id === purchaseOptionToBeCreatedId
          )
        ).toBeFalsy()
      })
  })
})
