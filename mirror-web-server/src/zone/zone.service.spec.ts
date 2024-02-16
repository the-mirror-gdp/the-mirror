import { PaginationService } from './../util/pagination/pagination.service'
import { HttpModule } from '@nestjs/axios'
import { ZoneService } from './zone.service'
import { SpaceService } from '../space/space.service'
import { Test, TestingModule } from '@nestjs/testing'
import { SpaceManagerExternalService } from './space-manager-external.service'
import { ZoneModelStub } from '../../test/stubs/zone.model.stub'
import { SpaceModelStub } from '../../test/stubs/space.model.stub'
import { LoggerModule } from '../util/logger/logger.module'
import { PaginationModule } from '../util/pagination/pagination.module'
import { RoleModelStub } from '../../test/stubs/role.model.stub'
import { RoleService } from '../roles/role.service'
import { MirrorServerConfigService } from '../mirror-server-config/mirror-server-config.service'
import { UserService } from '../user/user.service'

describe('ZoneService', () => {
  let service: ZoneService

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [LoggerModule, HttpModule],
      providers: [
        ZoneService,
        {
          provide: 'ZoneModel',
          useClass: ZoneModelStub
        },
        {
          provide: 'SpaceModel',
          useClass: SpaceModelStub
        },
        {
          provide: 'RoleModel',
          useClass: RoleModelStub
        },
        { provide: SpaceService, useValue: {} },
        { provide: PaginationService, useValue: {} },
        { provide: SpaceManagerExternalService, useValue: {} },
        { provide: RoleService, useValue: {} },
        { provide: MirrorServerConfigService, useValue: {} },
        { provide: UserService, useValue: {} }
      ]
    }).compile()

    service = module.get<ZoneService>(ZoneService)
  })

  it('should be defined', () => {
    expect(service).toBeDefined()
  })
})
