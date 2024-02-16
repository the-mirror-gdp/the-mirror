import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  InternalServerErrorException,
  NotFoundException
} from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { ObjectId } from 'mongodb'
import { Document, Model } from 'mongoose'
import {
  USER_FEEDBACK_ITEM_TYPE,
  USER_FEEDBACK_ITEM_VOTE
} from '../option-sets/user-feedback'
import { ROLE } from '../roles/models/role.enum'
import { Role } from '../roles/models/role.schema'
import { IRoleConsumer } from '../roles/role-consumer.interface'
import { RoleService } from '../roles/role.service'
import { MongoObjectIdString } from '../util/mongo-object-id-helpers'
import { CreateUserFeedbackCommentDto } from './dto/create-user-feedback-comment.dto'
import {
  CreateUserFeedbackItemBugDto,
  CreateUserFeedbackItemFeatureRequestDto,
  CreateVoteOnUserFeedbackItemDto
} from './dto/create-user-feedback.dto'
import { UpdateUserFeedbackDto } from './dto/update-user-feedback.dto'
import {
  UserFeedbackComment,
  UserFeedbackCommentDocument
} from './models/comments/user-feedback-comment.schema'
import {
  UserFeedbackItemBug,
  UserFeedbackItemBugDocument
} from './models/user-feedback/user-feedback-item-bug.schema'
import {
  UserFeedbackItemFeatureRequest,
  UserFeedbackItemFeatureRequestDocument
} from './models/user-feedback/user-feedback-item-feature-request.schema'
import {
  UserFeedbackItem,
  UserFeedbackItemDocument
} from './models/user-feedback/user-feedback-item.schema'

export type UserFeedbackItemDocumentWithPopulatedProperties =
  UserFeedbackItemDocument & {
    userFeedbackItem: UserFeedbackItemDocument
    role: Role
  }

@Injectable()
export class UserFeedbackService implements IRoleConsumer {
  constructor(
    @InjectModel(UserFeedbackItem.name)
    private userFeedbackItemModel: Model<UserFeedbackItemDocument>,
    @InjectModel(UserFeedbackItemFeatureRequest.name)
    private userFeedbackItemFeatureRequestModel: Model<UserFeedbackItemFeatureRequestDocument>,
    @InjectModel(UserFeedbackItemBug.name)
    private userFeedbackItemBugModel: Model<UserFeedbackItemBugDocument>,
    @InjectModel(UserFeedbackComment.name)
    private userFeedbackCommentModel: Model<UserFeedbackCommentDocument>,
    private roleService: RoleService
  ) {}
  createOneWithRolesCheck?(
    userId: string,
    dto: any
  ): Promise<Partial<Document<any, any, any>>> {
    throw new Error('Method not implemented.')
  }

  private _standardPopulateFields = ['creator']

  /**
   * @description note that there isn't a way to create a general UserFeedbackItem without a discriminator currently (2023-02-17 16:10:21). We can add that, but if a USER_FEEDBACK_TYPE isn't specified, we default to a USER_FEEDBACK_TYPE.FEATURE_REQUEST
   * @date 2023-02-17 16:11
   */
  async createUserFeedbackItemFeatureRequestWithRolesCheck(
    userId: string,
    createUserFeedbackDto: CreateUserFeedbackItemFeatureRequestDto
  ): Promise<UserFeedbackItemFeatureRequestDocument> {
    if (this.canCreateWithRolesCheck(userId)) {
      const createdUserFeedbackItem =
        new this.userFeedbackItemFeatureRequestModel({
          ...createUserFeedbackDto,
          creator: userId,
          owner: userId
        })
      // TODO: add role logic
      try {
        const role = await this.roleService.create({
          defaultRole: ROLE.OBSERVER,
          creator: userId,
          users: {},
          userGroups: {}
        })
        createdUserFeedbackItem.role = role
      } catch (error: any) {
        throw new InternalServerErrorException('Error creating Roles document')
      }
      return createdUserFeedbackItem.save()
    } else {
      throw new ForbiddenException()
    }
  }

