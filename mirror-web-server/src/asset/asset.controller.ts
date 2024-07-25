import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Optional,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Query,
  Res,
  UploadedFile,
  UseGuards,
  UseInterceptors,
  UsePipes,
  ValidationPipe
} from '@nestjs/common'
import { FileInterceptor } from '@nestjs/platform-express'
import {
  ApiBody,
  ApiConsumes,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiParam,
  ApiProperty,
  ApiQuery
} from '@nestjs/swagger'
import { plainToInstance } from 'class-transformer'
import { validateOrReject } from 'class-validator'
import { Types } from 'mongoose'
import { FirebaseTokenAuthGuard } from '../auth/auth.guard'
import { UserToken } from '../auth/get-user.decorator'
import { PublicFirebaseAuthNotRequired } from '../auth/public.decorator'
import { ASSET_TYPE } from '../option-sets/asset-type'
import {
  FileUploadApiResponse,
  FileUploadPublicApiResponse
} from '../util/file-upload/file-upload'
import { AssetId, UserId } from '../util/mongo-object-id-helpers'
import {
  PaginatedResponse,
  PaginationInterface
} from './../util/pagination/pagination.interface'
import { AssetApiResponse, AssetUsageApiResponse } from './asset.models'
import { Asset } from './asset.schema'
import { AssetService } from './asset.service'
import {
  CreateAssetDto,
  CreateMapDto,
  CreateMaterialDto,
  CreateTextureDto
} from './dto/create-asset.dto'
import {
  PaginatedSearchAssetDtoV2,
  getPopulateFieldsFromPaginatedSearchAssetDto
} from './dto/paginated-search-asset.dto'
import { SearchAssetDto } from './dto/search-asset.dto'
import {
  AddAssetPurchaseOptionDto,
  UpdateAssetDto
} from './dto/update-asset.dto'
import { PopulateField } from '../util/pagination/pagination.service'
import { TAG_TYPES } from '../tag/models/tag-types.enum'
import { AddTagToAssetDto } from './dto/add-tag-to-asset.dto'
import { UpdateAssetTagsDto } from './dto/update-asset-tags.dto'
import { IncludeSoftDeletedAssetDto } from './dto/include-soft-deleted-asset.dto'
import { DomainOrAuthUserGuard } from '../space/guards/DomainOrAuthUserGuard.guard'
import { GetAssetsPriceDto } from './dto/assets-price.dto'
import { Response } from 'express'

/**
 * @description Swagger generation doesn't support generics, so for each paginated response, it has to extended the PaginatedResponse class and implement the PaginationInterface
 * @date 2023-07-10 16:33
 */
export class AssetFullDataPaginatedResponse
  extends PaginatedResponse
  implements PaginationInterface
{
  @ApiProperty({ type: [Asset] })
  data: Asset[]
}
@UsePipes(new ValidationPipe({ whitelist: false }))
@Controller('asset')
export class AssetController {
  constructor(private readonly assetService: AssetService) {}

  /*****************************
   PUBLICLY ACCESSIBLE ENDPOINTS
   ****************************/

  /** Search for an asset */
  @PublicFirebaseAuthNotRequired()
  @Get('search')
  @ApiOkResponse({ type: [AssetApiResponse] })
  public async search(@Query() searchAssetDto: PaginatedSearchAssetDtoV2) {
    return await this.assetService.searchAssetsPublic(searchAssetDto, true)
  }

  /**
   * @description Same as above but no populate
   * @date 2023-07-12 23:49
   */
  @PublicFirebaseAuthNotRequired()
  @Get('search-v2')
  @ApiOkResponse({ type: [AssetApiResponse] })
  public async searchV2(@Query() searchAssetDto: PaginatedSearchAssetDtoV2) {
    return await this.assetService.searchAssetsPublic(searchAssetDto, false)
  }

  /***********************
   AUTH REQUIRED ENDPOINTS
   **********************/

  /**
   * Get Mirror Library assets
   * TODO this needs to be paginated
   */
  @Get('library')
  @FirebaseTokenAuthGuard()
  @ApiOkResponse({ type: [AssetApiResponse] })
  @ApiQuery({ required: false })
  public async getMirrorPublicLibraryAssets(
    @Query() searchAssetDto?: PaginatedSearchAssetDtoV2
  ) {
    return await this.assetService.findMirrorPublicLibraryAssets(
      searchAssetDto,
      undefined,
      true
    )
  }

