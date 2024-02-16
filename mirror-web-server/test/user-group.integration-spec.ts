import { INestApplication } from '@nestjs/common'
import { Test, TestingModule } from '@nestjs/testing'
import request from 'supertest'
import { beforeAll, describe, it } from 'vitest'
import { FirebaseAuthenticationService } from '../src/firebase/firebase-authentication.service'
import { UserGroupAccessRequestService } from '../src/user-groups/user-group-access-request.service'
import { UserGroupInviteService } from '../src/user-groups/user-group-invite.service'
import { UserGroupMembershipService } from '../src/user-groups/user-group-membership.service'
import { UserGroupController } from '../src/user-groups/user-group.controller'
import { UserGroupService } from '../src/user-groups/user-group.service'
import { LoggerModule } from '../src/util/logger/logger.module'
import { getMockClassesForProvidersArray } from './mocks/service.mocks'

describe('UserGroup Controller (Integration)', () => {
  let app: INestApplication

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [LoggerModule],
      controllers: [UserGroupController],
      providers: [
        UserGroupService,
        UserGroupInviteService,
        UserGroupAccessRequestService,
        UserGroupMembershipService,
        ...getMockClassesForProvidersArray([
          FirebaseAuthenticationService,
          UserGroupMembershipService,
          UserGroupService,
          UserGroupInviteService,
          UserGroupAccessRequestService
        ])
      ]
    }).compile()

    app = moduleFixture.createNestApplication()
    await app.init()
  })

  it('should fail without firebase auth', () => {
    return request(app.getHttpServer()).get('/user-group/my-groups').expect(403)
  })
})