  async createUserFeedbackItemBugWithRolesCheck(
    userId: string,
    createUserFeedbackDto: CreateUserFeedbackItemFeatureRequestDto
  ): Promise<UserFeedbackItemFeatureRequestDocument> {
    if (this.canCreateWithRolesCheck(userId)) {
      const createdUserFeedbackItem = new this.userFeedbackItemBugModel({
        ...createUserFeedbackDto,
        creator: userId,
        owner: userId
      })

      try {
        const role = await this.roleService.create({
          defaultRole: ROLE.OBSERVER,
          creator: userId,
          users: {},
          userGroups: {}
        })
        createdUserFeedbackItem.role = role
      } catch (error: any) {
        throw new InternalServerErrorException('Error creating Roles document')
      }
      return createdUserFeedbackItem.save()
    } else {
    }
  }

  async createUserFeedbackComment(
    createUserFeedbackCommentDto: CreateUserFeedbackCommentDto & {
      creatorId: string
    }
  ): Promise<UserFeedbackCommentDocument> {
    const created = new this.userFeedbackCommentModel({
      ...createUserFeedbackCommentDto,
      userFeedbackItem: createUserFeedbackCommentDto.userFeedbackItemId,
      creator: createUserFeedbackCommentDto.creatorId,
      owner: createUserFeedbackCommentDto.creatorId
    })
    try {
      const role = await this.roleService.create({
        defaultRole: ROLE.OBSERVER,
        creator: createUserFeedbackCommentDto.creatorId,
        users: {},
        userGroups: {}
      })
      created.role = role
    } catch (error: any) {
      throw new InternalServerErrorException('Error creating Roles document')
    }

    return created.save()
  }

  /**
   * @description anyone can create, but this method is to add business logic in the future. All services that conform to IRoleConsumer implement this
   * @date 2023-03-30 22:22
   */
  public canCreateWithRolesCheck(userId: string) {
    return true
  }
  /**
   * END Section: CREATE
   */

  /**
   * START Section: READ
   */
  async findOneWithRolesCheck(
    userId: string,
    userFeedbackItemId: string
  ): Promise<UserFeedbackItemDocumentWithPopulatedProperties> {
    const entity = await this._getUserFeedbackItemAdmin(userFeedbackItemId)

    if (this.canFindWithRolesCheck(userId, entity)) {
      const data = await this.userFeedbackItemModel
        .findById<UserFeedbackItemDocumentWithPopulatedProperties>(
          userFeedbackItemId
        )
        .populate(this._standardPopulateFields)
        .exec()
      if (!data) {
        throw new NotFoundException()
      }
      return data
    } else {
      throw new NotFoundException()
    }
  }

  getUserFeedbackItemTypes(): string[] {
    return Object.values(USER_FEEDBACK_ITEM_TYPE)
  }

  findNewestPublicUserFeedbackItemsAdmin(): Promise<
    UserFeedbackItemDocument[]
  > {
    return this.userFeedbackItemModel
      .find({
        public: true
      })
      .sort({
        createdAt: -1
      })
      .populate(this._standardPopulateFields)
      .exec()
  }

  findTopPublicUserFeedbackItemsAdmin(): Promise<UserFeedbackItemDocument[]> {
    return this.userFeedbackItemModel
      .find({
        public: true
      })
      .sort({
        upvotedBy: -1
      })
      .populate(this._standardPopulateFields)
      .exec()
  }

  findAllPublicUserFeedbackItemsAdmin(): Promise<UserFeedbackItemDocument[]> {
    return this.userFeedbackItemModel
      .find({
        public: true
      })
      .sort({
        upvotedBy: -1
      })
      .populate(this._standardPopulateFields)
      .exec()
  }

  findCommentsForUserFeedbackAdmin(
    userFeedbackId: MongoObjectIdString
  ): Promise<UserFeedbackItemDocument[]> {
    // ensure it's a valid mongo id
    if (!ObjectId.isValid(userFeedbackId)) {
      throw new BadRequestException()
    }
    return this.userFeedbackCommentModel
      .find({
        adminHidden: false,
        userFeedbackItem: userFeedbackId
      })
      .sort({
        createdAt: -1
      })
      .populate(['creator'])
      .exec()
  }

