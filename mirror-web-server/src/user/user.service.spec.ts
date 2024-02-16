import { Test, TestingModule } from '@nestjs/testing'
import { UserService } from './user.service'
import {
  UserAccessKeyStub,
  UserEntityActionModelStub,
  UserModelStub
} from '../../test/stubs/user.model.stub'
import { CustomDataModelStub } from '../../test/stubs/custom-data.model.stub'
import { FirebaseAuthenticationService } from '../firebase/firebase-authentication.service'
import { FileUploadService } from '../util/file-upload/file-upload.service'
import { UserSearch } from './user.search'
import { CustomDataService } from '../custom-data/custom-data.service'

describe('UserService', () => {
  let service: UserService

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UserService,
        {
          provide: 'UserModel',
          useClass: UserModelStub
        },
        {
          provide: 'CustomDataModel',
          useClass: CustomDataModelStub
        },
        {
          provide: 'UserAccessKeyModel',
          useClass: UserAccessKeyStub
        },
        {
          provide: 'UserAccessKey',
          useClass: UserAccessKeyStub
        },
        {
          provide: 'UserEntityActionModel',
          useClass: UserEntityActionModelStub
        },
        { provide: CustomDataService, useValue: {} },
        { provide: FirebaseAuthenticationService, useValue: {} },
        { provide: FileUploadService, useValue: {} },
        { provide: UserSearch, useValue: {} }
      ]
    }).compile()

    service = module.get<UserService>(UserService)
  })

  it('should be defined', () => {
    expect(service).toBeDefined()
  })
})
