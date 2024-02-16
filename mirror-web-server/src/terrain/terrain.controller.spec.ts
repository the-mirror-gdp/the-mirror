import { Test, TestingModule } from '@nestjs/testing'
import { firebaseAdminMock } from '../../test/mocks/firebase.mocks'
import { TerrainModelStub } from '../../test/stubs/terrain.model.stub'
import { LoggerModule } from '../util/logger/logger.module'
import { TerrainController } from './terrain.controller'
import { TerrainService } from './terrain.service'
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

describe('TerrainController', () => {
  let controller: TerrainController

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [TerrainController],
      imports: [
        ConfigModule.forRoot({ isGlobal: true }),
        firebaseAdminMock() as any,
        LoggerModule
      ],
      providers: [
        { provide: TerrainService, useValue: {} },
        {
          provide: 'TerrainModel',
          useClass: TerrainModelStub
        }
      ]
    }).compile()

    controller = module.get<TerrainController>(TerrainController)
  })

  it('should be defined', () => {
    expect(controller).toBeDefined()
  })
})
