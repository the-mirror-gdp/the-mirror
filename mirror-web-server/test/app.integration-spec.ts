import { Test, TestingModule } from '@nestjs/testing'
import { INestApplication } from '@nestjs/common'
import request from 'supertest'
import { AppController } from '../src/app.controller'
import { LoggerModule } from '../src/util/logger/logger.module'
import {
  afterAll,
  beforeAll,
  expect,
  it,
  vi,
  describe,
  beforeEach
} from 'vitest'

describe('AppController (Integration)', () => {
  let app: INestApplication

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [LoggerModule],
      controllers: [AppController]
    }).compile()

    app = moduleFixture.createNestApplication()
    await app.init()
  })

  it('/ (GET)', () => {
    return request(app.getHttpServer()).get('/').expect(200)
  })

  it('/util/version (GET)', () => {
    const version = require('../package.json').version // @ts-ignore
    return request(app.getHttpServer())
      .get('/util/version')
      .expect(200)
      .expect(version)
  })
})
