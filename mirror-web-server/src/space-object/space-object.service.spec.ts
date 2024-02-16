import { RoleModule } from './../roles/role.module'
import { LoggerModule } from './../util/logger/logger.module'
import { SpaceService } from './../space/space.service'
import { RoleService } from './../roles/role.service'
import { Test, TestingModule } from '@nestjs/testing'
import { SpaceObjectModelStub } from '../../test/stubs/spaceObject.model.stub'
import { SpaceObjectService } from './space-object.service'
import { RedisPubSubService } from '../redis/redis-pub-sub.service'
import { PaginationService } from '../util/pagination/pagination.service'
import { AssetService } from '../asset/asset.service'
import { SpaceObjectSearch } from './space-object.search'

describe('SpaceObjectService', () => {
  let service: SpaceObjectService

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [LoggerModule],
      providers: [
        SpaceObjectService,
        {
          provide: SpaceService,
          useValue: {}
        },
        { provide: RoleService, useValue: {} },
        {
          provide: 'SpaceObjectModel',
          useClass: SpaceObjectModelStub
        },
        { provide: RedisPubSubService, useValue: {} },
        {
          provide: PaginationService,
          useValue: {}
        },
        {
          provide: AssetService,
          useValue: {}
        },
        {
          provide: SpaceObjectSearch,
          useValue: {}
        }
      ]
    }).compile()

    service = module.get<SpaceObjectService>(SpaceObjectService)
  })

  it('should be defined', () => {
    expect(service).toBeDefined()
  })
})
