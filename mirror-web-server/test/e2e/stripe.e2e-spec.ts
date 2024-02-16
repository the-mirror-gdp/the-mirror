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
import WebSocket from 'ws'
import { IsArray, IsUrl } from 'class-validator'
import { AddBank, CardToken } from '../../src/stripe/dto/token.dto'
import { PaymentIntentDto } from '../../src/stripe/dto/paymentIntent.dto'
import { TransfersDto } from '../../src/stripe/dto/transfers.dto'
import { Stripe } from 'stripe'
import { StripeAccountType } from '../../src/stripe/constants'
import mongoose from 'mongoose'
import { ObjectId } from 'mongodb'

/**
 * E2E Walkthrough: https://www.loom.com/share/cea8701390bf4e7ba234cc0689830399?from_recorder=1&focus_title=1
 */

describe('E2E : Stripe', () => {
  let app: INestApplication
  let mongoDbUrl
  let dbName
  let userXAuthToken
  let createdUserXId
  let userXAccountEmail
  let userXAccountPassword
  let cardToBeCreated

  let transferAccount
  let transferAccountToken
  const stripe: Stripe = new Stripe(process.env.STRIPE_SECRET_KEY as string, {
    apiVersion: '2022-11-15'
  })

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
    await app.init()

    // create an account
    const { email, password } = await createTestAccountOnFirebaseAndDb(app)

    // create an account to test transfer
    transferAccount = await createTestAccountOnFirebaseAndDb(app)
    // set the test-level variables
    userXAccountEmail = email
    userXAccountPassword = password
    const tokenResponse = await getFirebaseToken(email, password)
    // Firebase token to create stripe account for transferAccount
    transferAccountToken = await getFirebaseToken(
      transferAccount.email,
      transferAccount.password
    )
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

  it('should create the stripe account', async () => {
    return request(app.getHttpServer())
      .post(`/stripe/connect`)
      .set('Authorization', `Bearer ${userXAuthToken}`)
      .expect(201)
      .then((res) => {
        expect(res.body.object).toBe('account_link')
        expect(res.body.created).toBeDefined()
        expect(res.body.expires_at).toBeDefined()
        expect(IsUrl(res.body.url)).toBeTruthy()
      })
  })

  it('should create the stripe customer', async () => {
    return request(app.getHttpServer())
      .post(`/stripe/customer`)
      .set('Authorization', `Bearer ${userXAuthToken}`)
      .expect(201)
      .then((res) => {
        expect(res.body.id).toBe(createdUserXId)
        expect(res.body.stripeCustomerId).toBeDefined()
      })
  })

  it('should add card in stripe account', async () => {
    // stripe test card token :: tok_visa, tok_mastercard
    await request(app.getHttpServer())
      .post(`/stripe/card`)
      .set('Authorization', `Bearer ${userXAuthToken}`)
      .send({ token: 'tok_visa' })
      .expect(201)
      .then((res) => {
        cardToBeCreated = res.body[0]
      })
  })

  it('should get the card list', async () => {
    return request(app.getHttpServer())
      .get(`/stripe/cards`)
      .set('Authorization', `Bearer ${userXAuthToken}`)
      .expect(200)
      .then((res) => {
        expect(IsArray(res.body)).toBeTruthy()
        expect(res.body[0].id).toBe(cardToBeCreated.id)
      })
  })

  it('should create bank account', async () => {
    const BankInfo: AddBank = { token: 'pm_usBankAccount_success' }

    await request(app.getHttpServer())
      .post(`/stripe/add-bank-account`)
      .set('Authorization', `Bearer ${userXAuthToken}`)
      .send(BankInfo)
      .expect(201)
      .then((res) => {})
  })

  it('should get the account stripe info', async () => {
    return request(app.getHttpServer())
      .get(`/stripe/account-info`)
      .set('Authorization', `Bearer ${userXAuthToken}`)
      .expect(200)
      .then((res) => {
        expect(res.body.object).toBe('account')
      })
  })

  it('should create setup intent', async () => {
    return request(app.getHttpServer())
      .post(`/stripe/setup-intent`)
      .set('Authorization', `Bearer ${userXAuthToken}`)
      .send({ payment_method: cardToBeCreated.id })
      .expect(201)
      .then((res) => {
        expect(res.body.client_secret).toBeDefined()
      })
  })

  it('should create payment intent', async () => {
    const paymentIntent: PaymentIntentDto = {
      amount: 100000,
      currency: 'eur',
      payment_method: cardToBeCreated.id
    }
    return request(app.getHttpServer())
      .post(`/stripe/payment-intent`)
      .send(paymentIntent)
      .set('Authorization', `Bearer ${userXAuthToken}`)
      .expect(201)
      .then((res) => {
        expect(res.body.client_secret).toBeDefined()
      })
  })

  // Not able to test trasfers cause for user needs transfer enabled by default.
  // it takes time for transfer enable.
  // StripeInvalidRequestError: Your destination account needs to have at least one of the following capabilities enabled: transfers, crypto_transfers, legacy_payments

  it('should transfers the amount', async () => {
    const transferBody: TransfersDto = {
      amount: 100,
      currency: 'usd',
      destination: createdUserXId
    }
    return await request(app.getHttpServer())
      .post(`/stripe/transfers`)
      .send(transferBody)
      .set('Authorization', `Bearer ${userXAuthToken}`)
      .expect(201)
      .then((res) => {})
  })

  it('should get the products details', async () => {
    return request(app.getHttpServer())
      .get(`/stripe/products`)
      .set('Authorization', `Bearer ${userXAuthToken}`)
      .expect(200)
      .then((res) => {
        res.body.data.forEach((element) => {
          expect(element.object).toBe('price')
          expect(element.currency).toBeDefined()
          expect(element.productData).toBeDefined()
        })
      })
  })

  it('should delete the card ', async () => {
    return request(app.getHttpServer())
      .delete(`/stripe/card/${cardToBeCreated.id}`)
      .set('Authorization', `Bearer ${userXAuthToken}`)
      .expect(200)
      .then((res) => {
        expect(IsArray(res.body)).toBeTruthy()
        expect(res.body.length).toBe(0) // Added the only one card so after delete it's length should be 0
      })
  })

  it('should delete the stripe account', async () => {
    return request(app.getHttpServer())
      .delete(`/stripe/connect`)
      .set('Authorization', `Bearer ${userXAuthToken}`)
      .expect(200)
      .then((res) => {
        expect(res.body.premiumAccess).not.contain('PREMIUM_1')
        expect(res.body.stripeAccountId).toBe(null)
        expect(res.body.stripeCustomerId).toBe(null)
      })
  })
})
