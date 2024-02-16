import { Test, TestingModule } from '@nestjs/testing'
import { EnvironmentService } from './environment.service'
import { EnvironmentModelStub } from '../../test/stubs/environment.model.stub'

describe('EnvironmentService', () => {
  let service: EnvironmentService

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        EnvironmentService,
        { provide: 'EnvironmentModel', useClass: EnvironmentModelStub }
      ]
    }).compile()

    service = module.get<EnvironmentService>(EnvironmentService)
  })

  it('should be defined', () => {
    expect(service).toBeDefined()
  })
})
