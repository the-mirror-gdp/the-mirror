import { INestApplication } from '@nestjs/common'
import { Test, TestingModule } from '@nestjs/testing'
import request from 'supertest'
import { beforeEach, describe, it, vi } from 'vitest'
import { UserController } from '../src/user/user.controller'
import { User, UserPublicData } from '../src/user/user.schema'
import { UserService } from '../src/user/user.service'
import { LoggerModule } from '../src/util/logger/logger.module'
import { FirebaseAuthenticationService } from '../src/firebase/firebase-authentication.service'
import { MockMongooseClass } from './mocks/mongoose-module.mock'
import { Model } from 'mongoose'
import { getModelToken } from '@nestjs/mongoose'
import { UserSearch } from '../src/user/user.search'
import { FileUploadService } from '../src/util/file-upload/file-upload.service'
import { CustomDataService } from '../src/custom-data/custom-data.service'
import {
  getMockClassesForProvidersArray,
  getMockMongooseModelsForProvidersArray
} from './mocks/service.mocks'
import { AssetService } from '../src/asset/asset.service'
import { AssetSearch } from '../src/asset/asset.search'

describe('User Controller (Integration)', () => {
  let app: INestApplication
  let userService: UserService
  let mockUserModel: Model<any>
  let mockUserAccessKeyModel: Model<any>
  let mockUserEntityActionModel: Model<any>
  let mockCustomDataModel: Model<any>

  const apiClient = () => {
    return request(app.getHttpServer())
  }

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [LoggerModule],
      controllers: [UserController],
      providers: [
        UserService,
        UserSearch,
        AssetSearch,
        CustomDataService,
        ...getMockClassesForProvidersArray([
          FirebaseAuthenticationService,
          FileUploadService
        ]),
        ...getMockMongooseModelsForProvidersArray()
      ]
    }).compile()

    app = moduleFixture.createNestApplication()
    await app.init()

    userService = moduleFixture.get(UserService)

    mockUserModel = moduleFixture.get<Model<any>>(getModelToken('User'))
    mockUserAccessKeyModel = moduleFixture.get<Model<any>>(
      getModelToken('UserAccessKey')
    )
    mockUserEntityActionModel = moduleFixture.get<Model<any>>(
      getModelToken('UserEntityAction')
    )
    mockCustomDataModel = moduleFixture.get<Model<any>>(
      getModelToken('CustomData')
    )
  })

  describe('Publicly accessible endpoints', () => {
    it('should allow search without firebase auth', () => {
      vi.spyOn(userService, 'searchForPublicUsers').mockResolvedValue([])
      return apiClient().get('/user/search?email=test@test.com').expect(200)
    })

    it('should allow findOneWithPublicProfile without firebase auth', () => {
      vi.spyOn(userService, 'findPublicUserFullProfile').mockResolvedValue(
        {} as User
      )
      return apiClient().get('/user/user-test-id/public-profile').expect(200)
    })

    it('should allow findPublicUser without firebase auth', () => {
      vi.spyOn(userService, 'findPublicUser').mockResolvedValue(
        {} as UserPublicData
      )
      return apiClient().get('/user/id/user-test-id').expect(200)
    })
  })

  describe('Auth required endpoints', () => {
    it('should fail uploadPublic without firebase auth', () => {
      return apiClient().get('/user/me').expect(403)
    })

    it('should fail updateProfile without firebase auth', () => {
      return apiClient().patch('/user/profile').expect(403)
    })

    it('should fail updateDeepLink without firebase auth', () => {
      return apiClient().patch('/user/deep-link').expect(403)
    })

    it('should fail updateAvatarType without firebase auth', () => {
      return apiClient().patch('/user/deep-link').expect(403)
    })

    it('should fail addRpmAvatarUrl without firebase auth', () => {
      return apiClient().post('/user/rpm-avatar-url').expect(403)
    })

    it('should fail removeRpmAvatarUrl without firebase auth', () => {
      return apiClient().delete('/user/rpm-avatar-url').expect(403)
    })
  })
})
