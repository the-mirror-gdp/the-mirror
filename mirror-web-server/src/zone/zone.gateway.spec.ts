import { Test, TestingModule } from '@nestjs/testing'
import { ZoneGateway } from './zone.gateway'
import { ZoneService } from './zone.service'
import { SpaceManagerExternalService } from './space-manager-external.service'
import { LoggerModule } from '../util/logger/logger.module'

describe('ZoneGateway', () => {
  let gateway: ZoneGateway

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [LoggerModule],
      providers: [
        ZoneGateway,
        { provide: ZoneService, useValue: {} },
        { provide: SpaceManagerExternalService, useValue: {} }
      ]
    }).compile()

    gateway = module.get<ZoneGateway>(ZoneGateway)
  })

  it('should be defined', () => {
    expect(gateway).toBeDefined()
  })
})
