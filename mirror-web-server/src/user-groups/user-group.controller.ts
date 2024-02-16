import {
  Body,
  Controller,
  Delete,
  Get,
  HttpException,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
  UsePipes,
  ValidationPipe
} from '@nestjs/common'
import { FirebaseTokenAuthGuard } from '../auth/auth.guard'
import { CreateUserGroupDto } from './dto/create-group.users.dto'
import { UpdateUserGroupDto } from './dto/update-group.users.dto'
import { UserGroupService } from './user-group.service'
import { CreateUserGroupInviteDto } from './dto/create-group-users-invite.dto'
import { USER_GROUP_INVITE_STATUSES } from '../option-sets/user-group-invite-statuses'
import { UserGroupInviteService } from './user-group-invite.service'
import { CreateUserGroupRequestDto } from './dto/create-group-users-request.dto'
import { UserGroupAccessRequestService } from './user-group-access-request.service'
import { CreateUserGroupMembershipDto } from './dto/create-group-users-membership.dto'
import { USER_GROUP_MEMBERSHIP_STATUSES } from '../option-sets/user-group-membership-statuses'
import { GROUP_ROLE } from '../option-sets/group-users-roles'
import { UserGroupMembershipService } from './user-group-membership.service'
import { Roles } from '../roles/roles.decorator'
import { ROLE } from '../roles/models/role.enum'
import { ApiCreatedResponse, ApiOkResponse, ApiParam } from '@nestjs/swagger'
import { UserGroup } from './user-group.schema'
import { ApiResponseProperty } from '@nestjs/swagger/dist/decorators/api-property.decorator'
import { UserGroupInvite } from './user-group-invite.schema'
import { UserToken } from '../auth/get-user.decorator'

class UserGroupApiResponse extends UserGroup {
  @ApiResponseProperty()
  _id: string
}

class UserGroupInviteApiResponse extends UserGroupInvite {
  @ApiResponseProperty()
  _id: string
}

@UsePipes(new ValidationPipe({ whitelist: true }))
@Controller('user-group')
@FirebaseTokenAuthGuard()
export class UserGroupController {
  public static numberOfMonthsUntilInviteExpires = 1
  private searchMaxLimit = 500

  constructor(
    private readonly userGroupService: UserGroupService,
    private readonly userGroupInviteService: UserGroupInviteService,
    private readonly userGroupRequestAccessService: UserGroupAccessRequestService,
    private readonly userGroupMembershipService: UserGroupMembershipService
  ) {}

  @Post()
  @FirebaseTokenAuthGuard()
  @ApiCreatedResponse({ type: UserGroupApiResponse })
  public async create(
    @UserToken('user_id') userId: string,
    @Body() createUserGroupDto: CreateUserGroupDto,
    @Body() createUserGroupMembershipDto: CreateUserGroupMembershipDto
  ) {
    createUserGroupDto.creator = userId
    const createdGroup = await this.userGroupService.create(createUserGroupDto)

    const groupMembershipBase = this.createBaseNewUserMembership(
      createUserGroupMembershipDto,
      userId,
      createdGroup._id,
      GROUP_ROLE.GROUP_OWNER
    )
    await this.userGroupMembershipService.create(groupMembershipBase)

    return createdGroup
  }

  /**
   * @description Find all groups for current user
   */
  @Get('/my-groups')
  @ApiOkResponse({ type: [UserGroupApiResponse] })
  public async getAllGroupsForMe(@UserToken('user_id') userId: string) {
    return await this.userGroupService.findAllForUser(userId)
  }

  /**
   * @description Find all invites for the current user
   */
  @Get('/my-invites')
  @FirebaseTokenAuthGuard()
  @ApiOkResponse({ type: [UserGroupInviteApiResponse] })
  public async getAllGroupInvitesForMe(@UserToken('user_id') userId: string) {
    return await this.userGroupInviteService.findAllForUser(userId)
  }

  /**
   * @description This is used for another user, NOT the current user,
   * so we only get the PUBLIC groups that the person is a part of
   * TODO - add ApiOkResponse type for UserGroupMembership
   */
  @Get('/group-membership/:otherUserId')
  @ApiParam({ name: 'otherUserId', type: 'string', required: true })
  @FirebaseTokenAuthGuard()
  public async findPublicGroupMembershipForOtherUser(
    @Param('otherUserId') otherUserId: string
  ) {
    return await this.userGroupMembershipService.findPublicGroupMembershipForUser(
      otherUserId
    )
  }

  /**
   * @description Find all group members of current user
   * TODO - add ApiOkResponse type for UserGroupMembership
   */
  @Get('/my-group-membership/:id')
  @FirebaseTokenAuthGuard()
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async getGroupMembershipForMe(
    @UserToken('user_id') userId: string,
    @Param('id') id: string
  ) {
    return await this.userGroupMembershipService.findAllMembers(id, userId)
  }

  @Get('search')
  @ApiOkResponse({ type: [UserGroupApiResponse] })
  public async search(@Query() query) {
    const { filterField, filterValue, sortField, sortValue, limit, skip } =
      query

    return await this.userGroupService.search({
      filterField: filterField || 'name',
      filterValue: filterValue || '',
      sortField: sortField || 'name',
      sortValue: sortValue || 1,
      limit: limit && limit < this.searchMaxLimit ? limit : 25,
      skip: skip || 0
    })
  }

  @Get(':id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  @ApiOkResponse({ type: UserGroupApiResponse })
  public async findOne(@Param('id') id: string) {
    const groupFound = await this.userGroupService.findOne(id)
    return groupFound[0]
  }

  @Patch(':id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  @ApiOkResponse({ type: UserGroupApiResponse })
  public async update(
    @Param('id') id: string,
    @Body() updateUserGroupDto: UpdateUserGroupDto
  ) {
    return await this.userGroupService.update(id, updateUserGroupDto)
  }

  @Delete(':id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  @ApiOkResponse({ type: UserGroupApiResponse })
  @FirebaseTokenAuthGuard()
  public async remove(
    @UserToken('user_id') userId: string,
    @Param('id') id: string
  ) {
    const groupMembership =
      await this.userGroupMembershipService.findAllMembers(id, userId)
    //only owner can delete group
    // TODO this needs to be updated with RBAC
    if (groupMembership.role == 0) {
      return this.userGroupService.remove(id)
    } else {
      throw new HttpException('Forbidden', HttpStatus.FORBIDDEN)
    }
  }

  private makeInviteExpirationDate(): Date {
    const now = new Date()
    now.setMonth(
      now.getMonth() + UserGroupController.numberOfMonthsUntilInviteExpires
    )
    return now
  }

  private createBaseNewUserMembership(
    createGroupMembershipDto: CreateUserGroupMembershipDto,
    userId: string,
    groupId: string,
    role: GROUP_ROLE
  ) {
    createGroupMembershipDto.user = userId
    createGroupMembershipDto.status = USER_GROUP_MEMBERSHIP_STATUSES.ACTIVE
    createGroupMembershipDto.role = role
    createGroupMembershipDto.group = groupId
    return createGroupMembershipDto
  }
}
