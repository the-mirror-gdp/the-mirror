import { ZoneService } from './zone.service'
import { ZoneController } from './zone.controller'
import { Test, TestingModule } from '@nestjs/testing'
import { SpaceService } from '../space/space.service'
import { SpaceManagerExternalService } from './space-manager-external.service'
import { ZoneModelStub } from '../../test/stubs/zone.model.stub'
import { SpaceModelStub } from '../../test/stubs/space.model.stub'
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

describe('ZoneController', () => {
  let controller: ZoneController

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [ZoneController],
      imports: [
        ConfigModule.forRoot({ isGlobal: true }),
        firebaseAdminMock() as any,
        LoggerModule
      ],
      providers: [
        { provide: SpaceService, useValue: {} },
        { provide: SpaceManagerExternalService, useValue: {} },
        { provide: ZoneService, useValue: {} },
        {
          provide: 'ZoneModel',
          useClass: ZoneModelStub
        },
        {
          provide: 'SpaceModel',
          useClass: SpaceModelStub
        }
      ]
    }).compile()

    controller = module.get<ZoneController>(ZoneController)
  })

  it('should be defined', () => {
    expect(controller).toBeDefined()
  })
})
