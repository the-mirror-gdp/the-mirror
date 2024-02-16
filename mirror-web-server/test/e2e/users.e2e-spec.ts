import { INestApplication } from '@nestjs/common'
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
import { afterAll, beforeAll, expect, it, describe } from 'vitest'
import { ObjectId } from 'mongodb'
import { isValidObjectId } from 'mongoose'
import { USER_AVATAR_TYPE } from '../../src/option-sets/user-avatar-types'
import {
  ENTITY_TYPE,
  USER_ENTITY_ACTION_TYPE
} from '../../src/user/models/user-entity-action.schema'
import { ENTITY_TYPE_AVAILABLE_TO_PURCHASE } from '../../src/user/models/user-cart.schema'

/**
 * E2E Walkthrough: https://www.loom.com/share/cea8701390bf4e7ba234cc0689830399?from_recorder=1&focus_title=1
 */

describe('E2E: User', () => {
  let app: INestApplication
  let mongoDbUrl
  let dbName
  let userXAuthToken
  let createdUserXId
  let userXAccountEmail
  let userXAccountPassword
  let profile1
  let profile2

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
  })

  it('alive test: should get the version of the app', async () => {
    return request(app.getHttpServer())
      .get(`/util/version`)
      .expect(200)
      .then((res) => {
        expect(res.text).toEqual(require('../../package.json').version)
      })
  })

  describe('Auth not required: API in which auth not required', () => {
    it('should get a Users public data by id', () => {
      return request(app.getHttpServer())
        .get(`/user/id/${new ObjectId(profile1.localId)}`)
        .expect(200)
        .then((res) => {
          expect(res.body._id).toBeDefined()
          expect(isValidObjectId(res.body._id)).toBe(true)
          expect(res.body._id).toEqual(profile1.localId)
          expect(res.body.displayName).toBeDefined()
          expect(res.body.displayName).toEqual(profile1.displayName)
          expect(res.body.email).toEqual(profile1.email)
        })
    })

    it('should get a public profile by user id', () => {
      return request(app.getHttpServer())
        .get(`/user/${new ObjectId(profile1.localId)}/public-profile`)
        .expect(200)
        .then((res) => {
          expect(res.body._id).toBeDefined()
          expect(isValidObjectId(res.body._id)).toBe(true)
          expect(res.body._id).toEqual(profile1.localId)
          expect(res.body.displayName).toBeDefined()
          expect(res.body.displayName).toEqual(profile1.displayName)
          expect(res.body.email).toEqual(profile1.email)
        })
    })

    it('should search for public users by query', async () => {
      const query = `test`
      return request(app.getHttpServer())
        .get(`/user/search?query=${query}`)
        .expect(200)
        .then((res) => {
          expect(Array.isArray(res.body)).toBe(true)
          if (res.body.length > 0) {
            for (const obj of res.body) {
              expect(obj._id).toBeDefined()
              expect(isValidObjectId(obj._id)).toBe(true)
              expect(obj.displayName).toBeDefined()
              expect(obj.email).toBeDefined()
            }
          }
        })
    })
  })

  describe('Auth required: API in which auth required', () => {
    // user/me
    it('should fail without firebase auth', () => {
      return request(app.getHttpServer()).get(`/user/me`).expect(403)
    })
    it('should get a Users profile data ', () => {
      return request(app.getHttpServer())
        .get(`/user/me`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body._id).toBeDefined()
          expect(isValidObjectId(res.body._id)).toBe(true)
          expect(res.body.displayName).toBeDefined()
          expect(res.body.email).toBeDefined()
        })
    })
    // user/me

    // user/profile
    const dataToUpdate = { displayName: 'Test123' }
    it('should fail without firebase auth', () => {
      return request(app.getHttpServer())
        .patch(`/user/profile`)
        .send(dataToUpdate)
        .expect(403)
    })
    it('should update user display name ', async () => {
      return request(app.getHttpServer())
        .patch(`/user/profile`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .send(dataToUpdate)
        .expect(200)
        .then((res) => {
          expect(res.body.displayName).toEqual(dataToUpdate.displayName)
        })
    })
    // user/profile

    // user/tutorial
    it('should fail without firebase auth', () => {
      return request(app.getHttpServer()).patch(`/user/tutorial`).expect(403)
    })
    it('should update tutorial  ', () => {
      return request(app.getHttpServer())
        .patch(`/user/tutorial`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body.tutorial).toBeDefined()
        })
    })
    // user/tutorial

    // user/deep-link
    const deepLinkKey = 'demo'
    const deepLinkValue = 'demo'
    it('should fail without firebase auth', () => {
      return request(app.getHttpServer())
        .patch(`/user/deep-link`)
        .send({ deepLinkKey, deepLinkValue })
        .expect(403)
    })
    it('should update deep-link  ', () => {
      return request(app.getHttpServer())
        .patch(`/user/deep-link`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .send({ deepLinkKey, deepLinkValue })
        .expect(200)
        .then((res) => {
          expect(res.body.deepLinkKey).toEqual(deepLinkKey)
          expect(res.body.deepLinkValue).toEqual(deepLinkValue)
        })
    })
    // user/deep-link

    // user/avatar
    const avatarUrl = 'demo'
    it('should fail without firebase auth', () => {
      return request(app.getHttpServer())
        .patch(`/user/avatar`)
        .send({ avatarUrl })
        .expect(403)
    })
    it('should update avatar  ', () => {
      return request(app.getHttpServer())
        .patch(`/user/avatar`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .send({ avatarUrl })
        .expect(200)
        .then((res) => {
          expect(res.body.avatarUrl).toEqual(avatarUrl)
        })
    })
    // user/avatar

    // user/terms
    const termsAgreedtoClosedAlpha = true
    it('should fail without firebase auth', () => {
      return request(app.getHttpServer())
        .patch(`/user/terms`)
        .send({ termsAgreedtoClosedAlpha })
        .expect(403)
    })
    it('should update terms  ', () => {
      return request(app.getHttpServer())
        .patch(`/user/terms`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .send({ termsAgreedtoClosedAlpha })
        .expect(200)
        .then((res) => {
          expect(res.body.termsAgreedtoClosedAlpha).toEqual(
            termsAgreedtoClosedAlpha
          )
        })
    })
    // user/terms

    // user/avatar-type
    const avatarType = USER_AVATAR_TYPE.MIRROR_AVATAR_V1
    it('should fail without firebase auth', () => {
      return request(app.getHttpServer())
        .patch(`/user/avatar-type`)
        .send({ avatarType })
        .expect(403)
    })
    it('should update avatar-type  ', () => {
      return request(app.getHttpServer())
        .patch(`/user/avatar-type`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .send({ avatarType })
        .expect(200)
        .then((res) => {
          expect(res.body.avatarType).toEqual(avatarType)
        })
    })
    // user/avatar-type

    // entity-action/for-entity/:entityId
    let tempId = new ObjectId()
    it('should fail without firebase auth', () => {
      return request(app.getHttpServer())
        .get(`/user/entity-action/for-entity/${tempId}`)
        .expect(403)
    })
    it('should get entity  ', () => {
      return request(app.getHttpServer())
        .get(`/user/entity-action/for-entity/${tempId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
    })
    // entity-action/for-entity/:entityId

    // entity-action/me/for-entity/:entityId
    tempId = new ObjectId()
    it('should fail without firebase auth', () => {
      return request(app.getHttpServer())
        .get(`/user/entity-action/me/for-entity/${tempId}`)
        .expect(403)
    })
    it('should get my entity  ', () => {
      return request(app.getHttpServer())
        .get(`/user/entity-action/me/for-entity/${tempId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
    })
    // entity-action/me/for-entity/:entityId

    // user/entity-action
    const forEntity = new ObjectId()
    const actionType = USER_ENTITY_ACTION_TYPE.LIKE
    const entityType = ENTITY_TYPE.ASSET
    it('should fail without firebase auth', () => {
      return request(app.getHttpServer())
        .patch(`/user/entity-action`)
        .send({ forEntity, actionType, entityType })
        .expect(403)
    })
    it('should update entity-action  ', () => {
      return request(app.getHttpServer())
        .patch(`/user/entity-action`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .send({ forEntity, actionType, entityType })
        .expect(200)
        .then((res) => {
          expect(new ObjectId(res.body.forEntity)).toEqual(forEntity)
          expect(res.body.actionType).toEqual(actionType)
          expect(res.body.entityType).toEqual(entityType)
        })
    })
    // user/entity-action

    // user/entity-action delete
    const id = new ObjectId()
    it('should fail without firebase auth', () => {
      return request(app.getHttpServer())
        .delete(`/user/entity-action/${id}`)
        .expect(403)
    })
    it('should delete entity-action  ', () => {
      return request(app.getHttpServer())
        .delete(`/user/entity-action/${id}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
    })
    // user/entity-action delete

    // user/friend/me
    it('should fail without firebase auth', () => {
      return request(app.getHttpServer()).get(`/user/friends/me`).expect(403)
    })
    it('should get my friends', async () => {
      const query = `${profile1.email}`
      return request(app.getHttpServer())
        .get(`/user/friends/me`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body.friends).toBeDefined()
          expect(Array.isArray(res.body.friends)).toBe(true)
        })
    })
    // user/friend/me

    // user/friend-requests/me
    it('should fail without firebase auth', () => {
      return request(app.getHttpServer())
        .get(`/user/friend-requests/me`)
        .expect(403)
    })
    it('should get my  friends request', async () => {
      return request(app.getHttpServer())
        .get(`/user/friend-requests/me`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(Array.isArray(res.body)).toBe(true)
        })
    })
    // user/friend-requests/me

    // user/friend-requests/:toUserId (sending friend request to profile1)
    it('should fail without firebase auth', () => {
      return request(app.getHttpServer())
        .post(`/user/friend-requests/${profile1.localId}`)
        .expect(403)
    })
    it('should send friend request to profile1', async () => {
      return request(app.getHttpServer())
        .post(`/user/friend-requests/${profile1.localId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(201)
        .then((res) => {
          expect(res.body.sentFriendRequestsToUsers).toContain(profile1.localId)
        })
    })
    // user/friend-requests/:toUserId

    // user/friend-requests/accept/fromUserId (Accepting  profile1 friend request)
    it('should fail without firebase auth', () => {
      return request(app.getHttpServer())
        .post(`/user/friend-requests/accept/${profile1.localId}`)
        .expect(403)
    })
    it('should accept friend request to profile1', async () => {
      return request(app.getHttpServer())
        .post(`/user/friend-requests/accept/${profile1.localId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(201)
        .then((res) => {
          expect(res.body.friends).toContainEqual(
            expect.objectContaining({ _id: profile1.localId })
          )
        })
    })
    // user/friend-requests/accept/fromUserId

    // user/friend-requests/accept/fromUserId
    it('should fail without firebase auth', () => {
      return request(app.getHttpServer())
        .delete(`/user/friends/${profile1.localId}`)
        .expect(403)
    })
    it('should remove from friend to profile1', async () => {
      return request(app.getHttpServer())
        .delete(`/user/friends/${profile1.localId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body.friends).not.toContainEqual(
            expect.objectContaining({ _id: profile1.localId })
          )
        })
    })
    // user/friend-requests/accept/fromUserId

    /**
     * START Section: Cart  ------------------------------------------------------
     */
    it('should add an item to the user cart', async () => {
      const dto = {
        entityType: ENTITY_TYPE_AVAILABLE_TO_PURCHASE.ASSET,
        forEntity: '64ab42652bcdb7e656e6006a',
        purchaseOptionId: '64ab5ddfd31223b68f33aea4'
      }

      await request(app.getHttpServer())
        .post('/user/cart')
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .send(dto)
        .expect(201)
        .then((res) => {
          expect(res.body.cartItems).toHaveLength(1)
          expect(res.body.cartItems[0].entityType).toEqual(dto.entityType)
          expect(res.body.cartItems[0].forEntity).toEqual(dto.forEntity)
        })
    })

    it('should get the user cart', async () => {
      await request(app.getHttpServer())
        .get('/user/cart')
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(Array.isArray(res.body.cartItems)).toBe(true)
          expect(res.body.cartItems.length).toBeGreaterThanOrEqual(0)
        })
    })

    it('should remove an item from the user cart', async () => {
      const user = await request(app.getHttpServer())
        .get('/user/cart')
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => res.body)

      const cartItemId = user.cartItems[0]._id

      await request(app.getHttpServer())
        .delete(`/user/cart/${cartItemId}`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .expect(200)
        .then((res) => {
          expect(res.body.cartItems).toHaveLength(0)
          expect(res.body.cartItems).not.toContainEqual(
            expect.objectContaining({ _id: cartItemId })
          )
        })
    })

    /**
     * END Section: Cart  ------------------------------------------------------
     */

    // user/rpm-avatar-url
    const rpmAvatarUrl = 'themirror://avatar/astronaut-male'
    it('should fail without firebase auth', () => {
      return request(app.getHttpServer())
        .post(`/user/rpm-avatar-url`)
        .send({ rpmAvatarUrl })
        .expect(403)
    })
    it('should update the rpm url', async () => {
      return request(app.getHttpServer())
        .post(`/user/rpm-avatar-url`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .send({ rpmAvatarUrl })
        .expect(201)
        .then((res) => {
          expect(res.body.readyPlayerMeAvatarUrls).contain(rpmAvatarUrl)
        })
    })
    // user/rpm-avatar-url

    // user/access-key
    const token = process.env.SIGN_UP_KEY_TOKEN
    let key
    it('should fail without firebase auth', () => {
      return request(app.getHttpServer())
        .post(`/user/access-key`)
        .send({ token })
        .expect(403)
    })
    it('should create access token', async () => {
      return request(app.getHttpServer())
        .post(`/user/access-key`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .send({ token })
        .expect(201)
        .then((res) => {
          key = res.body.key
        })
    })
    // user/access-key

    // user/submit-user-access-key
    it('should fail without firebase auth', () => {
      return request(app.getHttpServer())
        .post(`/user/submit-user-access-key`)
        .send({ key })
        .expect(403)
    })
    it('should submit access key', async () => {
      return request(app.getHttpServer())
        .post(`/user/submit-user-access-key`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .send({ key })
        .expect(201)
    })
    // user/submit-user-access-key

    // user/rpm-avatar-url
    it('should fail without firebase auth', () => {
      return request(app.getHttpServer())
        .delete(`/user/rpm-avatar-url`)
        .send({ rpmAvatarUrl })
        .expect(403)
    })
    it('should delete rpm-avatar-url', async () => {
      return request(app.getHttpServer())
        .delete(`/user/rpm-avatar-url`)
        .set('Authorization', `Bearer ${userXAuthToken}`)
        .send({ rpmAvatarUrl })
        .expect(200)
    })
    // user/rpm-avatar-url
  })
})
