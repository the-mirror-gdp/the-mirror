import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UsePipes,
  ValidationPipe
} from '@nestjs/common'
import {
  CreateUserFeedbackItemBugDto,
  CreateUserFeedbackItemDto,
  CreateUserFeedbackItemFeatureRequestDto,
  CreateVoteOnUserFeedbackItemDto
} from './dto/create-user-feedback.dto'
import { UpdateUserFeedbackDto } from './dto/update-user-feedback.dto'
import { UserFeedbackService } from './user-feedback.service'
import { FirebaseTokenAuthGuard } from '../auth/auth.guard'
import { Roles } from '../roles/roles.decorator'
import { ROLE } from '../roles/models/role.enum'
import {
  ApiBody,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiOperation,
  ApiParam
} from '@nestjs/swagger'
import { UserFeedbackItem } from './models/user-feedback/user-feedback-item.schema'
import { ApiResponseProperty } from '@nestjs/swagger/dist/decorators/api-property.decorator'
import { UserToken } from '../auth/get-user.decorator'
import { USER_FEEDBACK_ITEM_TYPE } from '../option-sets/user-feedback'
import { CreateUserFeedbackCommentDto } from './dto/create-user-feedback-comment.dto'
import { UserFeedbackComment } from './models/comments/user-feedback-comment.schema'
import { MongoObjectIdString } from '../util/mongo-object-id-helpers'

class UserFeedbackItemResponse extends UserFeedbackItem {
  @ApiResponseProperty()
  _id: string
  @ApiResponseProperty()
  createdAt: Date
  @ApiResponseProperty()
  updatedAt: Date
  @ApiResponseProperty()
  __t: 'UserFeedbackItemFeatureRequest' | 'UserFeedbackItemBug'
}
class UserFeedbackCommentResponse extends UserFeedbackComment {
  @ApiResponseProperty()
  _id: string
  @ApiResponseProperty()
  createdAt: Date
  @ApiResponseProperty()
  updatedAt: Date
}
/**
 * @description Wordy name, but this is catch-all class for user feedback that we publcily dislay. UserFeedbackItem is a top-level class that can have tags, comments, and votes.
 * @date 2023-02-17 15:47
 */
@UsePipes(new ValidationPipe({ whitelist: false }))
@Controller('user-feedback')
export class UserFeedbackController {
  constructor(private readonly userFeedbackService: UserFeedbackService) {}

  /**
   *
   * PUBLICLY ACCESSIBLE ENDPOINTS
   */

  @Get('/new')
  @ApiOkResponse({ type: [UserFeedbackItemResponse] })
  public async findNewestPublicUserFeedbackItems() {
    return await this.userFeedbackService.findNewestPublicUserFeedbackItemsAdmin()
  }

  @Get('/top')
  @ApiOkResponse({ type: [UserFeedbackItemResponse] })
  public async findTopPublicUserFeedbackItems() {
    return await this.userFeedbackService.findTopPublicUserFeedbackItemsAdmin()
  }

  @Get('/user-feedback-types')
  @ApiOperation({
    summary: 'Get all user feedback types from the USER_FEEDBACK_TYPE enum'
  })
  @ApiOkResponse({ type: [String] })
  @FirebaseTokenAuthGuard()
  public getUserFeedbackItemTypes() {
    return this.userFeedbackService.getUserFeedbackItemTypes()
  }

