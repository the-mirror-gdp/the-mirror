import { LoggerModule } from './../util/logger/logger.module'
import { Module } from '@nestjs/common'
import { MongooseModule } from '@nestjs/mongoose'
import {
  userGroupRequestAccessSchema,
  UserGroupRequestAccess
} from './user-group-access-request.schema'
import { userGroupInvite, UserGroupInvite } from './user-group-invite.schema'
import { UserGroupInviteService } from './user-group-invite.service'
import {
  UserGroupMembershipSchema,
  UserGroupMembership
} from './user-group-membership.schema'
import { UserGroupMembershipService } from './user-group-membership.service'
import { UserGroupAccessRequestService } from './user-group-access-request.service'
import { UserGroupController } from './user-group.controller'
import { UserGroup, UserGroupSchema } from './user-group.schema'
import { UserGroupService } from './user-group.service'

@Module({
  imports: [
    LoggerModule,
    MongooseModule.forFeature([
      { name: UserGroup.name, schema: UserGroupSchema },
      { name: UserGroupMembership.name, schema: UserGroupMembershipSchema },
      {
        name: UserGroupRequestAccess.name,
        schema: userGroupRequestAccessSchema
      },
      { name: UserGroupInvite.name, schema: userGroupInvite }
    ])
  ],
  controllers: [UserGroupController],
  providers: [
    UserGroupService,
    UserGroupMembershipService,
    UserGroupInviteService,
    UserGroupAccessRequestService
  ],
  exports: [UserGroupService]
})
export class UserGroupModule {}
