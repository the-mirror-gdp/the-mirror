import { Test, TestingModule } from '@nestjs/testing'
import { AssetModelStub } from '../../test/stubs/asset.model.stub'
import { AssetService } from './asset.service'
import { FileUploadService } from '../util/file-upload/file-upload.service'
import { AssetSearch } from './asset.search'
import { PaginationService } from '../util/pagination/pagination.service'
import { SpaceObjectModelStub } from '../../test/stubs/spaceObject.model.stub'
import { PurchaseOptionModelStub } from '../../test/stubs/purchaseoption.stub'
import { RoleService } from '../roles/role.service'
import { UserService } from '../user/user.service'
import { AssetAnalyzingService } from '../util/file-analyzing/asset-analyzing.service'

describe('AssetService', () => {
  let service: AssetService

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AssetService,
        {
          provide: 'AssetModel',
          useClass: AssetModelStub
        },
        {
          provide: 'MaterialModel',
          useClass: AssetModelStub
        },
        {
          provide: 'TextureModel',
          useClass: AssetModelStub
        },
        {
          provide: 'MapAssetModel',
          useClass: AssetModelStub
        },
        {
          provide: 'SpaceObjectModel',
          useClass: SpaceObjectModelStub
        },
        {
          provide: FileUploadService,
          useValue: {}
        },
        {
          provide: AssetSearch,
          useValue: {}
        },
        {
          provide: PaginationService,
          useValue: {}
        },
        {
          provide: RoleService,
          useValue: {}
        },
        {
          provide: 'PurchaseOptionModel',
          useClass: PurchaseOptionModelStub
        },
        {
          provide: UserService,
          useValue: {}
        },
        {
          provide: AssetAnalyzingService,
          useValue: {}
        }
      ]
    }).compile()

    service = module.get<AssetService>(AssetService)
  })

  it('should be defined', () => {
    expect(service).toBeDefined()
  })
})
