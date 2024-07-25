import { Test, TestingModule } from '@nestjs/testing'
import { RedisPubSubService } from '../redis/redis-pub-sub.service'
import { LoggerModule } from '../util/logger/logger.module'
import { GodotGateway } from './godot.gateway'
import { FirebaseAuthenticationService } from '../firebase/firebase-authentication.service'
import { WsAuthHelperService } from './ws-auth-helper.service'

describe('GodotGateway', () => {
  let gateway: GodotGateway

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [LoggerModule],
      providers: [
        GodotGateway,
        { provide: RedisPubSubService, useValue: {} },
        { provide: FirebaseAuthenticationService, useValue: {} },
        { provide: WsAuthHelperService, useValue: {} }
      ]
    }).compile()

    gateway = module.get<GodotGateway>(GodotGateway)
  })

  it('should be defined', () => {
    expect(gateway).toBeDefined()
  })
})
