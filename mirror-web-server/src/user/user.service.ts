import {
  HttpException,
  Injectable,
  Logger,
  BadRequestException,
  NotFoundException,
  ConflictException
} from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import { ObjectId, UpdateResult } from 'mongodb'
import mongoose, { Model, mongo } from 'mongoose'
import { v4 as uuidv4 } from 'uuid'
import { AssetPublicData } from '../asset/asset.schema'
import { CustomDataService } from '../custom-data/custom-data.service'
import { CreateCustomDataDto } from '../custom-data/dto/custom-data.dto'
import { PREMIUM_ACCESS } from '../option-sets/premium-tiers'
import { FileUploadService } from '../util/file-upload/file-upload.service'
import { getPublicPropertiesForMongooseQuery } from '../util/getPublicDataClassProperties'
import { UserEntityActionId, UserId } from '../util/mongo-object-id-helpers'
import { CreateUserAccessKeyDto } from './dto/create-user-access-key.dto'
import {
  AddRpmAvatarUrlDto,
  AddUserCartItemToUserCartDto,
  RemoveRpmAvatarUrlDto,
  UpdateUserAvatarDto,
  UpdateUserAvatarTypeDto,
  UpdateUserDeepLinkDto,
  UpdateUserProfileDto,
  UpdateUserTermsDto,
  UpdateUserTutorialDto,
  UpsertUserEntityActionDto
} from './dto/update-user.dto'
import { UploadProfileFileDto } from './dto/upload-profile-file.dto'
import {
  UserAccessKey,
  UserAccessKeyDocument
} from './models/user-access-key.schema'
import {
  ENTITY_TYPE,
  UserEntityAction,
  UserEntityActionDocument,
  USER_ENTITY_ACTION_TYPE
} from './models/user-entity-action.schema'
import { User, UserDocument, UserPublicData } from './user.schema'
import { UserSearch } from './user.search'
import { FirebaseAuthenticationService } from '../firebase/firebase-authentication.service'
import { UserCartItem } from './models/user-cart.schema'
import { AddUserSidebarTagDto } from './dto/add-user-sidebar-tag.dto'
import { IUserRecents } from './models/user-recents.schema'
import {
  Config,
  adjectives,
  animals,
  colors,
  uniqueNamesGenerator
} from 'unique-names-generator'
import { CreateUserWithEmailPasswordDto } from '../auth/dto/CreateUserWithEmailPasswordDto'

/**
 * @description The shape of the data retrieved when looking up a friend request. This is via `select` in mongoose
 * @date 2023-06-28 22:21
 */
export class Friend {
  @ApiProperty({ type: 'string' })
  displayName = ''
  @ApiProperty({ type: 'string' })
  coverImage? = ''
  @ApiProperty({ type: 'string' })
  profileImage? = ''
  @ApiProperty({ type: 'string' })
  id? = ''
  @ApiProperty({ type: 'string' })
  _id = ''
}

export class UserWithPublicProfile extends UserPublicData {
  @ApiProperty({
    type: AssetPublicData,
    isArray: true
  })
  publicAssets: AssetPublicData[]
  // TODO: add back for usergroups impl
  // @ApiProperty({
  //   type: UserGroupPublicData,
  //   isArray: true
  // })
  // publicGroups: UserGroupPublicData[]
}

@Injectable()
export class UserService {
  private readonly logger = new Logger(UserService.name)

  constructor(
    private readonly firebaseAuthService: FirebaseAuthenticationService,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(UserAccessKey.name)
    private userAccessKeyModel: Model<UserAccessKeyDocument>,
    @InjectModel(UserEntityAction.name)
    private userEntityActionModel: Model<UserEntityActionDocument>,
    private readonly userSearch: UserSearch,
    private readonly fileUploadService: FileUploadService,
    private readonly customDataService: CustomDataService
  ) {}
  searchForPublicUsers(searchQuery: string): Promise<UserPublicData[]> {
    const select = getPublicPropertiesForMongooseQuery(UserPublicData)

    if (!searchQuery) {
      return this.userModel
        .find({ deleted: { $exists: false } })
        .select(select)
        .limit(25)
        .exec()
    }

    const searchFilter = this.userSearch.getSearchFilter(searchQuery)

    //Users with deleted property should not appear in search results
    const filter = { ...searchFilter, deleted: { $exists: false } }

    return this.userModel.find(filter).select(select).exec()
  }

