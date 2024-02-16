import { Test, TestingModule } from '@nestjs/testing'
import { FileUploadService } from '../util/file-upload/file-upload.service'
import { firebaseAdminMock } from '../../test/mocks/firebase.mocks'
import { SpaceModelStub } from '../../test/stubs/space.model.stub'
import { SpaceVersionModelStub } from '../../test/stubs/spaceVersion.model.stub'
import { SpaceController } from './space.controller'
import { SpaceService } from './space.service'
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
import { ScriptEntityModule } from '../script-entity/script-entity.module'
import { ScriptEntityService } from 'src/script-entity/script-entity.service'
import { DomainOrAuthUserGuard } from './guards/DomainOrAuthUserGuard.guard'
import { AuthGuardFirebase } from '../auth/auth.guard'

describe('SpaceController', () => {
  let controller: SpaceController

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [SpaceController],
      imports: [
        ConfigModule.forRoot({ isGlobal: true }),
        firebaseAdminMock() as any,
        LoggerModule
      ],
      providers: [
        { provide: SpaceService, useValue: {} },
        {
          provide: 'SpaceModel',
          useClass: SpaceModelStub
        },
        {
          provide: 'SpaceVersionModel',
          useClass: SpaceVersionModelStub
        },
        { provide: FileUploadService, useValue: {} },
        { provide: ScriptEntityModule, useValue: {} },
        { provide: DomainOrAuthUserGuard, useValue: {} },
        { provide: AuthGuardFirebase, useValue: {} }
      ]
    }).compile()

    controller = module.get<SpaceController>(SpaceController)
  })

  it('should be defined', () => {
    expect(controller).toBeDefined()
  })
})
