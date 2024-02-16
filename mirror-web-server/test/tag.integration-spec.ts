import { INestApplication } from '@nestjs/common'
import { Test, TestingModule } from '@nestjs/testing'
import request from 'supertest'
import { beforeAll, describe, it } from 'vitest'
import { FirebaseAuthenticationService } from '../src/firebase/firebase-authentication.service'
import { TagController } from '../src/tag/tag.controller'
import { TagService } from '../src/tag/tag.service'
import { LoggerModule } from '../src/util/logger/logger.module'
import {
  getMockClassesForProvidersArray,
  getMockMongooseModelsForProvidersArray
} from './mocks/service.mocks'

describe('Tag Controller (Integration)', () => {
  let app: INestApplication

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [LoggerModule],
      controllers: [TagController],
      providers: [
        ...getMockMongooseModelsForProvidersArray(),
        ...getMockClassesForProvidersArray([
          TagService,
          FirebaseAuthenticationService
        ])
      ]
    }).compile()

    app = moduleFixture.createNestApplication()
    await app.init()
  })

  it('should fail without firebase auth', () => {
    return request(app.getHttpServer()).get('/tag/testId').expect(403)
  })
})