  findPublicUser(id: string): Promise<UserPublicData> {
    const select = getPublicPropertiesForMongooseQuery(UserPublicData)
    return this.userModel
      .findOne({ _id: id, deleted: { $exists: false } })
      .select(select)
      .populate('customData') // TODO this needs to be filtered with roles
      .exec()
  }

  /** @description Used for getting the user's additional profile data such as public assets and public groups */
  findPublicUserFullProfile(id: string): Promise<User> {
    const select = getPublicPropertiesForMongooseQuery(UserPublicData)
    return this.userModel
      .findOne({ _id: id, deleted: { $exists: false } })
      .select(select)
      .populate('customData') // TODO this needs to be filtered with roles
      .exec()
  }

  findPublicUserByEmail(email: string): Promise<User> {
    const select = getPublicPropertiesForMongooseQuery(UserPublicData)
    return this.userModel.findOne({ email: email }).select(select).exec()
  }

  async createUserWithEmailPassword(
    createUserWithEmailPasswordDto: CreateUserWithEmailPasswordDto
  ): Promise<UserDocument> {
    const { email, password, termsAgreedtoGeneralTOSandPP, displayName } =
      createUserWithEmailPasswordDto

    // disallow creation if they didn't agree to TOS/PP
    if (!termsAgreedtoGeneralTOSandPP) {
      throw new BadRequestException(
        'You must agree to the Terms of Service and Privacy Policy to create an account: https://www.themirror.space/terms, https://www.themirror.space/privacy'
      )
    }

    const _id = new mongo.ObjectId()
    this.logger.log('createUserWithEmailPassword with id', _id.toHexString())

    try {
      await this.firebaseAuthService.createUser({
        uid: _id.toHexString(),
        password,
        displayName,
        email,
        emailVerified: false
      })

      const user = new this.userModel({
        _id: _id,
        firebaseUID: _id.toHexString(),
        displayName,
        email,
        emailVerified: false,
        termsAgreedtoGeneralTOSandPP
      })

      const createdUser = await user.save()

      return createdUser.toJSON()
    } catch (error) {
      this.logger.error(error)
      await this.removeAuthUserWhenErrored(_id.toHexString())
      throw new HttpException(error?.message || error, 400)
    }
  }

  async ensureMirrorUserExists(token: string) {
    try {
      const decodedToken = await this.firebaseAuthService.verifyIdToken(token)
      const firebaseUID = decodedToken.uid

      const _id = new mongo.ObjectId()

      if (!decodedToken) {
        throw new NotFoundException('User not found')
      }

      const user = await this.userModel.findOne({ firebaseUID }).exec()

      if (!user) {
        const displayName = this._generateUniqueUsername()
        const userModel = new this.userModel({
          _id: _id,
          firebaseUID,
          displayName,
          emailVerified: false
        })

        const user = await userModel.save()
        this.logger.log('createAnonymousUser with id', _id.toHexString())
        return user
      }
      return user
    } catch (error) {
      this.logger.error(error)
      throw new HttpException(error?.message || error, 400)
    }
  }

  private _generateUniqueUsername() {
    const config: Config = {
      dictionaries: [adjectives, colors, animals],
      separator: ' ',
      style: 'capital'
    }

    return uniqueNamesGenerator(config)
  }

  /**
   * @deprecated since this uses populate and does have role checks. Use findOneAdmin
   * @date 2023-08-13 11:03
   */
  async findUser(userId: UserId): Promise<UserDocument> {
    return await this.userModel.findById(userId).populate('customData').exec()
  }

  async findOneAdmin(userId: UserId): Promise<UserDocument> {
    return await this.userModel.findById(userId).exec()
  }

  async getUserRecents(userId: UserId): Promise<IUserRecents> {
    const userRecents = await this.userModel
      .findOne({ _id: userId })
      .select('recents')
      .exec()

    if (!userRecents) {
      throw new NotFoundException('User not found')
    }

    return userRecents.recents as IUserRecents
  }

  /**
   * START Section: Friends and Friend Requests  ------------------------------------------------------
   */