  /**
   * @description This is where the business logic resides for what role level constitutes "read" access
   */
  public canFindWithRolesCheck(
    userId: string,
    entityWithPopulatedProperties: UserFeedbackItemDocument
  ) {
    const role: ROLE = this.roleService.getMaxRoleForUserForEntity(
      userId,
      entityWithPopulatedProperties
    )

    // Business logic: Anyone logged in can see user feedback items
    if (role >= ROLE.NO_ROLE) {
      return true
    } else {
      return false
    }
  }

  /**
   * @description Abstracted method so that consistent population is used for all find single space queries and also 404/not found is handled.
   * This is private so that either the -admin or -wiithRolesCheck suffix is chosen by the consuming method.
   * @date 2023-04-01 01:00:18
   */
  private async _getUserFeedbackItemAdmin(
    userFeedbackItemId: string
  ): Promise<UserFeedbackItemDocumentWithPopulatedProperties> {
    const userFeedbackItem = await this.userFeedbackItemModel
      .findById<UserFeedbackItemDocumentWithPopulatedProperties>(
        userFeedbackItemId
      )
      .populate(this._standardPopulateFields)
      .exec()
    if (!userFeedbackItem) {
      throw new NotFoundException()
    }
    return userFeedbackItem
  }

  /**
   * @description Abstracted method so that consistent population is used for all find single space queries and also 404/not found is handled.
   * This is private so that either the -admin or -wiithRolesCheck suffix is chosen by the consuming method.
   * @date 2023-04-01 01:00:18
   */
  private async _getUserFeedbackComment(
    commentId: string
  ): Promise<UserFeedbackItemDocument> {
    const comment = await this.userFeedbackCommentModel
      .findById(commentId)
      .populate(this._standardPopulateFields)
      .exec()
    if (!comment) {
      throw new NotFoundException()
    }
    return comment
  }

  /**
   * END Section: READ
   */

  /**
   * START Section: UPDATE
   */

  async updateOneWithRolesCheck(
    userId: string,
    userFeedbackItemId: string,
    updateUserFeedbackDto: UpdateUserFeedbackDto
  ): Promise<UserFeedbackItemDocument> {
    const userFeedbackItem = await this._getUserFeedbackItemAdmin(
      userFeedbackItemId
    )

    if (this.canUpdateWithRolesCheck(userId, userFeedbackItem)) {
      return this.userFeedbackItemModel
        .findByIdAndUpdate(userFeedbackItemId, updateUserFeedbackDto, {
          new: true
        })
        .populate(this._standardPopulateFields)
        .exec()
    } else {
      throw new ForbiddenException(
        'You do not have permission to update this UserFeedbackItem.'
      )
    }
  }
  /**
   * @description This is where the business logic resides for what role level constitutes "update" access
   */
  public canUpdateWithRolesCheck(
    userId: string,
    entityWithPopulatedProperties: UserFeedbackItemDocument
  ) {
    const role: ROLE = this.roleService.getMaxRoleForUserForEntity(
      userId,
      entityWithPopulatedProperties
    )
    if (role >= ROLE.OWNER) {
      return true
    } else {
      return false
    }
  }
  /**
   * END Section: UPDATE
   */

