import { Test, TestingModule } from '@nestjs/testing'
import { firebaseAdminMock } from '../../test/mocks/firebase.mocks'
import { GroupModelStub } from '../../test/stubs/group.model.stub'
import { UserGroupController } from './user-group.controller'
import { UserGroupService } from './user-group.service'
import { UserGroupInviteService } from './user-group-invite.service'
import { UserGroupAccessRequestService } from './user-group-access-request.service'
import { UserGroupMembershipService } from './user-group-membership.service'
import { LoggerModule } from '../util/logger/logger.module'
import { ConfigModule } from '@nestjs/config'
import {
  afterAll,
  beforeAll,
  expect,
  it,
  vi,
  describe,
  beforeEach
} from 'vitest'

describe('UserGroupController', () => {
  let controller: UserGroupController

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [UserGroupController],
      imports: [
        ConfigModule.forRoot({ isGlobal: true }),
        firebaseAdminMock() as any,
        LoggerModule
      ],
      providers: [
        UserGroupService,
        {
          provide: 'UserGroupModel',
          useClass: GroupModelStub
        },
        { provide: UserGroupInviteService, useValue: {} },
        { provide: UserGroupAccessRequestService, useValue: {} },
        { provide: UserGroupMembershipService, useValue: {} }
      ]
    }).compile()

    controller = module.get<UserGroupController>(UserGroupController)
  })

  it('should be defined', () => {
    expect(controller).toBeDefined()
  })
})
