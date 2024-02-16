import { INestApplication } from '@nestjs/common'
import { Test, TestingModule } from '@nestjs/testing'
import request from 'supertest'
import { beforeAll, describe, it, vi } from 'vitest'
import {
  AuthGuardFirebase,
  FirebaseTokenAuthGuard
} from '../src/auth/auth.guard'
import { FirebaseAuthenticationService } from '../src/firebase/firebase-authentication.service'
import { CreateSpaceObjectDto } from '../src/space-object/dto/create-space-object.dto'
import { UpdateSpaceObjectDto } from '../src/space-object/dto/update-space-object.dto'
import { SpaceObjectController } from '../src/space-object/space-object.controller'
import {
  SpaceObject,
  SpaceObjectDocument
} from '../src/space-object/space-object.schema'
import { SpaceObjectService } from '../src/space-object/space-object.service'
import { FileUploadService } from '../src/util/file-upload/file-upload.service'
import { LoggerModule } from '../src/util/logger/logger.module'
import { getMockClassesForProvidersArray } from './mocks/service.mocks'

describe('Space Object Controller With Guard (Integration)', () => {
  let app: INestApplication
  let service: SpaceObjectService
  // Modify mockEntity as needed for the test
  const randomId = 'some-id'

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [LoggerModule],
      controllers: [SpaceObjectController],
      providers: [
        ...getMockClassesForProvidersArray([
          FirebaseAuthenticationService,
          SpaceObjectService,
          FileUploadService
        ])
      ]
    })
      // Note: guard is NOT overridden here
      .compile()

    app = moduleFixture.createNestApplication()
    await app.init()

    service = moduleFixture.get(SpaceObjectService)
  })

  describe('Auth required endpoints', () => {
    it('should fail findOne without firebase auth', () => {
      return request(app.getHttpServer())
        .get(`/space-object/${randomId}`)
        .expect(403)
    })
    it('should fail create without firebase auth: deprecated route', () => {
      return request(app.getHttpServer())
        .post('/space-object/space')
        .expect(403)
    })
    it('should fail create without firebase auth: new route', () => {
      return request(app.getHttpServer()).post('/space-object').expect(403)
    })
    it('should fail update without firebase auth', () => {
      return request(app.getHttpServer())
        .patch(`/space-object/${randomId}`)
        .expect(403)
    })
    it('should fail delete without firebase auth', () => {
      return request(app.getHttpServer())
        .delete(`/space-object/${randomId}`)
        .expect(403)
    })
    /**
     * Permissions
     */
    // 2023-03-09 00:51:42 TODO: get these working
    // xit('should return space data if the Space is public', () => {
    //   return request(app.getHttpServer())
    //     .get(`/space-object/${spaceObject2InPublicManagerSpace}`)
    //     .expect(200)
    // })
    // xit('should not return space data if the Space is private', () => {
    //   return request(app.getHttpServer())
    //     .get(`/space-object/${spaceObject1InPrivateSpace}`)
    //     .expect(403)
    // })
  })
})

// 2023-04-21 01:21:47 commenting this out for now since it's a fairly useless test and we test it with E2E
describe.skip('Space-Object Controller WITHOUT Guard (Integration)', () => {
  let app: INestApplication
  let service: SpaceObjectService
  // Modify mockEntity as needed for the test
  const id = 'some-id'
  const mockEntity: SpaceObject = {
    name: 'testName'
  } as SpaceObject
  const mockCreateDto: CreateSpaceObjectDto = {
    name: 'aliquip tempo',
    spaceId: '622ae1aae722b0ebb8255c5c',
    description: 'ipsum qui proident velit',
    asset: '62341fbfd50090ff09dab70b'
  }
  const mockUpdateDto: UpdateSpaceObjectDto = mockCreateDto

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      controllers: [SpaceObjectController],
      providers: [
        ...getMockClassesForProvidersArray([
          FirebaseAuthenticationService,
          SpaceObjectService,
          FileUploadService
        ])
      ]
    })
      .overrideGuard(AuthGuardFirebase)
      .useValue({
        canActivate: () => true
      })
      .overrideGuard(FirebaseTokenAuthGuard)
      .useValue({
        canActivate: () => true
      })
      .compile()

    app = moduleFixture.createNestApplication()
    await app.init()

    service = moduleFixture.get(SpaceObjectService)
  })

  // 2023-04-21 01:21:47 commenting this out for now since it's a fairly useless test and we test it with E2E
  // xit('find one by ID', async () => {
  //   // Arrange
  //   jest
  //     .spyOn(service, 'findOneAdmin')
  //     .mockResolvedValue(mockEntity as SpaceObjectDocument)

  //   // Act
  //   await request(app.getHttpServer())
  //     .get(`/space-object/${id}`)

  //     // Assert
  //     .expect(200)
  //     .expect(await service.findOneAdmin('some-id'))
  // })

  it('create one', async () => {
    // Arrange
    vi.spyOn(service, 'createAndNotifyAdmin').mockResolvedValue(
      mockEntity as SpaceObjectDocument
    )

    // Act
    await request(app.getHttpServer())
      .post('/space-object')
      .send(mockCreateDto)

      // Assert
      .expect(201)
      .expect(
        await service.createAndNotifyAdmin({
          name: 'testName',
          spaceId: 'testSpaceId',
          creatorUserId: 'creatorUserId',
          asset: 'testAssetId'
        })
      )
  })

  it('should update one with an id', async () => {
    // Arrange
    vi.spyOn(service, 'updateOne').mockResolvedValue(
      mockEntity as SpaceObjectDocument
    )

    // Act
    await request(app.getHttpServer())
      .patch(`/space-object/${id}`)
      .send(mockUpdateDto)

      // Assert
      .expect(200)
      .expect(
        await service.updateOne(id, {
          _id: 'newId',
          name: 'testName',
          spaceId: 'testSpaceId',
          asset: 'testAssetId'
        } as unknown as CreateSpaceObjectDto)
      )
  })

  it('should delete one by id', async () => {
    // Arrange
    vi.spyOn(service, 'removeOneAdmin').mockResolvedValue(
      mockEntity as SpaceObjectDocument
    )

    // Act
    await request(app.getHttpServer())
      .delete(`/space-object/${id}`)

      // Assert
      .expect(200)
      .expect(await service.removeOneAdmin(id))
  })
})
