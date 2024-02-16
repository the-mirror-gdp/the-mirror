import { Test, TestingModule } from '@nestjs/testing'
import { MaterialInstanceModelStub } from '../../../test/stubs/materialInstance.model.stub'
import { MaterialInstanceController } from './material-instance.controller'
import { MaterialInstanceService } from './material-instance.service'
import { firebaseAdminMock } from '../../../test/mocks/firebase.mocks'
import { LoggerModule } from '../../util/logger/logger.module'
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

describe('MaterialInstanceController', () => {
  let controller: MaterialInstanceController

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [MaterialInstanceController],
      imports: [
        ConfigModule.forRoot({ isGlobal: true }),
        firebaseAdminMock() as any,
        LoggerModule
      ],
      providers: [
        {
          provide: MaterialInstanceService,
          useValue: {}
        },
        {
          provide: 'MaterialInstanceModel',
          useClass: MaterialInstanceModelStub
        }
      ]
    }).compile()

    controller = module.get<MaterialInstanceController>(
      MaterialInstanceController
    )
  })

  it('should be defined', () => {
    expect(controller).toBeDefined()
  })
})
