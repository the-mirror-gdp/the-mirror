import { Test, TestingModule } from '@nestjs/testing'
import { AssetModelStub } from '../../test/stubs/asset.model.stub'
import { AssetController } from './asset.controller'

import { AssetService } from './asset.service'
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
import { AuthGuardFirebase } from '../auth/auth.guard'

describe('AssetController', () => {
  let controller: AssetController

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [AssetController],
      imports: [
        ConfigModule.forRoot({ isGlobal: true }),
        firebaseAdminMock() as any,
        LoggerModule
      ],
      providers: [
        { provide: AssetService, useValue: {} },
        {
          provide: 'AssetModel',
          useClass: AssetModelStub
        },
        { provide: AuthGuardFirebase, useValue: {} }
      ]
    }).compile()

    controller = module.get<AssetController>(AssetController)
  })

  it('should be defined', () => {
    expect(controller).toBeDefined()
  })
})
