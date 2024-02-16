import { Test, TestingModule } from '@nestjs/testing'
import { ScriptEntityModelStub } from '../../test/stubs/scriptEntity.model.stub'
import { ScriptEntityController } from './script-entity.controller'
import { ScriptEntityService } from './script-entity.service'
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

describe('ScriptEntityController', () => {
  let controller: ScriptEntityController

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [ScriptEntityController],
      imports: [
        ConfigModule.forRoot({ isGlobal: true }),
        firebaseAdminMock() as any,
        LoggerModule
      ],
      providers: [
        {
          provide: ScriptEntityService,
          useValue: {}
        },
        {
          provide: 'ScriptEntityModel',
          useClass: ScriptEntityModelStub
        }
      ]
    }).compile()

    controller = module.get<ScriptEntityController>(ScriptEntityController)
  })

  it('should be defined', () => {
    expect(controller).toBeDefined()
  })
})
