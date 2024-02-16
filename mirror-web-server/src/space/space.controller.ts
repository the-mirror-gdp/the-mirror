import {
  Body,
  Controller,
  Delete,
  Get,
  Logger,
  NotFoundException,
  Optional,
  Param,
  Patch,
  Post,
  Query,
  UploadedFiles,
  UseGuards,
  UseInterceptors,
  UsePipes,
  ValidationPipe
} from '@nestjs/common'
import { AnyFilesInterceptor } from '@nestjs/platform-express'
import {
  ApiBody,
  ApiConsumes,
  ApiCreatedResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiParam,
  ApiProperty,
  ApiQuery,
  ApiResponse
} from '@nestjs/swagger'
import { FirebaseTokenAuthGuard } from '../auth/auth.guard'
import { UserToken } from '../auth/get-user.decorator'
import { PublicFirebaseAuthNotRequired } from '../auth/public.decorator'
import {
  PaginatedResponse,
  PaginationInterface
} from './../util/pagination/pagination.interface'

import {
  RemoveUserRoleForOneDto,
  SetUserRoleForOneDto
} from '../roles/dto/set-user-role-for-one.dto'
import { ROLE } from '../roles/models/role.enum'
import {
  SpaceId,
  SpaceVersionId,
  TagId,
  UserId
} from '../util/mongo-object-id-helpers'
import { CreateSpaceDto } from './dto/create-space.dto'
import { PaginatedSearchSpaceDto } from './dto/paginated-search-space.dto'
import {
  CreateNewSpaceVersionDto,
  SpaceCopyFromTemplateDto,
  UpdateSpaceDto
} from './dto/update-space.dto'
import { SpaceVersion } from './space-version.schema'
import { SpacePublicData } from './space.schema'
import { SpaceService } from './space.service'
import { AddTagToSpaceDto } from './dto/add-tag-to-space.dto'
import { TAG_TYPES } from '../tag/models/tag-types.enum'
import { UpdateSpaceTagsDto } from './dto/update-space-tags.dto'
import { PopulateSpaceDto } from './dto/populate-space.dto'
import { SpaceStatsModel } from './models/space-stats.model'
import { DomainOrAuthUserGuard } from './guards/DomainOrAuthUserGuard.guard'
import { RemixSpaceDto } from './dto/remix-space-dto'
import { version } from 'os'

/**
 * @description Swagger generation doesn't support generics, so for each paginated response, it has to extended the PaginatedResponse class and implement the PaginationInterface
 * @date 2023-07-10 16:33
 */
export class SpacePublicDataPaginatedResponse
  extends PaginatedResponse
  implements PaginationInterface
{
  @ApiProperty({ type: [SpacePublicData] })
  data: SpacePublicData[]
}

@Controller('space')
@UsePipes(new ValidationPipe({ whitelist: true }))
export class SpaceController {
  constructor(
    private readonly spaceService: SpaceService,
    private readonly logger: Logger
  ) {}

  /*****************************
   PUBLICLY ACCESSIBLE ENDPOINTS
   ****************************/

  /**
   * @description Retrieves a collection user's public spaces as public data
   * id prefix added to prevent wildcard route clashes with file method order
   */
  @PublicFirebaseAuthNotRequired()
  @Get('user/:id')
  @FirebaseTokenAuthGuard()
  @ApiOkResponse({ type: [SpacePublicData] })
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async getAllPublicForUser(
    @Param('id') ownerId: UserId,
    @UserToken('user_id') requestingUserId: UserId
  ) {
    return await this.spaceService.findAllPublicForUserWithRolesCheck(
      ownerId,
      true,
      requestingUserId
    )
  }

