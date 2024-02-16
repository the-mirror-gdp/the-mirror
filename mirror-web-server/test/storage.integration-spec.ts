import { INestApplication } from '@nestjs/common'
import { Test, TestingModule } from '@nestjs/testing'
import request from 'supertest'
import { beforeAll, describe, it } from 'vitest'
import { FirebaseAuthenticationService } from '../src/firebase/firebase-authentication.service'
import { MirrorServerConfigService } from '../src/mirror-server-config/mirror-server-config.service'
import { StorageController } from '../src/storage/storage.controller'
import { StorageService } from '../src/storage/storage.service'
import { LoggerModule } from '../src/util/logger/logger.module'
import { getMockClassesForProvidersArray } from './mocks/service.mocks'

describe('Storage Controller (Integration)', () => {
  let app: INestApplication

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [LoggerModule],
      controllers: [StorageController],
      providers: [
        ...getMockClassesForProvidersArray([
          StorageService,
          FirebaseAuthenticationService,
          MirrorServerConfigService
        ])
      ]
    }).compile()

    app = moduleFixture.createNestApplication()
    await app.init()
  })

  it('should fail without firebase auth', () => {
    return request(app.getHttpServer()).get('/storage/test').expect(403)
  })
})
