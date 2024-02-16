import { INestApplication } from '@nestjs/common'
import { Test, TestingModule } from '@nestjs/testing'
import request from 'supertest'
import { beforeAll, describe, it } from 'vitest'
import { AssetSearch } from '../src/asset/asset.search'
import { AssetService } from '../src/asset/asset.service'
import { AuthController } from '../src/auth/auth.controller'
import { AuthService } from '../src/auth/auth.service'
import { CustomDataService } from '../src/custom-data/custom-data.service'
import { FirebaseAuthenticationService } from '../src/firebase/firebase-authentication.service'
import { FirebaseDatabaseService } from '../src/firebase/firebase-database.service'
import { RoleService } from '../src/roles/role.service'
import { UserSearch } from '../src/user/user.search'
import { UserService } from '../src/user/user.service'
import { FileUploadService } from '../src/util/file-upload/file-upload.service'
import { LoggerModule } from '../src/util/logger/logger.module'
import { PaginationService } from '../src/util/pagination/pagination.service'
import {
  createViMockClass,
  getMockClassesForProvidersArray,
  getMockMongooseModelsForProvidersArray
} from './mocks/service.mocks'

describe('Auth Controller (Integration)', () => {
  let app: INestApplication

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [LoggerModule],
      controllers: [AuthController],
      providers: [
        ...getMockClassesForProvidersArray([
          CustomDataService,
          AuthService,
          FirebaseAuthenticationService,
          FirebaseDatabaseService,
          FileUploadService
        ]),
        ...getMockMongooseModelsForProvidersArray(),
        UserSearch,
        { provide: AssetService, useValue: {} },
        AssetSearch,
        PaginationService,
        RoleService,
        {
          provide: UserService,
          useClass: createViMockClass(UserService) // I'm not sure why this has to be useClass here when others work well with getMockClassesForProvidersArray 2023-07-03 18:36:08
        }
      ]
    }).compile()

    app = moduleFixture.createNestApplication()
    await app.init()
  })

  it('should pass when creating a new user', () => {
    const mockUserData = {
      displayName: 'Tes Terrino',
      email: 'tes@terrino.com',
      password: 'test123',
      termsAgreedtoGeneralTOSandPP: true
    }
    return request(app.getHttpServer())
      .post('/auth/email-password')
      .send({ ...mockUserData })
      .expect(201)
  })
})