  /**
   * Same as the above but no populate
   * @description Retrieves a collection user's public spaces as public data
   * id prefix added to prevent wildcard route clashes with file method order
   */
  @PublicFirebaseAuthNotRequired()
  @Get('user-v2/:id')
  @FirebaseTokenAuthGuard()
  @ApiOkResponse({ type: [SpacePublicData] })
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async getAllPublicForUserV2(
    @Param('id') ownerId: UserId,
    @UserToken('user_id') requestingUserId: UserId
  ) {
    return await this.spaceService.findAllPublicForUserWithRolesCheck(
      ownerId,
      false,
      requestingUserId
    )
  }

  /** @description Retrieves a collection of space's as public data */
  @Get('search')
  @UseGuards(DomainOrAuthUserGuard)
  @ApiOkResponse({ type: [SpacePublicData] })
  public async search(
    @UserToken('user_id') userId: UserId,
    @Query('query') query: string
  ): Promise<SpacePublicData[]> {
    return await this.spaceService.searchForPublicSpacesWithRolesCheck(
      userId,
      query,
      true
    )
  }

  /**
   * @description Same as the above but no populate
   * @date 2023-07-12 23:59
   */
  @PublicFirebaseAuthNotRequired()
  @Get('search-v2')
  @FirebaseTokenAuthGuard()
  @ApiOkResponse({ type: [SpacePublicData] })
  public async searchV2(
    @UserToken('user_id') userId: UserId,
    @Query('query') query: string
  ): Promise<SpacePublicData[]> {
    return await this.spaceService.searchForPublicSpacesWithRolesCheck(
      userId,
      query,
      false
    )
  }

  /***********************
   AUTH REQUIRED ENDPOINTS
   **********************/

  /**
   * @deprecated use /space/me-v2 instead
   * @date 2023-04-25 02:29
   */
  @Get('me')
  @ApiOkResponse({ type: [SpacePublicData] })
  @FirebaseTokenAuthGuard()
  public async findAllForMeWhereOwner(@UserToken('user_id') userId: UserId) {
    return await this.spaceService.findAllForUserWithRolesCheck(userId)
  }

  @Get('me-v2')
  @ApiOkResponse({ type: SpacePublicDataPaginatedResponse })
  @FirebaseTokenAuthGuard()
  public async findAllForMeWhereOwnerPaginatedV2(
    @UserToken('user_id') userId: UserId,
    @Query() searchSpaceDto: PaginatedSearchSpaceDto
  ) {
    return await this.spaceService.findForUserWithRolesCheckV2Paginated(
      userId,
      searchSpaceDto,
      ROLE.OWNER,
      undefined,
      true
    )
  }

  /**
   * @description This is the same as me-v2, but no populate
   * @date 2023-07-12 23:53
   */
  @Get('me-v3')
  @ApiOkResponse({ type: SpacePublicDataPaginatedResponse })
  @FirebaseTokenAuthGuard()
  public async findAllForMeWhereOwnerPaginatedV3(
    @UserToken('user_id') userId: UserId,
    @Query() searchSpaceDto: PaginatedSearchSpaceDto
  ) {
    return await this.spaceService.findForUserWithRolesCheckV2Paginated(
      userId,
      searchSpaceDto,
      ROLE.OWNER,
      undefined,
      false
    )
  }

  @Get('popular')
  @FirebaseTokenAuthGuard()
  @ApiQuery({ required: false })
  @ApiOkResponse({ type: [SpacePublicData] })
  public async getPopularSpaces(
    @UserToken('user_id') userId: UserId,
    @Query() populateSpaceDto: PopulateSpaceDto
  ) {
    return await this.spaceService.getPopularSpaces(
      userId,
      populateSpaceDto.populateCreator
    )
  }

  @Get('favorites')
  @FirebaseTokenAuthGuard()
  @ApiQuery({ required: false })
  @ApiOkResponse({ type: [SpacePublicData] })
  public async getFavoriteSpaces(
    @UserToken('user_id') userId: UserId,
    @Query() populateSpaceDto: PopulateSpaceDto
  ) {
    return await this.spaceService.getFavoriteSpaces(
      userId,
      populateSpaceDto.populateCreator
    )
  }

