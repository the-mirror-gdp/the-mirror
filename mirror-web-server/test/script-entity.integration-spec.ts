import { INestApplication } from '@nestjs/common'
import { Test, TestingModule } from '@nestjs/testing'
import request from 'supertest'
import { beforeAll, describe, it, vi } from 'vitest'
import {
  AuthGuardFirebase,
  FirebaseTokenAuthGuard
} from '../src/auth/auth.guard'
import { FirebaseAuthenticationService } from '../src/firebase/firebase-authentication.service'
import { ScriptEntityController } from '../src/script-entity/script-entity.controller'
import {
  ScriptEntity,
  ScriptEntityDocument
} from '../src/script-entity/script-entity.schema'
import { ScriptEntityService } from '../src/script-entity/script-entity.service'
import { FileUploadService } from '../src/util/file-upload/file-upload.service'
import { LoggerModule } from '../src/util/logger/logger.module'
import {
  MockScriptEntityService,
  getMockClassesForProvidersArray
} from './mocks/service.mocks'

describe('Script-Entity Controller With Guard (Integration)', () => {
  let app: INestApplication
  let service: ScriptEntityService
  const id = 'some-id'

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [LoggerModule],
      controllers: [ScriptEntityController],
      providers: [
        ...getMockClassesForProvidersArray([
          FirebaseAuthenticationService,
          ScriptEntityService,
          FileUploadService
        ])
      ]
    })
      // Note: guard is NOT overridden here
      .compile()

    app = moduleFixture.createNestApplication()
    await app.init()

    service = moduleFixture.get(ScriptEntityService)
  })

  describe('Auth required endpoints', () => {
    it('should fail findOne without firebase auth', () => {
      return request(app.getHttpServer())
        .get(`/script-entity/${id}`)
        .expect(403)
    })
    it('should fail create without firebase auth', () => {
      return request(app.getHttpServer()).post('/script-entity').expect(403)
    })
    it('should fail update without firebase auth', () => {
      return request(app.getHttpServer())
        .patch(`/script-entity/${id}`)
        .expect(403)
    })
    it('should fail delete without firebase auth', () => {
      return request(app.getHttpServer())
        .delete(`/script-entity/${id}`)
        .expect(403)
    })
  })
})

describe('Script-Entity Controller WITHOUT Guard (Integration)', () => {
  let app: INestApplication
  let service: ScriptEntityService
  // Modify mockEntity as needed for the test
  const id = 'some-id'
  const mockEntity: ScriptEntity = {
    blocks: [{ foo: 'bar' }],
    _id: id
  }

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      controllers: [ScriptEntityController],
      providers: [
        {
          provide: ScriptEntityService,
          useClass: MockScriptEntityService
        },
        ...getMockClassesForProvidersArray([
          FirebaseAuthenticationService,
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

    service = moduleFixture.get(ScriptEntityService)
  })

  it('find one by ID', async () => {
    // Arrange
    vi.spyOn(service, 'findOne').mockResolvedValue(
      mockEntity as ScriptEntityDocument
    )

    // Act
    await request(app.getHttpServer())
      .get(`/script-entity/${id}`)

      // Assert
      .expect(200)
      .expect(await service.findOne('some-id'))
  })

  it('create one', async () => {
    // Arrange
    vi.spyOn(service, 'create').mockResolvedValue(
      mockEntity as ScriptEntityDocument
    )

    // Act
    await request(app.getHttpServer())
      .post('/script-entity')
      .send(mockEntity)

      // Assert
      .expect(201)
      .expect(await service.create(mockEntity))
  })

  it('should update one with an id', async () => {
    // Arrange
    vi.spyOn(service, 'update').mockResolvedValue(
      mockEntity as ScriptEntityDocument
    )

    // Act
    await request(app.getHttpServer())
      .patch(`/script-entity/${id}`)
      .send(mockEntity)

      // Assert
      .expect(200)
      .expect(await service.update(id, mockEntity))
  })

  it('should delete one by id', async () => {
    // Arrange
    vi.spyOn(service, 'delete').mockResolvedValue(
      mockEntity as ScriptEntityDocument
    )

    // Act
    await request(app.getHttpServer())
      .delete(`/script-entity/${id}`)

      // Assert
      .expect(200)
      .expect(await service.delete(id))
  })
})