  public async findUserFriendsAdmin(userId: UserId): Promise<Friend[]> {
    const [aggregationResult] = await this.userModel
      .aggregate([
        { $match: { _id: new ObjectId(userId) } },
        {
          $lookup: {
            from: 'users',
            localField: 'friends',
            foreignField: '_id',
            as: 'friends'
          }
        },
        {
          $project: {
            friends: {
              $filter: {
                input: '$friends',
                as: 'friend',
                cond: { $ne: ['$$friend.deleted', true] }
              }
            }
          }
        },
        {
          $project: {
            'friends._id': 1,
            'friends.displayName': 1,
            'friends.profileImage': 1,
            'friends.coverImage': 1
          }
        }
      ])
      .exec()

    return aggregationResult
  }

  findFriendRequestsSentToMeAdmin(userId: UserId): Promise<Friend[]> {
    return this.userModel
      .find({
        sentFriendRequestsToUsers: { $in: [userId] },
        deleted: { $exists: false }
      })
      .select({ _id: 1, displayName: 1, profileImage: 1, coverImage: 1 })
      .exec()
  }

  async acceptFriendRequestAdmin(
    userId: UserId,
    userIdOfFriendRequestToAccept: UserId
  ): Promise<Friend[]> {
    // first ensure that the friend request actually exists
    const check = await this._checkIfFriendRequestExistsAdmin(
      userIdOfFriendRequestToAccept,
      userId // note that the param order is flipped for the _checkIfFriendRequestExists method because we want to check that the friend request was sent to the current userId (most likely use case for this method)
    )

    if (check) {
      // add to friends list for both users
      await this.userModel
        .findByIdAndUpdate(
          userId,
          { $addToSet: { friends: userIdOfFriendRequestToAccept } },
          { new: true }
        )
        .exec()
      await this.userModel
        .findByIdAndUpdate(
          userIdOfFriendRequestToAccept,
          { $addToSet: { friends: userId } },
          { new: true }
        )
        .exec()
      // remove the sentFriendRequestsToUsers from the user who sent the request
      await this.userModel
        .findByIdAndUpdate(
          userIdOfFriendRequestToAccept,
          { $pull: { sentFriendRequestsToUsers: userId } },
          { new: true }
        )
        .exec()

      return await this.findUserFriendsAdmin(userId)
    } else {
      throw new NotFoundException(
        'Friend request not found or you are already friends with this user'
      )
    }
  }

  async rejectFriendRequestAdmin(
    userId: UserId,
    userIdOfFriendRequestToReject: UserId
  ): Promise<Friend[]> {
    // first ensure that the friend request actually exists
    const check = await this._checkIfFriendRequestExistsAdmin(
      userIdOfFriendRequestToReject,
      userId // note that the param order is flipped for the _checkIfFriendRequestExists method because we want to check that the friend request was sent to the current userId (most likely use case for this method)
    )

    if (check) {
      // remove the sentFriendRequestsToUsers from the user who sent the request
      await this.userModel
        .findByIdAndUpdate(
          userIdOfFriendRequestToReject,
          { $pull: { sentFriendRequestsToUsers: userId } },
          { new: true }
        )
        .exec()

      // Note that the return here is different from acceptFriendRequestAdmin
      // instead, this returns the list of friend requests
      return await this.findFriendRequestsSentToMeAdmin(userId)
    } else {
      throw new NotFoundException('Friend request not found')
    }
  }

  async findSentFriendRequestsAdmin(userId: UserId): Promise<Friend[]> {
    const [aggregationResult] = await this.userModel
      .aggregate([
        { $match: { _id: new ObjectId(userId) } },
        {
          $lookup: {
            from: 'users',
            localField: 'sentFriendRequestsToUsers',
            foreignField: '_id',
            as: 'sentFriendRequestsToUsers'
          }
        },
        {
          $project: {
            sentFriendRequestsToUsers: {
              $filter: {
                input: '$sentFriendRequestsToUsers',
                as: 'request',
                cond: { $ne: ['$$request.deleted', true] }
              }
            }
          }
        },
        {
          $project: {
            'sentFriendRequestsToUsers._id': 1,
            'sentFriendRequestsToUsers.displayName': 1,
            'sentFriendRequestsToUsers.profileImage': 1,
            'sentFriendRequestsToUsers.coverImage': 1
          }
        }
      ])
      .exec()

    return aggregationResult.sentFriendRequestsToUsers
  }