  @Get('recents')
  @FirebaseTokenAuthGuard()
  @ApiQuery({ required: false })
  @ApiOkResponse({ type: [SpacePublicData] })
  public async getRecentSpaces(
    @UserToken('user_id') userId: UserId,
    @Query() populateSpaceDto: PopulateSpaceDto
  ) {
    return await this.spaceService.getRecentSpaces(
      userId,
      populateSpaceDto.populateCreator
    )
  }

  @Get('tag')
  @ApiOkResponse({ type: SpacePublicDataPaginatedResponse })
  @UseGuards(DomainOrAuthUserGuard)
  public async getSpacesByTags(
    @Query() searchDto: PaginatedSearchSpaceDto,
    @UserToken('user_id') userId: UserId
  ) {
    return await this.spaceService.getSpacesByTags(searchDto, userId)
  }

  @Post('tag')
  @FirebaseTokenAuthGuard()
  public async addTagToSpaceWithRoleChecks(
    @UserToken('user_id') userId: UserId,
    @Body() addTagToSpaceDto: AddTagToSpaceDto
  ) {
    return await this.spaceService.addTagToSpaceWithRoleChecks(
      userId,
      addTagToSpaceDto
    )
  }

  @Patch('tag')
  @FirebaseTokenAuthGuard()
  public async updateSpaceTagsByTypeWithRoleChecks(
    @UserToken('user_id') userId: UserId,
    @Body() updateSpaceTagsDto: UpdateSpaceTagsDto
  ) {
    return await this.spaceService.updateSpaceTagsByTypeWithRoleChecks(
      userId,
      updateSpaceTagsDto.spaceId,
      updateSpaceTagsDto.tagType,
      updateSpaceTagsDto.tags
    )
  }

  @Delete('tag/:spaceId/:tagType/:tagName')
  @FirebaseTokenAuthGuard()
  @ApiParam({ name: 'spaceId', type: 'string', required: true })
  @ApiParam({ name: 'tagType', enum: TAG_TYPES, required: true })
  @ApiParam({ name: 'tagName', type: 'string', required: true })
  public async deleteTagFromSpaceWithRoleChecks(
    @UserToken('user_id') userId: UserId,
    @Param('spaceId') spaceId: SpaceId,
    @Param('tagType') tagType: TAG_TYPES,
    @Param('tagName') tagName: string
  ) {
    return await this.spaceService.deleteTagFromSpaceWithRoleChecks(
      userId,
      spaceId,
      tagName,
      tagType
    )
  }

  /**
   * @deprecated use /space/discover-v2 instead
   * @date 2023-04-25 02:29
   */
  @Get('discover')
  @ApiOkResponse({
    type: [SpacePublicData],
    description: 'The space data for the /discover tab'
  })
  @FirebaseTokenAuthGuard()
  public async findDiscoverSpacesForUser(@UserToken('user_id') userId: UserId) {
    return await this.spaceService.findDiscoverSpacesForUser(userId)
  }

  @Get('discover-v2')
  @ApiOkResponse({
    type: SpacePublicDataPaginatedResponse,
    description: 'The space data for the /discover tab'
  })
  @FirebaseTokenAuthGuard()
  public async findDiscoverSpacesForUserPaginatedV2(
    @UserToken('user_id') userId: UserId,
    @Query() searchSpaceDto: PaginatedSearchSpaceDto
  ) {
    return await this.spaceService.findDiscoverSpacesForUserWithRolesCheckPaginatedV2(
      userId,
      searchSpaceDto,
      undefined,
      true
    )
  }

  /**
   * @description This is the same as discover-v2, but no populate
   * @date 2023-07-12 23:53
   */
  @Get('discover-v3')
  @ApiOkResponse({
    type: SpacePublicDataPaginatedResponse,
    description: 'The space data for the /discover tab'
  })
  @UseGuards(DomainOrAuthUserGuard)
  public async findDiscoverSpacesForUserPaginatedV3(
    @UserToken('user_id') userId: UserId,
    @Query() searchSpaceDto: PaginatedSearchSpaceDto
  ) {
    return await this.spaceService.findDiscoverSpacesForUserWithRolesCheckPaginatedV2(
      userId ? userId : undefined,
      searchSpaceDto,
      undefined,
      false
    )
  }

