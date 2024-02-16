import { INestApplication } from '@nestjs/common'
import { Test, TestingModule } from '@nestjs/testing'
import request from 'supertest'
import { beforeAll, describe, it } from 'vitest'
import { FavoriteController } from '../src/favorite/favorite.controller'
import { FavoriteService } from '../src/favorite/favorite.service'
import { FirebaseAuthenticationService } from '../src/firebase/firebase-authentication.service'
import { LoggerModule } from '../src/util/logger/logger.module'
import {
  getMockClassesForProvidersArray,
  getMockMongooseModelsForProvidersArray
} from './mocks/service.mocks'

describe('Favorite Controller (Integration)', () => {
  let app: INestApplication

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [LoggerModule],
      controllers: [FavoriteController],
      providers: [
        ...getMockClassesForProvidersArray([
          FirebaseAuthenticationService,
          FavoriteService
        ]),
        ...getMockMongooseModelsForProvidersArray()
      ]
    }).compile()

    app = moduleFixture.createNestApplication()
    await app.init()
  })

  it('should fail without firebase auth', () => {
    return request(app.getHttpServer()).get('/favorite/testId').expect(403)
  })
})