  sendFriendRequestAdmin(
    requestingUserId: UserId,
    toUserId: UserId
  ): Promise<UserDocument> {
    return this.userModel
      .findByIdAndUpdate(
        requestingUserId,
        { $addToSet: { sentFriendRequestsToUsers: toUserId } },
        { new: true }
      )
      .select({ sentFriendRequestsToUsers: 1 })
      .exec()
  }

  private async _checkIfFriendRequestExistsAdmin(
    fromUserId: UserId,
    toUserId: UserId
  ): Promise<boolean> {
    const test = await this.userModel
      .find({
        _id: new ObjectId(fromUserId),
        sentFriendRequestsToUsers: { $in: [toUserId] }
      })
      .select({ _id: 1, displayName: 1, profileImage: 1, coverImage: 1 })
      .exec()
    if (test) {
      return true
    }
    return false
  }

  /**
   * @description Removes a friend and returns the updated friends list
   * @date 2023-06-30 00:19
   */
  async removeFriendAdmin(
    userId: UserId,
    friendUserIdToRemove: UserId
  ): Promise<Friend[]> {
    // remove from friends list for both users
    await this.userModel
      .findByIdAndUpdate(
        userId,
        { $pull: { friends: friendUserIdToRemove } },
        { new: true }
      )
      .exec()
    await this.userModel
      .findByIdAndUpdate(
        friendUserIdToRemove,
        { $pull: { friends: userId } },
        { new: true }
      )
      .exec()

    return await this.findUserFriendsAdmin(userId)
  }
  /**
   * END Section: Friends and Friend Requests  ------------------------------------------------------
   */

  /**
   * START Section: Cart  ------------------------------------------------------
   */

  async getUserCartAdmin(userId: UserId) {
    return await this.userModel.findById(userId).select({ cartItems: 1 }).exec()
  }

  /**
   * @description add a UserCartItem to a User's cart
   * Admin call because the user should be determined by the JWT. Someone else should never be able to add to someone else's cart
   * @date 2023-07-09 16:19
   */
  async addUserCartItemToUserCartAdmin(
    userId: UserId,
    dto: AddUserCartItemToUserCartDto
  ) {
    const cartItem = new UserCartItem()
    cartItem.entityType = dto.entityType
    cartItem.forEntity = new mongoose.Types.ObjectId(dto.forEntity)
    return await this.userModel
      .findByIdAndUpdate(
        userId,
        {
          $push: { cartItems: cartItem }
        },
        { new: true, select: { cartItems: 1 } }
      )
      .exec()
  }

  async removeAllUserCartItemsFromUserCartAdmin(userId: UserId) {
    return await this.userModel
      .findByIdAndUpdate(
        userId,
        {
          $set: {
            cartItems: []
          }
        },
        { new: true, select: { cartItems: 1 } }
      )
      .exec()
  }

  async removeUserCartItemFromUserCartAdmin(
    userId: UserId,
    cartItemId: string
  ) {
    return await this.userModel
      .findByIdAndUpdate(
        userId,
        {
          $pull: {
            cartItems: {
              _id: new mongoose.Types.ObjectId(cartItemId)
            }
          }
        },
        { new: true, select: { cartItems: 1 } }
      )
      .exec()
  }

  /**
   * END Section: Cart  ------------------------------------------------------
   */

  // TODO need to lock down permissions for custom data. Also, users shouldn't be able to see each other unless they used the public methods like findPublicUserFullProfile()
  /**
   *
   * @deprecated This needs role checks and we want to avoid extra lookups. I'm not sure if customData is the best way to go. 2023-09-11 16:28:43
   */
  async findUserIncludingCustomData(id: string) {
    return await this.userModel.findById(id).populate('customData').exec()
  }

  findUserByDiscordId(discordUserId: string): Promise<User> {
    return this.userModel.findOne({ discordUserId: discordUserId }).exec()
  }

  findUserByEmail(email: string): Promise<User> {
    return this.userModel.findOne({ email: email }).exec()
  }