  /**
   * @description This is the same as discover-v2, but no populate
   * @date 2023-07-12 23:53
   */
  @Get('templates')
  @ApiOkResponse({
    type: SpacePublicDataPaginatedResponse,
    description: 'The space data for the /discover tab'
  })
  @FirebaseTokenAuthGuard()
  public async findSpaceTemplates(@UserToken('user_id') userId: UserId) {
    return await this.spaceService.findSpaceTemplatesList(userId)
  }

  /**
   * @description Returns all Spaces with an activeSpaceVersion
   * @date 2023-06-10 22:23
   */
  @Get('get-published-spaces')
  @ApiOkResponse({
    type: SpacePublicDataPaginatedResponse
  })
  @FirebaseTokenAuthGuard()
  public async getPublishedSpaces(
    @UserToken('user_id') userId: UserId,
    @Query() searchSpaceDto: PaginatedSearchSpaceDto
  ) {
    return await this.spaceService.findForUserWithRolesCheckV2Paginated(
      userId,
      searchSpaceDto,
      ROLE.OBSERVER,
      { activeSpaceVersion: { $exists: true } },
      true
    )
  }

  /**
   * @description same as get-published-spaces, but no populate
   * @date 2023-07-12 23:54
   */
  @Get('get-published-spaces-v2')
  @ApiOkResponse({
    type: SpacePublicDataPaginatedResponse
  })
  @UseGuards(DomainOrAuthUserGuard)
  public async getPublishedSpacesV2(
    @UserToken('user_id') userId: UserId,
    @Query() searchSpaceDto: PaginatedSearchSpaceDto,
    @Query() populateSpaceDto: PopulateSpaceDto
  ) {
    return await this.spaceService.findForUserWithRolesCheckV2Paginated(
      userId ? userId : undefined,
      searchSpaceDto,
      ROLE.OBSERVER,
      { activeSpaceVersion: { $exists: true } },
      false,
      populateSpaceDto.populateCreator
    )
  }

  @Get('latest-published/:spaceId')
  @ApiOkResponse({
    type: [SpaceVersion],
    description:
      'The latest version of a published space. This is the CLIENT-SIDE route for /latest'
  })
  @ApiParam({ name: 'spaceId', type: 'string', required: true })
  @FirebaseTokenAuthGuard()
  public async getLatestPublishedSpaceBySpaceId(
    @Param('spaceId') spaceId: SpaceId
  ) {
    // The admin route is called here because every published space is public currently, hence "published"
    const spaceVersion =
      await this.spaceService.getLatestSpaceVersionBySpaceIdAdmin(spaceId)

    if (!spaceVersion) {
      this.logger.log(
        `latest-published/:id ${spaceId} not found`,
        SpaceController.name
      )
      throw new NotFoundException('No Published Space Available')
    }
    return spaceVersion
  }

  @Get('refresh-stats/:spaceId')
  @ApiParam({ name: 'spaceId', type: 'string', required: true })
  @FirebaseTokenAuthGuard()
  @ApiOkResponse({ type: SpaceStatsModel })
  public async refreshStats(@Param('spaceId') spaceId: SpaceId) {
    return await this.spaceService.refreshSpaceStats(spaceId)
  }

  @Get(':id')
  @ApiOkResponse({ type: SpacePublicData })
  @ApiNotFoundResponse()
  @ApiParam({ name: 'id', type: 'string', required: true })
  @UseGuards(DomainOrAuthUserGuard)
  public async findOne(
    @Param('id') spaceId: SpaceId,
    @UserToken('user_id') userId: UserId,
    @Query() populateSpaceDto: PopulateSpaceDto
  ) {
    return await this.spaceService.findOneWithOutRolesCheck(
      spaceId,
      populateSpaceDto.populateUsersPresent
    )
  }