  /**
   * START Section: DELETE
   */
  async removeOneWithRolesCheck(userId: string, userFeedbackItemId: string) {
    const entity = await this._getUserFeedbackItemAdmin(userFeedbackItemId)

    if (this.canRemoveWithRolesCheck(userId, entity)) {
      debugger
      return await this.userFeedbackItemModel.findOneAndRemove({
        _id: userFeedbackItemId
      })
    } else {
      throw new ForbiddenException(
        'You do not have permission to delete this UserFeedbackItem.'
      )
    }
  }
  async removeCommentWithRolesCheck(
    userId: string,
    userFeedbackCommentId: string
  ) {
    const comment = await this._getUserFeedbackComment(userFeedbackCommentId)

    if (this.canRemoveWithRolesCheck(userId, comment)) {
      return await this.userFeedbackCommentModel.findOneAndRemove({
        _id: userFeedbackCommentId
      })
    } else {
      throw new ForbiddenException(
        'You do not have permission to delete this Comment.'
      )
    }
  }
  public canRemoveWithRolesCheck(
    userId: string,
    entityWithPopulatedProperties: UserFeedbackItemDocument
  ) {
    const role: ROLE = this.roleService.getMaxRoleForUserForEntity(
      userId,
      entityWithPopulatedProperties
    )
    if (role >= ROLE.OWNER) {
      return true
    } else {
      return false
    }
  }

  removeAdmin(id: string): Promise<UserFeedbackItemDocument> {
    return this.userFeedbackItemModel
      .findOneAndDelete({ _id: id }, { new: true })
      .exec()
  }
  /**
   * END Section: DELETE
   */

  async voteOnUserFeedbackItem(
    createVoteOnUserFeedbackItemDto: CreateVoteOnUserFeedbackItemDto & {
      votingUserId: string
    }
  ) {
    // if upvote, add to set of upvotes
    if (
      createVoteOnUserFeedbackItemDto.vote === USER_FEEDBACK_ITEM_VOTE.UPVOTE
    ) {
      return await this.userFeedbackItemModel
        .findOneAndUpdate(
          { _id: createVoteOnUserFeedbackItemDto.userFeedbackItemId },
          {
            $addToSet: {
              upvotedBy: createVoteOnUserFeedbackItemDto.votingUserId
            }
          },
          { new: true }
        )
        .populate(this._standardPopulateFields)
        .exec()
    }

    if (
      createVoteOnUserFeedbackItemDto.vote ===
      USER_FEEDBACK_ITEM_VOTE.REMOVE_UPVOTE
    ) {
      return await this.userFeedbackItemModel
        .findOneAndUpdate(
          { _id: createVoteOnUserFeedbackItemDto.userFeedbackItemId },
          {
            $pull: {
              upvotedBy: createVoteOnUserFeedbackItemDto.votingUserId
            }
          },
          { new: true }
        )
        .populate(this._standardPopulateFields)
        .exec()
    }
  }

  /**
   * START Section: Owner permissions for role modification
   */
  async setUserRoleForOneWithOwnerCheck(
    requestingUserId: string,
    targetUserId: string,
    userFeedbackItemId: string,
    role: ROLE
  ) {
    const userFeedbackItem = await this._getUserFeedbackItemAdmin(
      userFeedbackItemId
    )
    if (!userFeedbackItem.userIsOwner(requestingUserId)) {
      throw new ForbiddenException()
    }

    return await this.userFeedbackItemModel
      .findByIdAndUpdate(userFeedbackItemId, {
        $set: {
          [`role.users.${targetUserId}`]: role
        }
      })
      .exec()
  }
  async removeUserRoleForOneWithOwnerCheck(
    requestingUserId: string,
    targetUserId: string,
    userFeedbackItemId: string
  ) {
    const userFeedbackItem = await this._getUserFeedbackItemAdmin(
      userFeedbackItemId
    )
    if (!userFeedbackItem.userIsOwner(requestingUserId)) {
      throw new ForbiddenException()
    }

    return await this.userFeedbackItemModel
      .findByIdAndUpdate(userFeedbackItemId, {
        $unset: {
          [`role.users.${targetUserId}`]: 1
        }
      })
      .exec()
  }

  // TODO: add when groups is implemented
  // setUserGroupRoleForOne(
  //   requestingUserId: string,
  //   userGroupId: string,
  //   spaceId: string,
  //   role: ROLE
  // ) {}
  // removeUserGroupRoleForOne(
  //   requestingUserId: string,
  //   userGroupId,
  //   spaceId: string
  // ) {}
  /**
   * END Section: Owner permissions for role modification
   */
}