  async updateUserProfileAdmin(
    id: string,
    dto: UpdateUserProfileDto
  ): Promise<UserDocument> {
    let originalUser: UserDocument
    const firebaseUpdate = this.getFirebaseFieldsForUpdate(dto)
    const firebaseFields = Object.keys(firebaseUpdate)

    try {
      /** Update and save reference of old UserModel to handle errors */
      originalUser = await this.userModel.findByIdAndUpdate(id, dto).exec()

      /** Update firebase specific fields if present */
      if (firebaseFields.length) {
        await this.firebaseAuthService.updateUser(id, firebaseUpdate)
      }

      /** On success - return latest UserModel  */
      return this.findUser(id)
    } catch (error) {
      /** If Update succeeds but firebase fails, reset failed fields on mongodb User */
      if (firebaseFields.length && originalUser?._id) {
        this.undoUserUpdateOnError(id, firebaseFields, originalUser)
      }
      this.logger.error(error)
      throw new HttpException(error.message ?? error, 400)
    }
  }

  updateUserProfile(userId: UserId, dto: UpdateUserProfileDto) {
    return this.userModel.findByIdAndUpdate(userId, dto, { new: true }).exec()
  }

  updateUserTutorial(userId: UserId, dto: UpdateUserTutorialDto) {
    return this.userModel
      .findByIdAndUpdate(
        userId,
        {
          // the below is so nested properties don't get overwritten
          ...Object.fromEntries(
            Object.entries(dto).map(([key, value]) => [
              `tutorial.${key}`,
              value
            ])
          )
        },
        { new: true }
      )
      .exec()
  }

  updateDeepLink(userId: UserId, dto: UpdateUserDeepLinkDto) {
    return this.userModel
      .findByIdAndUpdate(
        userId,
        {
          deepLinkKey: dto.deepLinkKey,
          deepLinkValue: dto.deepLinkValue,
          deepLinkLastUpdatedAt: new Date()
        },
        { new: true }
      )
      .exec()
  }

  updateUserAvatar(id: string, dto: UpdateUserAvatarDto) {
    return this.userModel.findByIdAndUpdate(id, dto, { new: true }).exec()
  }

  updateUserTerms(id: string, dto: UpdateUserTermsDto) {
    return this.userModel.findByIdAndUpdate(id, dto, { new: true }).exec()
  }

  updateUserAvatarType(id: string, dto: UpdateUserAvatarTypeDto) {
    return this.userModel.findByIdAndUpdate(id, dto, { new: true }).exec()
  }

  updateUserRecentSpaces(id: string, spaces: string[]) {
    return this.userModel.findByIdAndUpdate(id, { 'recents.spaces': spaces })
  }

  updateUserRecentInstancedAssets(id: string, assets: string[]) {
    return this.userModel.findByIdAndUpdate(id, {
      'recents.assets.instanced': assets
    })
  }

  updateUserRecentScripts(id: string, scripts: string[]) {
    return this.userModel.findByIdAndUpdate(id, {
      'recents.scripts': scripts
    })
  }

  getUserFiveStarRatedSpaces(userId) {
    return this.userEntityActionModel
      .find({
        creator: new ObjectId(userId),
        entityType: ENTITY_TYPE.SPACE,
        actionType: USER_ENTITY_ACTION_TYPE.RATING,
        rating: 5
      })
      .select('forEntity')
      .exec()
  }

  addUserPremiumAccess(id: string, accessLevelToAdd: PREMIUM_ACCESS) {
    return this.userModel
      .findByIdAndUpdate(
        id,
        {
          $addToSet: {
            premiumAccess: accessLevelToAdd
          }
        },
        { new: true }
      )
      .exec()
  }

  removeUserPremiumAccess(id: string, accessLevelToRemove: PREMIUM_ACCESS) {
    return this.userModel
      .findByIdAndUpdate(
        id,
        {
          $pull: {
            premiumAccess: accessLevelToRemove
          }
        },
        { new: true }
      )
      .exec()
  }

  async getPublicEntityActionStats(entityId: string) {
    const pipeline = [
      {
        $match: { forEntity: new ObjectId(entityId) }
      },
      {
        $group: {
          _id: '$actionType',
          count: { $sum: 1 },
          ratingSum: { $sum: '$rating' },
          ratingAvg: { $avg: '$rating' }
        }
      },
      {
        $group: {
          _id: null,
          COUNT_LIKE: {
            $sum: { $cond: [{ $eq: ['$_id', 'LIKE'] }, '$count', 0] }
          },
          COUNT_FOLLOW: {
            $sum: { $cond: [{ $eq: ['$_id', 'FOLLOW'] }, '$count', 0] }
          },
          COUNT_SAVES: {
            $sum: { $cond: [{ $eq: ['$_id', 'SAVE'] }, '$count', 0] }
          },
          COUNT_RATING: {
            $sum: { $cond: [{ $eq: ['$_id', 'RATING'] }, '$count', 0] }
          },
          AVG_RATING: {
            $avg: { $cond: [{ $eq: ['$_id', 'RATING'] }, '$ratingAvg', null] }
          }
        }
      },
      {
        $project: {
          _id: 0,
          COUNT_LIKE: 1,
          COUNT_FOLLOW: 1,
          COUNT_SAVES: 1,
          COUNT_RATING: 1,
          AVG_RATING: 1
        }
      }
    ]
    const stats = await this.userEntityActionModel.aggregate(pipeline).exec()

    return stats[0]
  }

