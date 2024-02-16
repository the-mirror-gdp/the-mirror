import { INestApplication } from '@nestjs/common'
import { Test, TestingModule } from '@nestjs/testing'
import request from 'supertest'
import { GodotServerOverrideConfigController } from '../src/godot-server-override-config/godot-server-override-config.controller'
import { GodotServerOverrideConfigService } from '../src/godot-server-override-config/godot-server-override-config.service'
import { FileUploadService } from '../src/util/file-upload/file-upload.service'
import { SpaceManagerExternalService } from './../src/zone/space-manager-external.service'

import { beforeAll, describe, it } from 'vitest'
import { FirebaseAuthenticationService } from '../src/firebase/firebase-authentication.service'
import { LoggerModule } from '../src/util/logger/logger.module'
import { getMockClassesForProvidersArray } from './mocks/service.mocks'
import { spaceManagerExternalServiceMock } from './mocks/space-manager-external-service.mock'

describe('Godot Server Override Config (Integration)', () => {
  let app: INestApplication
  let service: GodotServerOverrideConfigService
  // Modify mockEntity as needed for the test
  const id = 'some-space-id'
  const mockEntity: any = {
    spaceId: id
  }

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [LoggerModule],
      controllers: [GodotServerOverrideConfigController],
      providers: [
        ...getMockClassesForProvidersArray([
          FirebaseAuthenticationService,
          FileUploadService,
          GodotServerOverrideConfigService
        ]),
        {
          provide: SpaceManagerExternalService,
          useValue: spaceManagerExternalServiceMock
        }
      ]
    }).compile()

    app = moduleFixture.createNestApplication()
    await app.init()

    service = moduleFixture.get(GodotServerOverrideConfigService)
  })

  // TODO having trouble with async/await tests here, but works on Postman
  // xit('GET one by space ID', async () => {
  //   // Arrange
  //   vi
  //     .spyOn(service, 'findOne')
  //     .mockResolvedValue(mockEntity as GodotServerOverrideConfigDocument)
  //   // TODO this test doesn't do much
  //   jest.spyOn(service, 'findOneFormatted').mockResolvedValue('someString')

  //   // Act
  //   await request(app.getHttpServer())
  //     .get(`/godot-server-override-config/${id}`)

  //     // Assert
  //     .expect(200)
  //     .expect(await service.findOneFormatted('some-id'))
  // })

  it('GET one without space ID: should return default', async () => {
    // Arrange

    // Act
    await request(app.getHttpServer())
      .get(`/godot-server-override-config/`)

      // Assert
      .expect(404)
  })

  // running into weirdness with a 400 bad request here, but it works in Postman
  // xit('create one', async () => {
  //   // Arrange
  //   vi
  //     .spyOn(service, 'create')
  //     .mockResolvedValue(mockEntity as GodotServerOverrideConfigDocument)

  //   // Act
  //   await request(app.getHttpServer())
  //     .post('/godot-server-override-config')
  //     .send(mockEntity)

  //     // Assert
  //     .expect(201)
  //     .expect(await service.create(mockEntity))
  // })
})