  /**
   * @description Same as getMirrorPublicLibraryAssets, but doesn't populate the fields
   * @date 2023-07-12 23:33
   */
  @Get('library-v2')
  @ApiOkResponse({ type: [AssetApiResponse] })
  @FirebaseTokenAuthGuard()
  @ApiQuery({ required: false })
  public async getMirrorPublicLibraryAssetsV2(
    @Query() searchAssetDto?: PaginatedSearchAssetDtoV2
  ) {
    return await this.assetService.findMirrorPublicLibraryAssets(
      searchAssetDto,
      undefined,
      false
    )
  }

  @Post()
  @FirebaseTokenAuthGuard()
  @ApiCreatedResponse({ type: AssetApiResponse })
  @ApiBody({
    type: CreateAssetDto
  })
  public async create(
    @UserToken('user_id') userId: UserId,
    @Body()
    createAssetDto: CreateAssetDto &
      CreateMaterialDto &
      CreateTextureDto &
      CreateMapDto // See https://www.loom.com/share/7e09d2777ef94368bcd5fd8c8341b5ef for walkthrough of DTOs with discriminators
  ) {
    // check whether to use the subclass as determined by assetType
    switch (createAssetDto.assetType) {
      case ASSET_TYPE.MATERIAL:
        const dtoMaterial = plainToInstance(CreateMaterialDto, createAssetDto)
        try {
          await validateOrReject(dtoMaterial)
        } catch (error) {
          console.error(error.join(','))
          throw new BadRequestException(error.join(','))
        }
        return await this.assetService.createMaterial({
          ownerId: userId,
          ...dtoMaterial
        })
      case ASSET_TYPE.TEXTURE:
        const dtoTexture = plainToInstance(CreateTextureDto, createAssetDto)
        try {
          await validateOrReject(dtoTexture)
        } catch (error) {
          console.error(error.join(','))
          throw new BadRequestException(error.join(','))
        }
        return await this.assetService.createTexture({
          ownerId: userId,
          ...dtoTexture
        })
      case ASSET_TYPE.MAP:
        const dtoMap = plainToInstance(CreateMapDto, createAssetDto)
        try {
          await validateOrReject(dtoMap)
        } catch (error) {
          console.error(error.join(','))
          throw new BadRequestException(error.join(','))
        }
        return await this.assetService.createMap({
          ownerId: userId,
          ...dtoMap
        })
      default:
        const dtoAsset = plainToInstance(CreateAssetDto, createAssetDto)
        try {
          await validateOrReject(dtoAsset)
        } catch (error) {
          console.error(error.join(','))
          throw new BadRequestException(error.join(','))
        }
        return await this.assetService.createAsset({
          ownerId: userId,
          ...dtoAsset
        })
    }
  }

  @Get('recents')
  @FirebaseTokenAuthGuard()
  @ApiOkResponse({ type: [AssetApiResponse] })
  public async getUserRecentInstancedAssets(
    @UserToken('user_id') userId: UserId,
    @Query() searchAssetDto?: PaginatedSearchAssetDtoV2
  ) {
    return await this.assetService.getRecentInstancedAssets(
      userId,
      searchAssetDto
    )
  }

