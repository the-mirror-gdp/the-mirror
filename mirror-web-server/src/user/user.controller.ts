import {
  Body,
  Controller,
  Delete,
  Get,
  NotFoundException,
  Param,
  Patch,
  Post,
  Query,
  UnauthorizedException,
  UploadedFile,
  UseInterceptors,
  UsePipes,
  ValidationPipe
} from '@nestjs/common'
import {
  ApiBody,
  ApiConsumes,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiParam
} from '@nestjs/swagger'
import { FirebaseTokenAuthGuard } from '../auth/auth.guard'
import { User, UserPublicData } from './user.schema'
import { Friend, UserService } from './user.service'
import { UserToken } from '../auth/get-user.decorator'
import { FileUploadPublicApiResponse } from '../util/file-upload/file-upload'
import { FileInterceptor } from '@nestjs/platform-express'
import {
  AddRpmAvatarUrlDto,
  UpdateUserAvatarDto,
  RemoveRpmAvatarUrlDto,
  UpdateUserAvatarTypeDto,
  UpdateUserDeepLinkDto,
  UpdateUserProfileDto,
  UpdateUserTermsDto,
  UpdateUserTutorialDto,
  UpsertUserEntityActionDto,
  AddUserCartItemToUserCartDto
} from './dto/update-user.dto'
import { PublicFirebaseAuthNotRequired } from '../auth/public.decorator'
import { CreateUserAccessKeyDto } from './dto/create-user-access-key.dto'
import { SubmitUserAccessKeyDto } from './dto/submit-user-access-key.dto'
import { UserEntityActionId, UserId } from '../util/mongo-object-id-helpers'
import { PREMIUM_ACCESS } from '../option-sets/premium-tiers'
import { AddUserSidebarTagDto } from './dto/add-user-sidebar-tag.dto'
import { UpdateUserSidebarTagsDto } from './dto/update-user-sidebar-tags.dto'
import { UserRecents } from './models/user-recents.schema'

@UsePipes(new ValidationPipe({ whitelist: true }))
@Controller('user')
@FirebaseTokenAuthGuard()
export class UserController {
  constructor(private readonly userService: UserService) {}

  /*****************************
   PUBLICLY ACCESSIBLE ENDPOINTS
   ****************************/

  /**
   * @description Retrieves a Users public data
   * id prefix added to prevent wildcard route clashes with file method order
   */
  @PublicFirebaseAuthNotRequired()
  @Get('id/:id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  public findOne(@Param('id') id: string): Promise<UserPublicData> {
    return this.userService.findPublicUser(id)
  }

  /** @description Retrieves a Users public profile data including populated
   *  fields like public assets and public groups */
  @PublicFirebaseAuthNotRequired()
  @Get(':id/public-profile')
  @ApiParam({ name: 'id', type: 'string', required: true })
  @ApiOkResponse({ type: UserPublicData })
  public findOneWithPublicProfile(@Param('id') id: string): Promise<User> {
    return this.userService.findPublicUserFullProfile(id)
  }

  /** @description Retrieves a collection of Users public data */
  @PublicFirebaseAuthNotRequired()
  @Get('search')
  @ApiOkResponse({ type: [UserPublicData] })
  public search(@Query('query') query: string): Promise<UserPublicData[]> {
    return this.userService.searchForPublicUsers(query)
  }

  /***********************
   AUTH REQUIRED ENDPOINTS
   **********************/

  /** @description /me gets the current user by checking their uid on the JWT */
  @Get('me')
  @ApiOkResponse({ type: User })
  public async getCurrentUser(@UserToken('uid') id: string) {
    const user = await this.userService.findUser(id)
    if (!user) {
      throw new NotFoundException()
    }
    return user
  }

  @Get('recents/me')
  @ApiOkResponse({ type: UserRecents })
  public async getUserRecents(@UserToken('user_id') userId: UserId) {
    return await this.userService.getUserRecents(userId)
  }

  /**
   * TODO - Would be nice to have 1 file upload endpoint that can handle all entity types and paths
   *  move logic to service
   */
  @Post('/upload/public')
  @FirebaseTokenAuthGuard() // 2023-03-08 00:28:04 can this line be removed since the controller has it?
  @ApiConsumes('multipart/form-data')
  @ApiBody({ schema: { type: 'file' } })
  @ApiCreatedResponse({ type: FileUploadPublicApiResponse })
  @UseInterceptors(FileInterceptor('file'))
  public async uploadPublic(
    @UserToken('user_id') userId: string,
    @UploadedFile() file: Express.Multer.File
  ) {
    return await this.userService.uploadProfileImage({ file, userId })
  }

  @Patch('profile')
  @ApiOkResponse({ type: User })
  public updateProfile(
    @UserToken('uid') id: string,
    @Body() dto: UpdateUserProfileDto
  ) {
    return this.userService.updateUserProfileAdmin(id, dto)
  }

  @Patch('tutorial')
  @ApiOkResponse({ type: User })
  public updateUserTutorial(
    @UserToken('uid') id: UserId,
    @Body() dto: UpdateUserTutorialDto
  ) {
    return this.userService.updateUserTutorial(id, dto)
  }

