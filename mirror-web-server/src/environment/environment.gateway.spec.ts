import { Test, TestingModule } from '@nestjs/testing'
import { LoggerModule } from '../util/logger/logger.module'
import { EnvironmentGateway } from './environment.gateway'
import { EnvironmentService } from './environment.service'
import { WsAuthHelperService } from '../godot-server/ws-auth-helper.service'

describe('EnvironmentGateway', () => {
  let gateway: EnvironmentGateway

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [LoggerModule],
      providers: [
        EnvironmentGateway,
        { provide: EnvironmentService, useValue: {} },
        { provide: WsAuthHelperService, useValue: {} }
      ]
    }).compile()

    gateway = module.get<EnvironmentGateway>(EnvironmentGateway)
  })

  it('should be defined', () => {
    expect(gateway).toBeDefined()
  })
})
