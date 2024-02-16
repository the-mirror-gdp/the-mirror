import { app } from 'firebase-admin'
import { MongoClient } from 'mongodb'
import MongoMemoryServer from 'mongodb-memory-server-core'
import { seedDatabase } from './db-seed'
import {
  generateFormattedDate,
  generateRandomE2EEmail,
  generateRandomName
} from './e2e-util'
import request from 'supertest'
// 2023-07-03 00:43:50 note: this may cause full test suite bugs, but works with individual test suites (e.g. `yarn test:e2e zone`)
export const useInMemoryMongo = true
export const dropMongoDatabaseAfterTest = true

export function checkDbUriIsLocalHost(uri: string) {
  return uri?.includes('localhost') || uri?.includes('127.0.0.1')
}

export async function createTestAccountOnFirebaseAndDb(
  app,
  accountEmail = generateRandomE2EEmail(),
  accountPassword = generateRandomName()
) {
  return request(app.getHttpServer())
    .post(`/auth/email-password`)
    .send({
      email: accountEmail,
      password: accountPassword,
      displayName: `e2eTest ${accountEmail}`
    })
    .then((res) => {
      if (res.statusCode >= 300) {
        throw new Error(
          'Unable to create account: ' + JSON.stringify(res, null, 2)
        )
      }
      return { email: accountEmail, password: accountPassword }
    })
}

export async function initTestMongoDbWithSeed() {
  const dbName = 'ze2e_' + generateFormattedDate() // adding a "z" so it appears in the bottom of the MongoDB compass DB list (if used instead of monogdb-memory-server-core)
  let mongoDbUrl
  // check if localhost mongo or in memory. in-memory should generally be used. Localhost is there if you want to debug a test (you'd need to not drop the db via dropMongoDatabaseAfterTest: false)
  if (useInMemoryMongo) {
    // set the mongo instance to the in memory mongodb
    const mongod = await MongoMemoryServer.create({
      instance: {
        dbName
      }
    })
    mongoDbUrl = mongod.getUri() + dbName
    console.log('Using in-memory mongo. uri: ' + mongoDbUrl)
  } else {
    console.log('Using localhost mongo')
    mongoDbUrl = 'mongodb://localhost:27017/' + dbName
  }
  process.env.MONGODB_URL = mongoDbUrl

  // Start with a clean slate
  await clearTestDatabase(mongoDbUrl, dbName)
  // seed the db
  await seedDatabase(mongoDbUrl, dbName)

  return { mongoDbUrl, dbName }
}

export async function clearTestDatabase(
  uri: string, // don't default to process.env.MONGODB_URL here for safety. Force the test call to explicitly state the
  dbName: string
) {
  const client = new MongoClient(uri)
  const db = client.db(dbName)

  if (!checkDbUriIsLocalHost(uri)) {
    console.warn('Skipping clearTestDatabase because not on localhost')
    return
  }
  // safety check
  if (uri === 'themirror') {
    console.warn(`Safety: will not clear 'themirror' database`)
    return
    // double check for safety
  } else if (checkDbUriIsLocalHost(uri) && dropMongoDatabaseAfterTest) {
    try {
      await db.dropDatabase()
    } catch (error) {
      console.error(error)
    }
    return
  }
}

/**
 * @description Checks process.env.MONGODB_URL if the database is localhost. If not, it exits the process. This is to prevent accidentally running tests on a deployed database.
 * @date 2023-03-15 23:49
 */
export async function safetyCheckDatabaseForTest() {
  const uri = process.env.MONGODB_URL
  const isLocalhost = uri?.includes('localhost') || uri?.includes('127.0.0.1')
  if (!isLocalhost) {
    console.warn(
      'Database is not localhost. Exiting for safety to not affect a deployed database'
    )
    process.exit(1)
  }
}