  @Patch('deep-link')
  public updateDeepLink(
    @UserToken('uid') id: string,
    @Body() dto: UpdateUserDeepLinkDto
  ) {
    return this.userService.updateDeepLink(id, dto)
  }

  @Patch('avatar')
  public updateAvatar(
    @UserToken('uid') id: string,
    @Body() dto: UpdateUserAvatarDto
  ) {
    return this.userService.updateUserAvatar(id, dto)
  }

  @Patch('terms')
  public updateTermsAgreedTo(
    @UserToken('uid') id: string,
    @Body() dto: UpdateUserTermsDto
  ) {
    return this.userService.updateUserTerms(id, dto)
  }

  @Patch('avatar-type')
  public updateAvatarType(
    @UserToken('uid') id: string,
    @Body() dto: UpdateUserAvatarTypeDto
  ) {
    return this.userService.updateUserAvatarType(id, dto)
  }

  /**
   * @param {string} entityId - The id of the entity that the action is for such as Space, Asset, User, etc., NOT the UserEntityAction ID
   * @date 2023-06-14 16:49
   */
  @Get('entity-action/for-entity/:entityId')
  @ApiParam({ name: 'entityId', type: 'string', required: true })
  public getUserEntityAction(
    @UserToken('uid') id: UserId,
    @Param('entityId') entityId: string
  ) {
    return this.userService.getPublicEntityActionStats(entityId)
  }

  /**
   * @param {string} entityId - The id of the entity that the action is for such as Space, Asset, User, etc., NOT the UserEntityAction ID
   * @date 2023-06-14 16:49
   */
  @Get('entity-action/me/for-entity/:entityId')
  @ApiParam({ name: 'entityId', type: 'string', required: true })
  public getUserEntityActionsByMeForEntity(
    @UserToken('uid') userId: UserId,
    @Param('entityId') entityId: string
  ) {
    return this.userService.findEntityActionsByUserForEntity(userId, entityId)
  }

  @Patch('entity-action')
  public upsertUserEntityAction(
    @UserToken('uid') id: UserId,
    @Body() dto: UpsertUserEntityActionDto
  ) {
    return this.userService.upsertUserEntityAction(id, dto)
  }

  @Delete('entity-action/:userEntityActionId')
  @ApiParam({ name: 'userEntityActionId', type: 'string', required: true })
  public deleteUserEntityAction(
    @UserToken('uid') id: UserId,
    @Param('userEntityActionId') userEntityActionId: UserEntityActionId
  ) {
    return this.userService.removeUserEntityAction(id, userEntityActionId)
  }

  /**
   * START Section: Friends and friend requests  ------------------------------------------------------
   */
  @Get('friends/me')
  @ApiOkResponse({
    type: [Friend],
    description: 'Gets friend requests for the current user from the token'
  })
  public getMyFriends(@UserToken('uid') userId: UserId): Promise<Friend[]> {
    return this.userService.findUserFriendsAdmin(userId)
  }

  @Get('friend-requests/me')
  @ApiOkResponse({ type: [Friend] })
  public getMyFriendRequests(
    @UserToken('uid') userId: UserId
  ): Promise<Friend[]> {
    return this.userService.findFriendRequestsSentToMeAdmin(userId)
  }

  @Post('friend-requests/accept/:fromUserId')
  @ApiParam({ name: 'fromUserId', type: 'string', required: true })
  @ApiOkResponse({
    type: [Friend],
    description:
      'Accepts a friend request. This uses the current user from the token as the accepting user'
  })
  public acceptFriendRequest(
    @UserToken('uid') userId: UserId,
    @Param('fromUserId') fromUserId: UserId
  ): Promise<Friend[]> {
    return this.userService.acceptFriendRequestAdmin(userId, fromUserId)
  }

  @Post('friend-requests/reject/:fromUserId')
  @ApiParam({ name: 'fromUserId', type: 'string', required: true })
  @ApiOkResponse({
    type: [Friend],
    description:
      'Rejects a friend request. This uses the current user from the token as the user that rejects the request'
  })
  public rejectFriendRequest(
    @UserToken('uid') userId: UserId,
    @Param('fromUserId') fromUserId: UserId
  ): Promise<Friend[]> {
    return this.userService.rejectFriendRequestAdmin(userId, fromUserId)
  }

  @Get('friend-requests/sent')
  @ApiOkResponse({
    type: [Friend],
    description: 'Gets SENT friend requests by the current user from the token'
  })
  public getSentFriendRequests(
    @UserToken('uid') userId: UserId
  ): Promise<Friend[]> {
    return this.userService.findSentFriendRequestsAdmin(userId)
  }

  @Post('friend-requests/:toUserId')
  @ApiParam({ name: 'toUserId', type: 'string', required: true })
  @ApiCreatedResponse({
    type: User,
    description:
      'Sends a friend request. This uses the current user from the token'
  })
  public sendFriendRequest(
    @UserToken('uid') userId: UserId,
    @Param('toUserId') toUserId: UserId
  ): Promise<User> {
    return this.userService.sendFriendRequestAdmin(userId, toUserId)
  }

