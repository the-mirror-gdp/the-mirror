import { Test, TestingModule } from '@nestjs/testing'
import { FavoriteController } from './favorite.controller'
import { FavoriteService } from './favorite.service'
import { FavoriteModelStub } from '../../test/stubs/favorite.model.stub'
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

describe('FavoriteController', () => {
  let controller: FavoriteController

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [FavoriteController],
      imports: [
        ConfigModule.forRoot({ isGlobal: true }),
        firebaseAdminMock() as any,
        LoggerModule
      ],
      providers: [
        { provide: FavoriteService, useValue: {} },
        {
          provide: 'FavoriteModel',
          useClass: FavoriteModelStub
        }
      ]
    }).compile()

    controller = module.get<FavoriteController>(FavoriteController)
  })

  it('should be defined', () => {
    expect(controller).toBeDefined()
  })
})
