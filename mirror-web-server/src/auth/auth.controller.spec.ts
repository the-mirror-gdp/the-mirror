import { Test, TestingModule } from '@nestjs/testing'
import { AuthController } from './auth.controller'
import { AuthService } from './auth.service'
import { UserService } from '../user/user.service'
import { FirebaseAuthenticationService } from '../firebase/firebase-authentication.service'
import { LoggerModule } from '../util/logger/logger.module'

describe('Auth Controller', () => {
  let controller: AuthController

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [LoggerModule],
      controllers: [AuthController],
      providers: [
        {
          provide: AuthService,
          useValue: {
            createUser: () => {} // eslint-disable-line
          }
        },
        {
          provide: FirebaseAuthenticationService,
          useValue: {
            createUser: () => {} // eslint-disable-line
          }
        },
        { provide: UserService, useValue: {} }
      ]
    }).compile()

    controller = module.get<AuthController>(AuthController)
  })

  it('should be defined', () => {
    expect(controller).toBeDefined()
  })
})