  @Delete('friends/:friendUserIdToRemove')
  @ApiParam({ name: 'friendUserIdToRemove', type: 'string', required: true })
  @ApiOkResponse({
    type: User,
    description: 'Removes a friend and returns the updated friends list'
  })
  public removeFriend(
    @UserToken('uid') userId: UserId,
    @Param('friendUserIdToRemove') friendUserIdToRemove: UserId
  ): Promise<Friend[]> {
    return this.userService.removeFriendAdmin(userId, friendUserIdToRemove)
  }
  /**
   * END Section: Friends and friend requests  ------------------------------------------------------
   */

  /**
   * START Section: Cart  ------------------------------------------------------
   */
  @Get('cart')
  @ApiOkResponse({ type: User })
  public getUserCart(@UserToken('uid') userId: string) {
    return this.userService.getUserCartAdmin(userId)
  }

  @Post('cart')
  @ApiCreatedResponse({ type: User })
  public addUserCartItemToUserCart(
    @UserToken('uid') userId: string,
    @Body() dto: AddUserCartItemToUserCartDto
  ) {
    return this.userService.addUserCartItemToUserCartAdmin(userId, dto)
  }

  @Delete('cart/all')
  @ApiOkResponse({ type: User })
  public removeAllUserItemsFromCart(@UserToken('uid') userId: string) {
    return this.userService.removeAllUserCartItemsFromUserCartAdmin(userId)
  }

  @Delete('cart/:cartItemId')
  @ApiParam({ name: 'cartItemId', type: 'string', required: true })
  @ApiOkResponse({ type: User })
  public removeUserCartItemFromUserCart(
    @UserToken('uid') userId: string,
    @Param('cartItemId') cartItemId: string
  ) {
    return this.userService.removeUserCartItemFromUserCartAdmin(
      userId,
      cartItemId
    )
  }

  /**
   * END Section: Cart  ------------------------------------------------------
   */

  /** @description Add a url to the array of the user's RPM avatars, readyPlayerMeAvatarUrls in Mongo */
  @Post('rpm-avatar-url')
  public addRpmAvatarUrl(
    @UserToken('uid') id: string,
    @Body() dto: AddRpmAvatarUrlDto
  ) {
    return this.userService.addRpmAvatarUrl(id, dto)
  }

  @Post('access-key')
  createSignUpKey(@Body() createSignUpKeyDto: CreateUserAccessKeyDto) {
    if (createSignUpKeyDto.token !== process.env.SIGN_UP_KEY_TOKEN) {
      throw new UnauthorizedException()
    }
    return this.userService.createUserAccessKey(createSignUpKeyDto)
  }

  @Post('submit-user-access-key')
  async submitUserAccessKey(
    @UserToken('uid') userId: string,
    @Body() submitUserAccessKeyDto: SubmitUserAccessKeyDto
  ) {
    const key = await this.userService.checkUserAccessKeyExistence(
      submitUserAccessKeyDto.key
    )
    if (key) {
      await this.userService.addUserPremiumAccess(
        userId,
        key.premiumAccess as PREMIUM_ACCESS
      )
      await this.userService.setUserAccessKeyAsUsed(key.id, userId)
    } else {
      throw new UnauthorizedException(
        "We're sorry, but that key doesn't exist or it's been used"
      )
    }
  }

  /** @description Removes an RPM url from readyPlayerMeAvatarUrls in Mongo */
  @Delete('rpm-avatar-url')
  public removeRpmAvatarUrl(
    @UserToken('uid') id: string,
    @Body() dto: RemoveRpmAvatarUrlDto
  ) {
    return this.userService.removeRpmAvatarUrl(id, dto)
  }

  @Get('sidebar-tags')
  @FirebaseTokenAuthGuard()
  public async getUserSidebarTags(@UserToken('user_id') userId: UserId) {
    return await this.userService.getUserSidebarTags(userId)
  }

  @Post('sidebar-tags')
  @FirebaseTokenAuthGuard()
  public async addUserSidebarTag(
    @UserToken('user_id') userId: UserId,
    @Body() addUserSidebarTagDto: AddUserSidebarTagDto
  ) {
    return await this.userService.addUserSidebarTag(
      userId,
      addUserSidebarTagDto
    )
  }

  @Patch('sidebar-tags')
  @FirebaseTokenAuthGuard()
  public async updateUserSidebarTags(
    @UserToken('user_id') userId: UserId,
    @Body() updateUserSidebarTagsDto: UpdateUserSidebarTagsDto
  ) {
    return await this.userService.updateUserSidebarTags(
      userId,
      updateUserSidebarTagsDto.sidebarTags
    )
  }

  @Delete('sidebar-tags/:sidebarTag')
  @ApiParam({ name: 'sidebarTag', type: 'string', required: true })
  @FirebaseTokenAuthGuard()
  public async deleteUserSidebarTag(
    @UserToken('user_id') userId: UserId,
    @Param('sidebarTag') sidebarTag: string
  ) {
    return await this.userService.deleteUserSidebarTag(userId, sidebarTag)
  }
}
