import { Test, TestingModule } from '@nestjs/testing'
import { TerrainModelStub } from '../../test/stubs/terrain.model.stub'
import { TerrainService } from './terrain.service'
import { FileUploadService } from '../util/file-upload/file-upload.service'

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
        { provide: FileUploadService, useValue: {} }
      ]
    }).compile()

    service = module.get<TerrainService>(TerrainService)
  })

  it('should be defined', () => {
    expect(service).toBeDefined()
  })
})
