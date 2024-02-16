import { INestApplication } from '@nestjs/common'
import { Test } from '@nestjs/testing'
import { isAfter, sub } from 'date-fns'
import request from 'supertest'
import { AppModule } from '../../src/app.module'
import { UserFeedbackItem } from './../../src/user-feedback/models/user-feedback/user-feedback-item.schema'
import {
  userFeedbackItemBug3ToBeCreated,
  userFeedbackItemFeature1ToBeCreated
} from './../stubs/user-feedback.stub'

import { deleteFirebaseTestAccount, getFirebaseToken } from './e2e-auth'

import { afterAll, beforeAll, describe, expect, it } from 'vitest'
import { ROLE } from '../../src/roles/models/role.enum'
import {
  clearTestDatabase,
  createTestAccountOnFirebaseAndDb,
  initTestMongoDbWithSeed,
  safetyCheckDatabaseForTest
} from './e2e-db-util'

/**
 * E2E Walkthrough: https://www.loom.com/share/cea8701390bf4e7ba234cc0689830399?from_recorder=1&focus_title=1
 */

describe.skip('E2E: UserFeedback', () => {
  let app: INestApplication
  let mongoDbUrl
  let dbName
  let authToken
  let createdUserId
  let accountEmail
  let accountPassword

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
    accountEmail = email
    accountPassword = password
    const tokenResponse = await getFirebaseToken(email, password)
    createdUserId = tokenResponse.localId
    authToken = tokenResponse.idToken
  })

  afterAll(async () => {
    await clearTestDatabase(mongoDbUrl, dbName)
    await deleteFirebaseTestAccount(app, accountEmail)
  })

  it('alive test: should get the version of the app', async () => {
    return request(app.getHttpServer())
      .get(`/util/version`)
      .expect(200)
      .then((res) => {
        expect(res.text).toEqual(require('../../package.json').version)
      })
  })

  // it('should succeed for some routes without auth', () => {
  //   return Promise.all([
  //     request(app.getHttpServer()).get(`/user-feedback/new`).expect(200),
  //     request(app.getHttpServer()).get(`/user-feedback/top`).expect(200),
  //     request(app.getHttpServer())
  //       .get(`/user-feedback/6427aeb7350c1a3e4f93536a`)
  //       .expect(404), // 404 is okay. We're checking that's it's not a 403
  //     request(app.getHttpServer())
  //       .get(`/user-feedback/comments/6427aeb7350c1a3e4f93536a`)
  //       .expect(200),
  //     request(app.getHttpServer()).get(`/user-feedback`).expect(200)
  //   ])
  // })

  // it('should fail without firebase auth for specific routes', () => {
  //   return Promise.all([
  //     request(app.getHttpServer()).post(`/user-feedback`).expect(403),
  //     request(app.getHttpServer()).post(`/user-feedback/vote`).expect(403),
  //     request(app.getHttpServer()).post(`/user-feedback/comment`).expect(403),
  //     request(app.getHttpServer())
  //       .delete(`/user-feedback/comment/id`)
  //       .expect(403),
  //     request(app.getHttpServer())
  //       .get(`/user-feedback/user-feedback-types`)
  //       .expect(403),
  //     request(app.getHttpServer())
  //       .patch(`/user-feedback/6427aeb7350c1a3e4f93536a`)
  //       .expect(403),
  //     request(app.getHttpServer())
  //       .delete(`/user-feedback/6427aeb7350c1a3e4f93536a`)
  //       .expect(403)
  //   ])
  // })

  // describe('Create, read, update, delete', () => {
  //   let publicUserFeedbackFeatureItemIdToBeCreated: Partial<UserFeedbackItem>
  //   let publicUserFeedbackFeatureBugIdToBeCreated: Partial<UserFeedbackItem>
  //   it('creates a user feedback item feature', () => {
  //     return request(app.getHttpServer())
  //       .post(`/user-feedback`)
  //       .send({
  //         ...userFeedbackItemFeature1ToBeCreated
  //       })
  //       .set('Authorization', `Bearer ${authToken}`)
  //       .expect(201)
  //       .then((res) => {
  //         expect(res.body._id.length).toBe(24) // mongo objectID length
  //         expect(res.body.name).toEqual(
  //           userFeedbackItemFeature1ToBeCreated.name
  //         )

  //         // ensure createdAt/updatedAt exist
  //         expect(res.body.createdAt).toBeTruthy()
  //         expect(res.body.updatedAt).toBeTruthy()
  //         // ensure createdAt/updatedAt is in the past minute
  //         const createdAtDate = new Date(res.body.createdAt)
  //         const updatedAtDate = new Date(res.body.updatedAt)
  //         const oneMinAgo = sub(new Date(), { minutes: 1 })
  //         expect(isAfter(createdAtDate, oneMinAgo)).toBeTruthy()
  //         expect(isAfter(updatedAtDate, oneMinAgo)).toBeTruthy()

  //         // ensure role is present
  //         expect(res.body.role).toBeTruthy()

  //         // Type
  //         expect(res.body.__t).toEqual('UserFeedbackItemFeatureRequest')

  //         publicUserFeedbackFeatureItemIdToBeCreated = res.body._id
  //       })
  //   })
  //   it('creates a user feedback item bug', () => {
  //     return request(app.getHttpServer())
  //       .post(`/user-feedback`)
  //       .send({
  //         ...userFeedbackItemBug3ToBeCreated
  //       })
  //       .set('Authorization', `Bearer ${authToken}`)
  //       .expect(201)
  //       .then((res) => {
  //         expect(res.body._id.length).toBe(24) // mongo objectID length
  //         expect(res.body.name).toEqual(userFeedbackItemBug3ToBeCreated.name)

  //         // ensure createdAt/updatedAt exist
  //         expect(res.body.createdAt).toBeTruthy()
  //         expect(res.body.updatedAt).toBeTruthy()
  //         // ensure createdAt/updatedAt is in the past minute
  //         const createdAtDate = new Date(res.body.createdAt)
  //         const updatedAtDate = new Date(res.body.updatedAt)
  //         const oneMinAgo = sub(new Date(), { minutes: 1 })
  //         expect(isAfter(createdAtDate, oneMinAgo)).toBeTruthy()
  //         expect(isAfter(updatedAtDate, oneMinAgo)).toBeTruthy()

  //         // ensure role is present
  //         expect(res.body.role).toBeTruthy()

  //         // Type
  //         expect(res.body.__t).toEqual('UserFeedbackItemBug')

  //         publicUserFeedbackFeatureBugIdToBeCreated = res.body._id
  //       })
  //   })
  //   it('can get the userfeedbackitem it just created', () => {
  //     return request(app.getHttpServer())
  //       .get(`/user-feedback/${publicUserFeedbackFeatureItemIdToBeCreated}`)
  //       .set('Authorization', `Bearer ${authToken}`)
  //       .expect(200)
  //       .then((res) => {
  //         expect(res.body.name).toEqual(
  //           userFeedbackItemFeature1ToBeCreated.name
  //         )
  //         expect(res.body.description).toEqual(
  //           userFeedbackItemFeature1ToBeCreated.description
  //         )

  //         // ensure that it was created with the correct role
  //         expect(res.body.role.defaultRole).toEqual(ROLE.OBSERVER)
  //         expect(res.body.role.users).toBeTruthy()
  //         expect(res.body.role.userGroups).toBeTruthy()
  //       })
  //   })
  //   it('can update the userfeedbackitem it just created', () => {
  //     const newName = 'new name'
  //     const newDescription = 'new description'
  //     return request(app.getHttpServer())
  //       .patch(`/user-feedback/${publicUserFeedbackFeatureItemIdToBeCreated}`)
  //       .set('Authorization', `Bearer ${authToken}`)
  //       .send({
  //         name: newName,
  //         description: newDescription
  //       })
  //       .expect(200)
  //       .then((res) => {
  //         expect(res.body.name).toEqual(newName)
  //         expect(res.body.description).toEqual(newDescription)
  //       })
  //   })

  //   it('creates a comment on the user feedback item', () => {
  //     return request(app.getHttpServer())
  //       .post(`/user-feedback/comment`)
  //       .send({
  //         text: 'test comment',
  //         userFeedbackItemId: publicUserFeedbackFeatureItemIdToBeCreated
  //       })
  //       .set('Authorization', `Bearer ${authToken}`)
  //       .expect(201)
  //   })

  //   it('can get a comment it created on the userFeedbackItemId', () => {
  //     return request(app.getHttpServer())
  //       .get(
  //         `/user-feedback/comments/${publicUserFeedbackFeatureItemIdToBeCreated}`
  //       )
  //       .set('Authorization', `Bearer ${authToken}`)
  //       .expect(200)
  //   })

  //   it('can delete the userfeedbackitem it just created', () => {
  //     return request(app.getHttpServer())
  //       .delete(`/user-feedback/${publicUserFeedbackFeatureItemIdToBeCreated}`)
  //       .set('Authorization', `Bearer ${authToken}`)
  //       .expect(200)
  //   })
  //   it('404s when trying to get the userfeedbackitem it just deleted', () => {
  //     return request(app.getHttpServer())
  //       .get(`/user-feedback/${publicUserFeedbackFeatureItemIdToBeCreated}`)
  //       .set('Authorization', `Bearer ${authToken}`)
  //       .expect(404)
  //   })

  // describe.skip('created a defaultRole of ROLE.OBSERVER for a public Userfeedbackitem', () => {
  //   return request(app.getHttpServer())
  //     .get(`/user-feedback/${publicUserFeedbackFeatureItemIdToBeCreated}`)
  //     .set('Authorization', `Bearer ${authToken}`)
  //     .expect(200)
  //     .then((res) => {
  //       // TODO add roles for userfeedbackitems
  //       // expect(res.body.role.defaultRole).toEqual(ROLE.OBSERVER)
  //     })
  // })
  // })
})