  findEntityActionsByUserForEntity(userId: UserId, entityId: string) {
    // validate mongo Ids
    if (!mongo.ObjectId.isValid(userId)) {
      throw new BadRequestException('User ID is not a valid Mongo ObjectId')
    }
    if (!mongo.ObjectId.isValid(entityId)) {
      throw new BadRequestException('Entity ID is not a valid Mongo ObjectId')
    }
    return this.userEntityActionModel
      .find({
        creator: new ObjectId(userId),
        forEntity: new ObjectId(entityId)
      })
      .exec()
  }

  upsertUserEntityAction(userId: string, dto: UpsertUserEntityActionDto) {
    const findData = {
      creator: new ObjectId(userId),
      forEntity: new ObjectId(dto.forEntity),
      entityType: dto.entityType,
      actionType: dto.actionType
    }
    const updateData: any = {}
    if (dto.rating !== undefined) {
      updateData.rating = dto.rating
    }
    return this.userEntityActionModel
      .findOneAndUpdate(findData, updateData, { new: true, upsert: true })
      .exec()
  }

  removeUserEntityAction(
    userId: UserId,
    userEntityActionId: UserEntityActionId
  ) {
    return this.userEntityActionModel
      .findOneAndRemove({ creator: userId, _id: userEntityActionId })
      .exec()
  }

  public uploadProfileImage({ file, userId }: UploadProfileFileDto) {
    const fileId = new ObjectId()
    const path = `${userId}/profile-images/${fileId.toString()}`
    return this.fileUploadService.uploadFilePublic({ file, path })
  }

  /**
   * @description Adds an RPM url to readyPlayerMeAvatarUrls. $addToSet forces uniqueness so there aren't duplicates
   * @date 2022-06-18 12:04
   */
  addRpmAvatarUrl(id: string, dto: AddRpmAvatarUrlDto) {
    return this.userModel
      .findByIdAndUpdate(
        id,
        {
          $addToSet: {
            readyPlayerMeAvatarUrls: dto.rpmAvatarUrl
          }
        },
        { new: true }
      )
      .exec()
  }

  /**
   * @description Removes an RPM url from readyPlayerMeAvatarUrls.
   * @date 2022-06-18 12:07
   */
  removeRpmAvatarUrl(id: string, dto: RemoveRpmAvatarUrlDto) {
    return this.userModel
      .findByIdAndUpdate(
        id,
        {
          $pullAll: {
            readyPlayerMeAvatarUrls: [dto.rpmAvatarUrl]
          }
        },
        { new: true }
      )
      .exec()
  }

  createUserAccessKey(createSignUpKeyDto: CreateUserAccessKeyDto) {
    const keyName = uuidv4()
    const key = new this.userAccessKeyModel({
      ...createSignUpKeyDto,
      key: keyName
    })
    return key.save()
  }

  async checkUserAccessKeyExistence(name: string) {
    const check = await this.userAccessKeyModel.findOne({
      key: name,
      usedBy: {
        $exists: false // need to ensure it's not in use
      }
    })
    if (check) {
      return check
    } else {
      return false
    }
  }

  async setUserAccessKeyAsUsed(
    keyId: string,
    userId: string
  ): Promise<UpdateResult> {
    // @ts-ignore. The error was: Type '"ObjectID"' is not assignable to type '"ObjectId"' with importing from Mongo vs Mongoose. Not worth debugging 2023-03-28 01:41:44
    return await this.userAccessKeyModel
      .updateOne({ _id: keyId }, { usedBy: userId })
      .exec()
  }