  // same as findAllForUser but no populate
  @Get('v2')
  @ApiOkResponse({ type: [SpacePublicData] })
  @FirebaseTokenAuthGuard()
  public async findAllForUserV2(@UserToken('user_id') ownerId: UserId) {
    return await this.spaceService.findAllPublic(ownerId, false)
  }

  @Get()
  @ApiOkResponse({ type: [SpacePublicData] })
  @FirebaseTokenAuthGuard()
  public async findAllForUser(@UserToken('user_id') ownerId: UserId) {
    return await this.spaceService.findAllPublic(ownerId, true)
  }

  @Post()
  @ApiCreatedResponse({
    type: SpacePublicData
  })
  @FirebaseTokenAuthGuard()
  public async create(
    @UserToken('user_id') userId: UserId,
    @Body() createSpaceDto: CreateSpaceDto
  ) {
    const createSpaceData = Object.assign({}, createSpaceDto, {
      owner: userId, // the owner is the requesting user by default
      creator: userId // the creator is the requesting user by default
    })

    return await this.spaceService.createOneWithRolesCheck(
      userId,
      createSpaceData
    )
  }

  @Patch(':id')
  @FirebaseTokenAuthGuard()
  @ApiOkResponse({ type: SpacePublicData })
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async update(
    @UserToken('user_id') userId: UserId,
    @Param('id') spaceId: SpaceId,
    @Body() updateSpaceDto: UpdateSpaceDto
  ) {
    return await this.spaceService.updateOneWithRolesCheck(
      userId,
      spaceId,
      updateSpaceDto
    )
  }

  @Delete(':id')
  @FirebaseTokenAuthGuard()
  @ApiOkResponse({ type: SpacePublicData })
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async remove(
    @UserToken('user_id') userId: UserId,
    @Param('id') spaceId: SpaceId
  ) {
    return await this.spaceService.removeOneWithRolesCheck(userId, spaceId)
  }

  @Delete('voxels/:id')
  @FirebaseTokenAuthGuard()
  @ApiOkResponse({ type: SpacePublicData })
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async clearVoxels(@Param('id') id: string) {
    return await this.spaceService.clearVoxels(id)
  }

  @Post('copy/:id')
  @FirebaseTokenAuthGuard()
  @ApiOkResponse({
    type: SpacePublicData,
    description: `Copy a user's own space`
  })
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async copy(
    @Param('id') spaceId: SpaceId,
    @UserToken('user_id') userId: UserId
  ) {
    return await this.spaceService.copyFullSpaceWithRolesCheck(userId, spaceId)
  }

  @Post('copy-from-template/:id')
  @FirebaseTokenAuthGuard()
  @ApiOkResponse({ type: SpacePublicData })
  @ApiParam({ name: 'id', type: 'string', required: true })
  @ApiBody({
    type: SpaceCopyFromTemplateDto
  })
  public async copyFromTemplate(
    @Param('id') spaceId: SpaceId,
    @UserToken('user_id') userId: UserId,
    @Optional()
    @Body()
    spaceCopyFromTemplateDto?: SpaceCopyFromTemplateDto
  ) {
    return await this.spaceService.copyFullSpaceWithRolesCheck(
      userId,
      spaceId,
      undefined,
      spaceCopyFromTemplateDto?.name,
      spaceCopyFromTemplateDto?.description,
      spaceCopyFromTemplateDto?.publicBuildPermissions,
      spaceCopyFromTemplateDto?.maxUsers
    )
  }

  @Post('remix-space/:id')
  @FirebaseTokenAuthGuard()
  @ApiParam({ name: 'id', type: 'string', required: true })
  public remixSpace(
    @Param('id') spaceId: SpaceId,
    @UserToken('user_id') userId: UserId,
    @Body() remixSpaceDto: RemixSpaceDto
  ) {
    return this.spaceService.remixSpaceWithRolesCheck(
      spaceId,
      userId,
      remixSpaceDto
    )
  }