  @Post('new')
  @FirebaseTokenAuthGuard()
  @ApiConsumes('multipart/form-data')
  @ApiBody({ schema: { type: 'file' } })
  @ApiCreatedResponse({ type: AssetApiResponse })
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fieldSize: 20 * 1024 * 1024, fileSize: 20 * 1024 * 1024 } // 20MB limit. Arbitrary. I wanted to reference a class property of this.fileSizeBytes, but not sure if that's accessible in a decorator
    })
  )
  public async createWithUpload(
    @UserToken('user_id') userId: UserId,
    @Body()
    createAssetDto:
      | CreateAssetDto
      | CreateMaterialDto
      | CreateTextureDto
      | CreateMapDto, // See https://www.loom.com/share/7e09d2777ef94368bcd5fd8c8341b5ef for walkthrough of DTOs with discriminators
    @UploadedFile() file: Express.Multer.File
  ) {
    // check whether to use the subclass as determined by assetType
    switch (createAssetDto.assetType) {
      case ASSET_TYPE.MATERIAL:
        const dtoMaterial = plainToInstance(CreateMaterialDto, createAssetDto)
        try {
          await validateOrReject(dtoMaterial)
        } catch (error) {
          console.error(error.join(','))
          throw new BadRequestException(error.join(','))
        }
        return await this.assetService.createMaterialWithUpload(
          { ownerId: userId, ...dtoMaterial },
          file
        )
      case ASSET_TYPE.TEXTURE:
        const dtoTexture = plainToInstance(CreateTextureDto, createAssetDto)
        try {
          await validateOrReject(dtoTexture)
        } catch (error) {
          console.error(error.join(','))
          throw new BadRequestException(error.join(','))
        }
        return await this.assetService.createTextureWithUpload(
          { ownerId: userId, ...dtoTexture },
          file
        )
      case ASSET_TYPE.MAP:
        const dtoMap = plainToInstance(CreateMapDto, createAssetDto)
        try {
          await validateOrReject(dtoMap)
        } catch (error) {
          console.error(error.join(','))
          throw new BadRequestException(error.join(','))
        }
        return await this.assetService.createMapWithUpload(
          { ownerId: userId, ...dtoMap },
          file
        )
      // Default to base Asset class
      default:
        const dtoAsset = plainToInstance(CreateAssetDto, createAssetDto)
        try {
          await validateOrReject(dtoAsset)
        } catch (error) {
          console.error(error.join(','))
          throw new BadRequestException(error.join(','))
        }
        return await this.assetService.createAssetWithUpload(
          { ownerId: userId, ...dtoAsset },
          file
        )
    }
  }

  /**
   * Get player's created assets
   * TODO this needs to be paginated
   */
  @Get('me')
  @FirebaseTokenAuthGuard()
  @ApiOkResponse({ type: [AssetApiResponse] })
  @ApiQuery({ required: false })
  public async getAssetsForMe(
    @UserToken('user_id') userId: UserId,
    @Query() searchAssetDto?: PaginatedSearchAssetDtoV2
  ) {
    return await this.assetService.findAllAssetsForUserIncludingPrivate(
      userId,
      searchAssetDto,
      undefined,
      true
    )
  }
  /**
   * Same as above but no populate
   * TODO this needs to be paginated
   */
  @Get('me-v2')
  @FirebaseTokenAuthGuard()
  @ApiOkResponse({ type: [AssetApiResponse] })
  @ApiQuery({ required: false })
  public async getAssetsForMeV2(
    @UserToken('user_id') userId: UserId,
    @Query() searchAssetDto?: PaginatedSearchAssetDtoV2
  ) {
    return await this.assetService.findAllAssetsForUserIncludingPrivate(
      userId,
      searchAssetDto,
      undefined,
      false
    )
  }

  /**
   * Get all player's accessible assets. Accessible assets are assets that are public, or assets that are private but owned by the user.
   */
  @Get('my-library')
  @FirebaseTokenAuthGuard()
  @UsePipes(new ValidationPipe({ transform: true }))
  @ApiOkResponse({ type: AssetFullDataPaginatedResponse })
  @ApiQuery({ required: false })
  public async getAllAccessibleAssetsOfUser(
    @UserToken('user_id') userId: UserId,
    @Query() searchAssetDto: PaginatedSearchAssetDtoV2
  ): Promise<AssetFullDataPaginatedResponse> {
    return await this.assetService.findAllAccessibleAssetsOfUser(
      userId,
      searchAssetDto,
      true
    )
  }

  /**
   * @description Same as above but no populate
   * @date 2023-07-12 23:45
   */
  @Get('my-library-v2')
  @FirebaseTokenAuthGuard()
  @UsePipes(new ValidationPipe({ transform: true }))
  @ApiOkResponse({ type: AssetFullDataPaginatedResponse })
  @ApiQuery({ required: false })
  public async getAllAccessibleAssetsOfUserV2(
    @UserToken('user_id') userId: UserId,
    @Query() searchAssetDto: PaginatedSearchAssetDtoV2
  ): Promise<AssetFullDataPaginatedResponse> {
    return await this.assetService.findAllAccessibleAssetsOfUser(
      userId,
      searchAssetDto,
      false
    )
  }

  @Get('recent')
  @FirebaseTokenAuthGuard()
  @UsePipes(new ValidationPipe({ transform: true }))
  @ApiOkResponse({ type: [AssetApiResponse] })
  public async getRecentAssetsForUser(
    @UserToken('user_id') userId: UserId,
    @Query('limit', ParseIntPipe) @Optional() limit?: number,
    @Query()
    includeSoftDeletedAssetDto?: IncludeSoftDeletedAssetDto
  ) {
    const assets = await this.assetService.findRecentAssetsOfUserWithRolesCheck(
      userId,
      includeSoftDeletedAssetDto.includeSoftDeleted,
      limit,
      true
    )
    return assets
  }

  @Get('recent-v2')
  @FirebaseTokenAuthGuard()
  @UsePipes(new ValidationPipe({ transform: true }))
  @ApiOkResponse({ type: [AssetApiResponse] })
  public async getRecentAssetsForUserV2(
    @UserToken('user_id') userId: UserId,
    @Query('limit', ParseIntPipe) @Optional() limit?: number,
    @Query()
    includeSoftDeletedAssetDto?: IncludeSoftDeletedAssetDto
  ) {
    const assets = await this.assetService.findRecentAssetsOfUserWithRolesCheck(
      userId,
      includeSoftDeletedAssetDto.includeSoftDeleted,
      limit,
      false
    )
    return assets
  }

  @Get('my-assets')
  @FirebaseTokenAuthGuard()
  @ApiOkResponse({ type: AssetFullDataPaginatedResponse })
  @ApiQuery({ required: false })
  public async getPaginatedMyAssets(
    @UserToken('user_id') userId: UserId,
    @Query() searchAssetDto?: PaginatedSearchAssetDtoV2
  ): Promise<AssetFullDataPaginatedResponse> {
    return await this.assetService.findPaginatedMyAssetsWithRolesCheck(
      userId,
      searchAssetDto,
      true
    )
  }

  /**
   * @description Same as above but no populate
   * @date 2023-07-12 23:43
   */
  @Get('my-assets-v2')
  @FirebaseTokenAuthGuard()
  @ApiOkResponse({ type: AssetFullDataPaginatedResponse })
  @ApiQuery({ required: false })
  public async getPaginatedMyAssetsV2(
    @UserToken('user_id') userId: UserId,
    @Query() searchAssetDto?: PaginatedSearchAssetDtoV2
  ): Promise<AssetFullDataPaginatedResponse> {
    return await this.assetService.findPaginatedMyAssetsWithRolesCheck(
      userId,
      searchAssetDto,
      false
    )
  }

  @Get('mirror-assets')
  @FirebaseTokenAuthGuard()
  @ApiOkResponse({ type: AssetFullDataPaginatedResponse })
  @ApiQuery({ required: false })
  public async getPaginatedMirrorAssets(
    @UserToken('user_id') userId: UserId,
    @Query() searchAssetDto?: PaginatedSearchAssetDtoV2
  ): Promise<AssetFullDataPaginatedResponse> {
    return await this.assetService.findPaginatedMirrorAssetsWithRolesCheck(
      userId,
      searchAssetDto,
      this.assetService.standardPopulateFields
    )
  }

  /**
   * @description Same as above but no populate
   * @date 2023-07-12 23:41
   */
  @Get('mirror-assets-v2')
  @UseGuards(DomainOrAuthUserGuard)
  @ApiOkResponse({ type: AssetFullDataPaginatedResponse })
  @ApiQuery({ required: false })
  public async getPaginatedMirrorAssetsV2(
    @UserToken('user_id') userId: UserId,
    @Query() searchAssetDto?: PaginatedSearchAssetDtoV2
  ): Promise<AssetFullDataPaginatedResponse> {
    // parse through populate fields
    const populateFields: PopulateField[] =
      getPopulateFieldsFromPaginatedSearchAssetDto(searchAssetDto)

    return await this.assetService.findPaginatedMirrorAssetsWithRolesCheck(
      userId,
      searchAssetDto,
      populateFields
    )
  }

  @Get('user/:targetUserId')
  @FirebaseTokenAuthGuard()
  @ApiOkResponse({ type: [AssetApiResponse] })
  @ApiParam({ name: 'targetUserId', type: 'string', required: true })
  public async findAllForUser(
    @UserToken('user_id') requestingUserId: UserId,
    @Param('targetUserId') targetUserId: UserId,
    @Query() searchAssetDto?: SearchAssetDto
  ) {
    // Validate that it's a Mongo ObjectId
    if (!Types.ObjectId.isValid(targetUserId)) {
      throw new BadRequestException('ID is not a valid Mongo ObjectID')
    }
    return await this.assetService.findAllPublicAssetsForUserWithRolesCheck(
      requestingUserId,
      targetUserId
    )
  }

  @Get('usage/:assetId')
  @FirebaseTokenAuthGuard()
  @ApiOkResponse({ type: AssetUsageApiResponse })
  @ApiParam({ name: 'assetId', type: 'string', required: true })
  public async findOneAssetUsage(
    @UserToken('user_id') userId: UserId,
    @Param('assetId') assetId: AssetId
  ) {
    // Validate that it's a Mongo ObjectId
    if (!Types.ObjectId.isValid(assetId)) {
      throw new BadRequestException('ID is not a valid Mongo ObjectID')
    }
    return await this.assetService.findAssetUsageWithRolesCheck(userId, assetId)
  }

  @Get('tag')
  @ApiOkResponse({ type: AssetFullDataPaginatedResponse })
  @UseGuards(DomainOrAuthUserGuard)
  public async getAssetsByTag(
    @Query() searchDto: PaginatedSearchAssetDtoV2,
    @UserToken('user_id') userId: UserId
  ) {
    return await this.assetService.getAssetsByTag(searchDto, userId)
  }

  @Post('tag')
  public async addTagToAssetsWithRoleChecks(
    @UserToken('user_id') userId: UserId,
    @Body() addTagToAssetDto: AddTagToAssetDto
  ) {
    return await this.assetService.addTagToAssetsWithRoleChecks(
      userId,
      addTagToAssetDto
    )
  }

  @Patch('tag')
  @FirebaseTokenAuthGuard()
  public async updateAssetTagsByTypeWithRoleChecks(
    @UserToken('user_id') userId: UserId,
    @Body() updateAssetTagsDto: UpdateAssetTagsDto
  ) {
    return await this.assetService.updateAssetTagsByTypeWithRoleChecks(
      userId,
      updateAssetTagsDto.assetId,
      updateAssetTagsDto.tagType,
      updateAssetTagsDto.tags
    )
  }

  @Delete('tag/:assetId/:tagType/:tagName')
  @FirebaseTokenAuthGuard()
  @ApiParam({ name: 'assetId', type: 'string', required: true })
  @ApiParam({ name: 'tagType', enum: TAG_TYPES, required: true })
  @ApiParam({ name: 'tagName', type: 'string', required: true })
  public async deleteTagFromAssetWithRoleChecks(
    @UserToken('user_id') userId: UserId,
    @Param('assetId') assetId: AssetId,
    @Param('tagType') tagType: TAG_TYPES,
    @Param('tagName') tagName: string
  ) {
    return await this.assetService.deleteTagFromAssetWithRoleChecks(
      userId,
      assetId,
      tagName,
      tagType
    )
  }

  @Get(':id')
  @UseGuards(DomainOrAuthUserGuard)
  @ApiOkResponse({ type: AssetApiResponse })
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async findOne(
    @UserToken('user_id') userId: UserId,
    @Param('id') assetId: AssetId
  ) {
    // Validate that it's a Mongo ObjectId
    if (!Types.ObjectId.isValid(assetId)) {
      throw new BadRequestException('ID is not a valid Mongo ObjectID')
    }
    return await this.assetService.findOneWithRolesCheck(userId, assetId)
  }

  @Patch(':id')
  @FirebaseTokenAuthGuard()
  @ApiOkResponse({ type: AssetApiResponse })
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async update(
    @UserToken('user_id') userId: UserId,
    @Param('id') assetId: AssetId,
    @Body() updateAssetDto: UpdateAssetDto
  ) {
    // Validate that it's a Mongo ObjectId
    if (!Types.ObjectId.isValid(assetId)) {
      throw new BadRequestException('ID is not a valid Mongo ObjectID')
    }
    return await this.assetService.updateOneWithRolesCheck(
      userId,
      assetId,
      updateAssetDto
    )
  }

  @Delete(':id')
  @FirebaseTokenAuthGuard()
  @ApiParam({ name: 'id', type: 'string', required: true })
  @ApiOkResponse({ type: AssetApiResponse })
  public async remove(
    @UserToken('user_id') userId: UserId,
    @Param('id') assetId: AssetId
  ) {
    return await this.assetService.removeOneWithRolesCheck(userId, assetId)
  }

  /**
   * @description This endpoint is used to undo soft delete of an asset.
   * (Remove isSoftDeleted and softDeletedAt fields from the asset document)
   *
   * @date 2023-11-23
   */
  @Post('undo-soft-delete/:assetId')
  @FirebaseTokenAuthGuard()
  @ApiParam({ name: 'assetId', type: 'string', required: true })
  @ApiOkResponse({ type: String })
  public async undoAssetSoftDelete(
    @UserToken('user_id') userId: UserId,
    @Param('assetId') assetId: AssetId
  ) {
    return await this.assetService.undoAssetSoftDelete(userId, assetId)
  }

  ///////////////////////////////////////
  /// File Uploading Below //////////////
  ///////////////////////////////////////

  @Post('/:assetId/upload')
  @FirebaseTokenAuthGuard()
  @ApiParam({ name: 'assetId', type: 'string', required: true })
  @ApiConsumes('multipart/form-data')
  @ApiBody({ schema: { type: 'file' } })
  @ApiCreatedResponse({ type: FileUploadApiResponse })
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fieldSize: 20 * 1024 * 1024, fileSize: 20 * 1024 * 1024 } // 20MB limit. Arbitrary. I wanted to reference a class property of this.fileSizeBytes, but not sure if that's accessible in a decorator
    })
  )
  public async upload(
    @Param('assetId') assetId: AssetId,
    @UserToken('user_id') userId: UserId,
    @UploadedFile() file: Express.Multer.File
  ) {
    // Validate that it's a Mongo ObjectId
    if (!Types.ObjectId.isValid(assetId)) {
      throw new BadRequestException('ID is not a valid Mongo ObjectID')
    }

    const { relativePath: currentFile } =
      await this.assetService.uploadAssetFileWithRolesCheck({
        assetId,
        userId,
        file
      })

    return await this.assetService.updateOneWithRolesCheck(userId, assetId, {
      currentFile
    })
  }

  @Post('/:id/upload/public')
  @FirebaseTokenAuthGuard()
  @ApiParam({ name: 'id', type: 'string', required: true })
  @ApiConsumes('multipart/form-data')
  @ApiBody({ schema: { type: 'file' } })
  @ApiCreatedResponse({ type: FileUploadPublicApiResponse })
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fieldSize: 20 * 1024 * 1024, fileSize: 20 * 1024 * 1024 } // 20MB limit. Arbitrary. I wanted to reference a class property of this.fileSizeBytes, but not sure if that's accessible in a decorator
    })
  )
  public async uploadPublic(
    @Param('id') assetId: AssetId,
    @UserToken('user_id') userId: UserId,
    @UploadedFile() file: Express.Multer.File
  ) {
    // Validate that it's a Mongo ObjectId
    if (!Types.ObjectId.isValid(assetId)) {
      throw new BadRequestException('ID is not a valid Mongo ObjectID')
    }
    const { publicUrl: currentFile } =
      await this.assetService.uploadAssetFilePublicWithRolesCheck({
        assetId,
        userId,
        file
      })

    return await this.assetService.updateOneWithRolesCheck(userId, assetId, {
      currentFile
    })
  }

  @Post('/:id/upload/thumbnail')
  @FirebaseTokenAuthGuard()
  @ApiParam({ name: 'id', type: 'string', required: true })
  @ApiConsumes('multipart/form-data')
  @ApiBody({ schema: { type: 'file' } })
  @ApiCreatedResponse({ type: FileUploadPublicApiResponse })
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fieldSize: 20 * 1024 * 1024, fileSize: 20 * 1024 * 1024 } // 20MB limit. Arbitrary. I wanted to reference a class property of this.fileSizeBytes, but not sure if that's accessible in a decorator
    })
  )
  public async uploadThumbnail(
    @Param('id') assetId: AssetId,
    @UserToken('user_id') userId: UserId,
    @UploadedFile() file: Express.Multer.File
  ) {
    // Validate that it's a Mongo ObjectId
    if (!Types.ObjectId.isValid(assetId)) {
      throw new BadRequestException('ID is not a valid Mongo ObjectID')
    }
    const { publicUrl: thumbnail } =
      await this.assetService.uploadAssetThumbnailWithRolesCheck({
        assetId,
        userId,
        file
      })

    return await this.assetService.updateOneWithRolesCheck(userId, assetId, {
      thumbnail
    })
  }

  @Get('by/start-item')
  @FirebaseTokenAuthGuard()
  public async getAsset(
    @UserToken('user_id') userId: UserId,
    @Query() queryParams: PaginatedSearchAssetDtoV2
  ) {
    return await this.assetService.getPaginatedQueryResponseByStartItemWithRolesCheck(
      userId,
      queryParams
    )
  }

  @Post('/:assetId/purchase-option')
  @FirebaseTokenAuthGuard()
  @ApiBody({
    type: AddAssetPurchaseOptionDto
  })
  @ApiParam({ name: 'assetId', type: 'string', required: true })
  public async addAssetPurchaseOption(
    @Param('assetId') assetId: AssetId,
    @UserToken('user_id') userId: UserId,
    @Body() data: AddAssetPurchaseOptionDto
  ) {
    return await this.assetService.addAssetPurchaseOption(userId, assetId, data)
  }

  @Delete('/:assetId/purchase-option/:purchaseOptionId')
  @FirebaseTokenAuthGuard()
  @ApiBody({
    type: AddAssetPurchaseOptionDto
  })
  @ApiParam({ name: 'assetId', type: 'string', required: true })
  @ApiParam({ name: 'purchaseOptionId', type: 'string', required: true })
  public async deleteAssetPurchaseOption(
    @Param('assetId') assetId: AssetId,
    @Param('purchaseOptionId') purchaseOptionId: string,
    @UserToken('user_id') userId: UserId
  ) {
    return await this.assetService.deleteAssetPurchaseOption(
      userId,
      assetId,
      purchaseOptionId
    )
  }

  @Get('check-if-asset-copied/:assetId')
  @FirebaseTokenAuthGuard()
  @ApiParam({ name: 'assetId', type: 'string', required: true })
  public async checkIfAssetCopied(
    @UserToken('user_id') userId: UserId,
    @Param('assetId') assetId: AssetId
  ) {
    return await this.assetService.checkIfAssetCopiedByUser(assetId, userId)
  }

  @Post('copy-free-asset/:assetId')
  @ApiParam({ name: 'assetId', type: 'string', required: true })
  @FirebaseTokenAuthGuard()
  public async copyFreeAsset(
    @UserToken('user_id') userId: UserId,
    @Param('assetId') assetId: AssetId
  ) {
    return await this.assetService.copyFreeAssetToNewUserWithRolesCheck(
      userId,
      assetId
    )
  }

  @Get('download/:assetId')
  @ApiParam({ name: 'assetId', type: 'string', required: true })
  @FirebaseTokenAuthGuard()
  public async downloadAsset(
    @UserToken('user_id') userId: UserId,
    @Param('assetId') assetId: AssetId,
    @Res() res: Response
  ) {
    return await this.assetService.downloadAssetFileWithRoleChecks(
      userId,
      assetId,
      res
    )
  }

  @Get('/space/:spaceId')
  @FirebaseTokenAuthGuard()
  public async getAllAssetsBySpaceIdWithRolesCheck(
    @UserToken('user_id') userId: UserId,
    @Param('spaceId') spaceId: string
  ) {
    return await this.assetService.getAllAssetsBySpaceIdWithRolesCheck(
      spaceId,
      userId
    )
  }

  @Patch('pack/add-asset/:packId/:assetId')
  @FirebaseTokenAuthGuard()
  @ApiParam({ name: 'assetId', type: 'string', required: true })
  public async addAssetToPackWithRolesCheck(
    @UserToken('user_id') userId: UserId,
    @Param('packId') packId: string,
    @Param('assetId') assetId: string
  ) {
    return await this.assetService.addAssetToPackWithRolesCheck(
      packId,
      assetId,
      userId
    )
  }

  @Delete('pack/remove-asset/:packId/:assetId')
  @FirebaseTokenAuthGuard()
  @ApiParam({ name: 'assetId', type: 'string', required: true })
  public async deleteAssetFromPackWithRolesCheck(
    @UserToken('user_id') userId: UserId,
    @Param('packId') packId: string,
    @Param('assetId') assetId: string
  ) {
    return await this.assetService.deleteAssetFromPackWithRolesCheck(
      packId,
      assetId,
      userId
    )
  }
}
