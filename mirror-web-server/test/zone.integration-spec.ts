import { HttpModule } from '@nestjs/axios'
import { INestApplication } from '@nestjs/common'
import { Test, TestingModule } from '@nestjs/testing'
import request from 'supertest'
import { beforeAll, describe, it } from 'vitest'
import { AssetSearch } from '../src/asset/asset.search'
import { AssetService } from '../src/asset/asset.service'
import { CustomDataService } from '../src/custom-data/custom-data.service'
import { EnvironmentService } from '../src/environment/environment.service'
import { FirebaseAuthenticationService } from '../src/firebase/firebase-authentication.service'
import { RedisPubSubService } from '../src/redis/redis-pub-sub.service'
import { RoleService } from '../src/roles/role.service'
import { SpaceObjectService } from '../src/space-object/space-object.service'
import { SpaceVariablesDataService } from '../src/space-variable/space-variables-data.service'
import { SpaceSearch } from '../src/space/space.search'
import { SpaceService } from '../src/space/space.service'
import { TerrainService } from '../src/terrain/terrain.service'
import { FileUploadService } from '../src/util/file-upload/file-upload.service'
import { LoggerModule } from '../src/util/logger/logger.module'
import { PaginationService } from '../src/util/pagination/pagination.service'
import { SpaceManagerExternalService } from '../src/zone/space-manager-external.service'
import { ZoneController } from '../src/zone/zone.controller'
import { ZoneService } from '../src/zone/zone.service'
import {
  getMockClassesForProvidersArray,
  getMockMongooseModelsForProvidersArray
} from './mocks/service.mocks'
import { spaceManagerExternalServiceMock } from './mocks/space-manager-external-service.mock'

describe('Zone Controller (Integration)', () => {
  let app: INestApplication

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [HttpModule, LoggerModule],
      controllers: [ZoneController],
      providers: [
        AssetSearch,
        SpaceSearch,
        PaginationService,
        RoleService,
        {
          provide: SpaceManagerExternalService,
          useValue: spaceManagerExternalServiceMock
        },
        ...getMockClassesForProvidersArray([
          ZoneService,
          SpaceService,
          SpaceObjectService,
          FileUploadService,
          RedisPubSubService,
          AssetService,
          EnvironmentService,
          CustomDataService,
          SpaceVariablesDataService,
          TerrainService,
          FirebaseAuthenticationService
        ]),
        ...getMockMongooseModelsForProvidersArray()
      ]
    }).compile()

    app = moduleFixture.createNestApplication()
    await app.init()
  })

  it('should fail without firebase auth', () => {
    return request(app.getHttpServer()).get('/zone/testId').expect(403)
  })
})
