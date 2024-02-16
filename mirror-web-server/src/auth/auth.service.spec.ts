import { Test, TestingModule } from '@nestjs/testing'
import { AuthService } from './auth.service'
import { UserService } from '../user/user.service'
import { UserModelStub } from '../../test/stubs/user.model.stub'
import { LoggerModule } from '../util/logger/logger.module'
import { FirebaseAuthenticationService } from '../firebase/firebase-authentication.service'
import { FirebaseDatabaseService } from '../firebase/firebase-database.service'

describe('AuthService', () => {
  let service: AuthService

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [LoggerModule],
      providers: [
        AuthService,
        {
          provide: FirebaseAuthenticationService,
          useValue: {
            createUser: () => {} // eslint-disable-line
          }
        },
        {
          provide: FirebaseDatabaseService,
          useValue: {}
        },
        {
          provide: UserService,
          useValue: {}
        },
        {
          provide: 'UserModel',
          useClass: UserModelStub
        }
      ]
    }).compile()

    service = module.get<AuthService>(AuthService)
  })

  it('should be defined', () => {
    expect(service).toBeDefined()
  })
})
