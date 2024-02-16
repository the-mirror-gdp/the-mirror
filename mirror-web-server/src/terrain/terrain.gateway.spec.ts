import { Test, TestingModule } from '@nestjs/testing'
import { LoggerModule } from '../util/logger/logger.module'
import { TerrainGateway } from './terrain.gateway'
import { TerrainService } from './terrain.service'

describe('TerrainGateway', () => {
  let gateway: TerrainGateway

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [LoggerModule],
      providers: [TerrainGateway, { provide: TerrainService, useValue: {} }]
    }).compile()

    gateway = module.get<TerrainGateway>(TerrainGateway)
  })

  it('should be defined', () => {
    expect(gateway).toBeDefined()
  })
})