  @Get(':id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  @ApiOkResponse({ type: UserFeedbackItemResponse })
  public async findOne(
    @UserToken('user_id') userId: string,
    @Param('id') id: string
  ) {
    return await this.userFeedbackService.findOneWithRolesCheck(userId, id)
  }

  @Get('comments/:userFeedbackItemId')
  @ApiParam({ name: 'userFeedbackItemId', type: 'string', required: true })
  @ApiOkResponse({ type: [UserFeedbackCommentResponse] })
  public async findComments(
    @Param('userFeedbackItemId') id: MongoObjectIdString
  ) {
    return await this.userFeedbackService.findCommentsForUserFeedbackAdmin(id)
  }

  @Get()
  @ApiOkResponse({ type: [UserFeedbackItemResponse] })
  public async findAllPublicUserFeedbackItems() {
    return await this.userFeedbackService.findAllPublicUserFeedbackItemsAdmin()
  }

  @Post()
  @ApiBody({
    type: CreateUserFeedbackItemDto // 2023-02-13 14:08:07 not sure how to do multiple DTO types at the moment, such just adding parent DTO
  })
  @ApiCreatedResponse({
    type: UserFeedbackItemResponse
  })
  @FirebaseTokenAuthGuard()
  public async create(
    @Body()
    createUserFeedbackDto: CreateUserFeedbackItemDto &
      CreateUserFeedbackItemFeatureRequestDto &
      CreateUserFeedbackItemBugDto,
    @UserToken('user_id') userId: string
  ) {
    // check whether to use the subclass as determined by USER_FEEDBACK_TYPE
    switch (createUserFeedbackDto.userFeedbackType) {
      case USER_FEEDBACK_ITEM_TYPE.FEATURE_REQUEST:
        return await this.userFeedbackService.createUserFeedbackItemFeatureRequestWithRolesCheck(
          userId,
          {
            ...createUserFeedbackDto
          }
        )
      case USER_FEEDBACK_ITEM_TYPE.BUG:
        return await this.userFeedbackService.createUserFeedbackItemBugWithRolesCheck(
          userId,
          {
            ...createUserFeedbackDto
          }
        )

      default: // default to feature request
        return await this.userFeedbackService.createUserFeedbackItemFeatureRequestWithRolesCheck(
          userId,
          {
            ...createUserFeedbackDto
          }
        )
    }
  }

  @Post('vote')
  @ApiBody({
    type: CreateVoteOnUserFeedbackItemDto
  })
  @ApiOkResponse({
    type: UserFeedbackItemResponse
  })
  @ApiCreatedResponse({
    type: UserFeedbackItemResponse
  })
  @FirebaseTokenAuthGuard()
  voteOnUserFeedbackItem(
    @UserToken('user_id') userId: string,
    @Body() createVoteOnUserFeedbackItemDto: CreateVoteOnUserFeedbackItemDto
  ) {
    return this.userFeedbackService.voteOnUserFeedbackItem({
      votingUserId: userId,
      ...createVoteOnUserFeedbackItemDto
    })
  }

  @Post('comment')
  @ApiBody({
    type: CreateUserFeedbackCommentDto
  })
  @ApiCreatedResponse({
    type: UserFeedbackCommentResponse
  })
  @FirebaseTokenAuthGuard()
  public async createComment(
    @Body()
    createUserFeedbackCommentDto: CreateUserFeedbackCommentDto,
    @UserToken('user_id') userId: string
  ) {
    return await this.userFeedbackService.createUserFeedbackComment({
      creatorId: userId,
      ...createUserFeedbackCommentDto
    })
  }

  @Patch(':id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  @FirebaseTokenAuthGuard()
  public async update(
    @UserToken('user_id') userId: string,
    @Param('id') id: string,
    @Body() updateUserFeedbackDto: UpdateUserFeedbackDto
  ) {
    return await this.userFeedbackService.updateOneWithRolesCheck(
      userId,
      id,
      updateUserFeedbackDto
    )
  }

  @Delete(':id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  @FirebaseTokenAuthGuard()
  public async removeUserFeedbackItem(
    @UserToken('user_id') userId: string,
    @Param('id') id: string
  ) {
    return await this.userFeedbackService.removeOneWithRolesCheck(userId, id)
  }

  @Delete('comment/:id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  @FirebaseTokenAuthGuard()
  public async removeComment(
    @Param('id') commentId: string,
    @UserToken('user_id') userId: string
  ) {
    return await this.userFeedbackService.removeCommentWithRolesCheck(
      userId,
      commentId
    )
  }
}
