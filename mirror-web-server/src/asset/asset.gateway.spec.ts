import { AssetGateway } from './asset.gateway'
import { AssetService } from './asset.service'
import { Test, TestingModule } from '@nestjs/testing'
import { LoggerModule } from '../util/logger/logger.module'

describe('AssetGateway', () => {
  let gateway: AssetGateway

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [LoggerModule],
      providers: [AssetGateway, { provide: AssetService, useValue: {} }]
    }).compile()

    gateway = module.get<AssetGateway>(AssetGateway)
  })

  it('should be defined', () => {
    expect(gateway).toBeDefined()
  })
})