  /**
   * START Section: Custom Data
   */
  async setCustomDataOnUser(
    userId: string,
    customDataDto: CreateCustomDataDto
  ) {
    const customDataDoc = await this.customDataService.createCustomData(
      userId,
      customDataDto
    )
    const doc = await this.userModel
      .findByIdAndUpdate(
        userId,
        {
          $set: {
            customData: customDataDoc.id
          }
        },
        { new: true }
      )
      .exec()
    return doc
  }

  /**
   * END Section: Custom Data
   */

  /** Extract Firebase specific properties to update */
  protected getFirebaseFieldsForUpdate(dto: UpdateUserProfileDto): any {
    const { email, displayName } = dto
    return {
      ...(email && { email }),
      ...(displayName && { displayName })
    }
  }

  protected undoUserUpdateOnError(
    id: string,
    firebaseFields: string[],
    originalUser: UserDocument
  ) {
    this.logger.warn(
      `Error Encountered. Attempting to revert User update for User ID: ${id}`
    )

    const revertFields = firebaseFields.reduce((result, field) => {
      if (originalUser[field]) {
        result[field] = originalUser[field]
      }
      return result
    }, {} as UpdateUserProfileDto)

    this.updateUserProfile(id, revertFields)
      .then(() =>
        this.logger.warn(
          `Attempted update of User ID: ${id} in mongo db successful. Update reverted.`
        )
      )
      .catch(() =>
        this.logger.warn(
          `Attempted update of User ID: ${id} in mongo db unsuccessful. Update not reverted.`
        )
      )
  }

  protected async removeAuthUserWhenErrored(_id: string) {
    this.logger.warn(
      `Error Encountered. Attempting to remove user from firebase db. ID: ${_id}`
    )
    await this.firebaseAuthService
      .deleteUser(_id)
      .then((result) => {
        this.logger.warn(
          `Attempted removal of user ${_id} from firebase db successful. ID: ${_id} deleted.`
        )
      })
      .catch((error) => {
        this.logger.error(
          `Attempted removal of user ${_id} from firebase db unsuccessful. ID: ${_id} not deleted!`
        )
      })
  }

  public async getUserSidebarTags(userId: UserId) {
    const user = await this.userModel
      .findOne({ _id: userId })
      .select('sidebarTags')
      .exec()

    if (!user) {
      throw new NotFoundException('User not found')
    }

    return user?.sidebarTags || []
  }

  public async addUserSidebarTag(
    userId: UserId,
    addUserSidebarTagDto: AddUserSidebarTagDto
  ) {
    const { sidebarTag } = addUserSidebarTagDto
    const sidebarTags = await this.getUserSidebarTags(userId)

    if (sidebarTags.length === 3) {
      throw new BadRequestException('User already has 3 sidebar tags')
    }

    if (sidebarTags.includes(sidebarTag)) {
      throw new ConflictException('User already has this sidebar tag')
    }

    sidebarTags.push(sidebarTag)
    await this.updateUserSidebarTags(userId, sidebarTags)

    return sidebarTag
  }

  public async deleteUserSidebarTag(userId: UserId, sidebarTag: string) {
    await this.userModel.updateOne(
      { _id: userId },
      { $pull: { sidebarTags: sidebarTag } }
    )

    return { userId, sidebarTag }
  }

  public async updateUserSidebarTags(userId: string, sidebarTags: string[]) {
    await this.userModel.updateOne({ _id: userId }, { $set: { sidebarTags } })
    return sidebarTags
  }

  public async updateUserLastActiveTimestamp(userId: string) {
    await this.userModel.updateOne(
      { _id: userId },
      { $set: { lastActiveTimestamp: new Date() } }
    )
  }

  /**
   * @description This method removes all personally identifiable information from the user and marks the user as deleted.
   * When a user requests to delete an account, it is marked with the deleted: true property.
   * A user with the deleted: true property will be filtered out of all search results.
   * After we check for any compliance/investigative issues (e.g. in case of a report from another user), we remove the account
   * @date 2023-12-22 17:31
   */
  public async markUserAsDeleted(userId: string) {
    const updateResult = await this.userModel.updateOne({ _id: userId }, [
      { $set: { deleted: true } },
      { $unset: ['email', 'firebaseUID', 'discordUserId'] }
    ])

    if (!updateResult.modifiedCount) {
      throw new NotFoundException('User not found')
    }
  }
}
