import { SpaceGateway } from './space.gateway'
import { SpaceService } from './space.service'
import { Test, TestingModule } from '@nestjs/testing'
import { LoggerModule } from '../util/logger/logger.module'
import { WsAuthHelperService } from '../godot-server/ws-auth-helper.service'

describe('SpaceGateway', () => {
  let gateway: SpaceGateway

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [LoggerModule],
      providers: [
        SpaceGateway,
        { provide: SpaceService, useValue: {} },
        { provide: WsAuthHelperService, useValue: {} }
      ]
    }).compile()

    gateway = module.get<SpaceGateway>(SpaceGateway)
  })

  it('should be defined', () => {
    expect(gateway).toBeDefined()
  })
})
