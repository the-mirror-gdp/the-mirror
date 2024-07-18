import { Test, TestingModule } from '@nestjs/testing'
import { LoggerModule } from '../util/logger/logger.module'
import { SpaceObjectGateway } from './space-object.gateway'
import { SpaceObjectService } from './space-object.service'
import { WsAuthHelperService } from '../godot-server/ws-auth-helper.service'

describe('SpaceObjectGateway', () => {
  let gateway: SpaceObjectGateway

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [LoggerModule],
      providers: [
        SpaceObjectGateway,
        {
          provide: SpaceObjectService,
          useValue: {}
        },
        { provide: WsAuthHelperService, useValue: {} }
      ]
    }).compile()

    gateway = module.get<SpaceObjectGateway>(SpaceObjectGateway)
  })

  it('should be defined', () => {
    expect(gateway).toBeDefined()
  })
})
