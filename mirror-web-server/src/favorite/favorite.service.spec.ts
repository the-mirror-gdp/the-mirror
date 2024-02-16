import { Test, TestingModule } from '@nestjs/testing'
import { FavoriteModelStub } from '../../test/stubs/favorite.model.stub'
import { FavoriteService } from './favorite.service'

describe('FavoriteService', () => {
  let service: FavoriteService

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FavoriteService,
        {
          provide: 'FavoriteModel',
          useClass: FavoriteModelStub
        }
      ]
    }).compile()

    service = module.get<FavoriteService>(FavoriteService)
  })

  it('should be defined', () => {
    expect(service).toBeDefined()
  })
})
