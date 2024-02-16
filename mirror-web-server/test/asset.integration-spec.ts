import { INestApplication, forwardRef } from '@nestjs/common'
import { Test, TestingModule } from '@nestjs/testing'
import request from 'supertest'
import { beforeAll, describe, it, vi } from 'vitest'
import { AssetController } from '../src/asset/asset.controller'
import { AssetService } from '../src/asset/asset.service'
import { FirebaseAuthenticationService } from '../src/firebase/firebase-authentication.service'
import { RoleService } from '../src/roles/role.service'
import { FileUploadService } from '../src/util/file-upload/file-upload.service'
import { LoggerModule } from '../src/util/logger/logger.module'
import { PaginationService } from '../src/util/pagination/pagination.service'
import { AssetSearch } from './../src/asset/asset.search'
import {
  getMockClassesForProvidersArray,
  getMockMongooseModelsForProvidersArray
} from './mocks/service.mocks'
import { UserService } from '../src/user/user.service'
import { UserModule } from '../src/user/user.module'
import { AssetAnalyzingService } from '../src/util/file-analyzing/asset-analyzing.service'
import { AuthGuardFirebase } from '../src/auth/auth.guard'

describe('Asset Controller (Integration)', () => {
  let app: INestApplication
  let assetService: AssetService

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [LoggerModule],
      controllers: [AssetController],
      providers: [
        ...getMockClassesForProvidersArray([
          FileUploadService,
          FirebaseAuthenticationService
        ]),
        AssetService,
        AssetSearch,
        PaginationService,
        RoleService,
        { provide: UserService, useValue: {} },
        ...getMockMongooseModelsForProvidersArray(),
        { provide: AssetAnalyzingService, useValue: {} },
        { provide: AuthGuardFirebase, useValue: {} }
      ]
    })
      .overrideProvider(FileUploadService)
      .useValue({})
      .compile()

    app = moduleFixture.createNestApplication()
    await app.init()

    assetService = moduleFixture.get(AssetService)
  })

  describe('Publicly accessible endpoints', () => {
    it('should pass search without firebase auth', () => {
      vi.spyOn(assetService, 'searchAssetsPublic').mockImplementation(
        async () => []
      )

      return request(app.getHttpServer())
        .get('/asset/search?email=test@test.com')
        .expect(200)
    })
  })

  describe('Auth required endpoints', () => {
    it('should fail getMirrorPublicLibraryAssets without firebase auth', () => {
      return request(app.getHttpServer()).get('/asset/library').expect(403)
    })

    it('should fail create without firebase auth', () => {
      return request(app.getHttpServer()).post('/asset').expect(403)
    })

    it('should fail getAssetsForMe without firebase auth', () => {
      return request(app.getHttpServer()).get('/asset/me').expect(403)
    })

    it('should fail findAllForUser without firebase auth', () => {
      return request(app.getHttpServer())
        .get('/asset/user/test-asset-id')
        .expect(403)
    })

    it('should fail findOne without firebase auth', () => {
      return request(app.getHttpServer())
        .get('/asset/test-asset-id')
        .expect(403)
    })

    it('should fail update without firebase auth', () => {
      return request(app.getHttpServer())
        .patch('/asset/test-asset-id')
        .expect(403)
    })

    it('should fail remove without firebase auth', () => {
      return request(app.getHttpServer())
        .delete('/asset/test-asset-id')
        .expect(403)
    })

    it('should fail upload without firebase auth', () => {
      return request(app.getHttpServer())
        .post('/asset/test-asset-id/upload')
        .expect(403)
    })

    it('should fail uploadPublic without firebase auth', () => {
      return request(app.getHttpServer())
        .post('/asset/test-asset-id/upload/public')
        .expect(403)
    })
  })
})
