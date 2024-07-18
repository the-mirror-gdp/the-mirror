import { Test, TestingModule } from '@nestjs/testing'
import { EnvironmentService } from './environment.service'
import { EnvironmentModelStub } from '../../test/stubs/environment.model.stub'
import { SpaceService } from '../space/space.service'

describe('EnvironmentService', () => {
  let service: EnvironmentService

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        EnvironmentService,
        { provide: 'EnvironmentModel', useClass: EnvironmentModelStub },
        {
          provide: 'SpaceModel',
          useValue: {}
        },
        {
          provide: SpaceService,
          useValue: {}
        }
      ]
    }).compile()

    service = module.get<EnvironmentService>(EnvironmentService)
  })

  it('should be defined', () => {
    expect(service).toBeDefined()
  })
})
