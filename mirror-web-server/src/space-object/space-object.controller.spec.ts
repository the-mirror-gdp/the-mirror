import { Test, TestingModule } from '@nestjs/testing'
import { SpaceObjectModelStub } from '../../test/stubs/spaceObject.model.stub'
import { SpaceObjectController } from './space-object.controller'
import { SpaceObjectService } from './space-object.service'
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

describe('SpaceObjectController', () => {
  let controller: SpaceObjectController

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [SpaceObjectController],
      imports: [
        ConfigModule.forRoot({ isGlobal: true }),
        firebaseAdminMock() as any,
        LoggerModule
      ],
      providers: [
        { provide: SpaceObjectService, useValue: {} },
        {
          provide: 'SpaceObjectModel',
          useClass: SpaceObjectModelStub
        }
      ]
    }).compile()

    controller = module.get<SpaceObjectController>(SpaceObjectController)
  })

  it('should be defined', () => {
    expect(controller).toBeDefined()
  })
})
