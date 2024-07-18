import { Test, TestingModule } from '@nestjs/testing'
import { TerrainModelStub } from '../../test/stubs/terrain.model.stub'
import { TerrainService } from './terrain.service'
import { FileUploadService } from '../util/file-upload/file-upload.service'

import { SpaceModelStub } from '../../test/stubs/space.model.stub'
import { SpaceService } from '../space/space.service'

describe('TerrainService', () => {
  let service: TerrainService

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TerrainService,
        {
          provide: 'TerrainModel',
          useClass: TerrainModelStub
        },
        {
          provide: 'SpaceModel',
          useClass: SpaceModelStub
        },
        { provide: FileUploadService, useValue: {} },
        { provide: SpaceService, useValue: {} }
      ]
    }).compile()

    service = module.get<TerrainService>(TerrainService)
  })

  it('should be defined', () => {
    expect(service).toBeDefined()
  })
})
