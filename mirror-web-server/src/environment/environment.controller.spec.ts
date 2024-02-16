import { Test, TestingModule } from '@nestjs/testing'
import { EnvironmentController } from './environment.controller'
import { EnvironmentService } from './environment.service'
import { firebaseAdminMock } from '../../test/mocks/firebase.mocks'
import { LoggerModule } from '../util/logger/logger.module'
import { ConfigModule } from '@nestjs/config'
import {
  afterAll,
  beforeAll,
  expect,
  it,
  vi,
  describe,
  beforeEach
} from 'vitest'

describe('EnvironmentController', () => {
  let controller: EnvironmentController

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({ isGlobal: true }),
        firebaseAdminMock() as any,
        LoggerModule
      ],
      controllers: [EnvironmentController],
      providers: [{ provide: EnvironmentService, useValue: {} }]
    }).compile()

    controller = module.get<EnvironmentController>(EnvironmentController)
  })

  it('should be defined', () => {
    expect(controller).toBeDefined()
  })
})