  @Post('version/:id')
  @FirebaseTokenAuthGuard()
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async publish(
    @UserToken('user_id') userId: UserId,
    @Param('id') spaceId: SpaceId,
    @Optional()
    @Body()
    createNewSpaceVersionDto?: CreateNewSpaceVersionDto
  ) {
    const space = await this.spaceService.findOneWithRolesCheck(userId, spaceId)
    return await this.spaceService.publishSpaceByIdWithRolesCheck(
      userId,
      space._id,
      createNewSpaceVersionDto.updateSpaceWithActiveSpaceVersion,
      createNewSpaceVersionDto.name
    )
  }

  @Get('version/:id')
  @UseGuards(DomainOrAuthUserGuard)
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async getPublishedSpacesBySpaceId(@Param('id') spaceId: SpaceId) {
    return await this.spaceService.getSpaceVersionsBySpaceId(spaceId)
  }

  @Post('/:id/upload/public')
  @FirebaseTokenAuthGuard()
  @ApiBody({ schema: { type: 'file' }, isArray: true })
  @ApiConsumes('multipart/form-data')
  @ApiCreatedResponse({ type: SpacePublicData })
  @UseInterceptors(AnyFilesInterceptor({ limits: { files: 4 } }))
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async uploadPublic(
    @UserToken('user_id') userId: UserId,
    @Param('id') spaceId: SpaceId,
    @UploadedFiles() files: Express.Multer.File[]
  ) {
    const images = await this.spaceService.uploadSpaceFilesPublicWithRolesCheck(
      userId,
      {
        spaceId,
        files
      }
    )
    return await this.spaceService.updateSpaceImagesWithRolesCheck(
      userId,
      spaceId,
      images
    )
  }

  @Post('restore-space-from-version/:id')
  @FirebaseTokenAuthGuard()
  @ApiParam({ name: 'id', type: 'string', required: true })
  async restoreSpaceFromSpaceVersion(
    @Param('id') spaceVersionId: SpaceVersionId,
    @UserToken('user_id') userId: UserId
  ) {
    return await this.spaceService.restoreSpaceFromSpaceVersionWithRolesCheck(
      spaceVersionId,
      userId
    )
  }

  /**
   * START Section: Owner permissions for role modification
   */
  @Patch(':id/role/set')
  @FirebaseTokenAuthGuard()
  @ApiOkResponse({ type: SpacePublicData })
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async setUserRoleForOne(
    @UserToken('user_id') userId: UserId,
    @Param('id') spaceId: SpaceId,
    @Body() setUserRoleForOneDto: SetUserRoleForOneDto
  ) {
    return await this.spaceService.setUserRoleForOneWithOwnerCheck(
      userId,
      setUserRoleForOneDto.targetUserId,
      spaceId,
      setUserRoleForOneDto.role
    )
  }

  @Patch(':id/role/unset')
  @FirebaseTokenAuthGuard()
  @ApiOkResponse({ type: SpacePublicData })
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async removeUserRoleForOne(
    @UserToken('user_id') userId: UserId,
    @Param('id') spaceId: SpaceId,
    @Body() removeUserRoleForOneDto: RemoveUserRoleForOneDto
  ) {
    return await this.spaceService.removeUserRoleForOneWithOwnerCheck(
      userId,
      removeUserRoleForOneDto.targetUserId,
      spaceId
    )
  }
  /**
   * END Section: Owner permissions for role modification
   */

  @Post(':id/kickme')
  @FirebaseTokenAuthGuard()
  @ApiOkResponse({ type: SpacePublicData })
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async kickMe(
    @UserToken('user_id') userId: UserId,
    @Param('id') spaceId: SpaceId
  ) {
    return await this.spaceService.kickUserByAdmin(userId, spaceId)
  }
}
