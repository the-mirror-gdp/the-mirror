import { CustomDataService } from './../custom-data/custom-data.service'
import { Test, TestingModule } from '@nestjs/testing'
import { SpaceModelStub } from '../../test/stubs/space.model.stub'
import { LightModelStub } from '../../test/stubs/light.model.stub'
import { SpaceVersionModelStub } from '../../test/stubs/spaceVersion.model.stub'
import { SpaceService } from './space.service'
import { FileUploadService } from '../util/file-upload/file-upload.service'
import { SpaceSearch } from './space.search'
import { SpaceObjectService } from '../space-object/space-object.service'
import { TerrainService } from '../terrain/terrain.service'
import { EnvironmentService } from '../environment/environment.service'
import { AssetService } from '../asset/asset.service'
import { RoleService } from '../roles/role.service'
import { LoggerModule } from '../util/logger/logger.module'
import { PaginationModule } from '../util/pagination/pagination.module'
import { RoleModelStub } from '../../test/stubs/role.model.stub'
import { SpaceVariablesDataModelStub } from '../../test/stubs/space-variables-data.model.stub'
import { PaginationService } from '../util/pagination/pagination.service'
import { SpaceVariablesDataService } from '../space-variable/space-variables-data.service'
import { MirrorServerConfigService } from '../mirror-server-config/mirror-server-config.service'
import { SpaceObjectModelStub } from '../../test/stubs/spaceObject.model.stub'
import { ZoneService } from '../zone/zone.service'
import { UserService } from '../user/user.service'
import { RedisPubSubService } from '../redis/redis-pub-sub.service'
import { MirrorDBService } from '../mirror-db/mirror-db.service'
import { ScriptEntityService } from '../script-entity/script-entity.service'
import { MaterialInstanceService } from './material-instance/material-instance.service'

describe('SpaceService', () => {
  let service: SpaceService

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [LoggerModule],
      providers: [
        SpaceService,
        {
          provide: 'SpaceModel',
          useClass: SpaceModelStub
        },
        {
          provide: 'SpaceObjectModel',
          useClass: SpaceObjectModelStub
        },
        {
          provide: 'RoleModel',
          useClass: RoleModelStub
        },
        {
          provide: 'SpaceVersionModel',
          useClass: SpaceVersionModelStub
        },
        {
          provide: 'SpaceVariablesDataModel',
          useClass: SpaceVariablesDataModelStub
        },
        {
          provide: 'LightModel',
          useClass: LightModelStub
        },
        { provide: FileUploadService, useValue: {} },
        { provide: CustomDataService, useValue: {} },
        { provide: SpaceVariablesDataService, useValue: {} },
        { provide: SpaceSearch, useValue: {} },
        { provide: SpaceObjectService, useValue: {} },
        { provide: TerrainService, useValue: {} },
        { provide: EnvironmentService, useValue: {} },
        { provide: AssetService, useValue: {} },
        { provide: RoleService, useValue: {} },
        { provide: PaginationService, useValue: {} },
        { provide: MirrorServerConfigService, useValue: {} },
        { provide: ZoneService, useValue: {} },
        { provide: UserService, useValue: {} },
        { provide: RedisPubSubService, useValue: {} },
        { provide: MirrorDBService, useValue: {} },
        { provide: ScriptEntityService, useValue: {} },
        { provide: MaterialInstanceService, useValue: {} }
      ]
    }).compile()

    service = module.get<SpaceService>(SpaceService)
  })

  it('should be defined', () => {
    expect(service).toBeDefined()
  })
})
