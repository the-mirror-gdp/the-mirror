import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
  forwardRef
} from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'

import { ObjectId } from 'mongodb'
import { FilterQuery, Model, PipelineStage, Types } from 'mongoose'
import {
  PURCHASE_OPTION_TYPE,
  PurchaseOption,
  PurchaseOptionDocument
} from '../marketplace/purchase-option.subdocument.schema'
import { ROLE } from '../roles/models/role.enum'
import { RoleService } from '../roles/role.service'
import {
  SpaceObject,
  SpaceObjectDocument
} from '../space-object/space-object.schema'
import { FileUploadService } from '../util/file-upload/file-upload.service'
import {
  AssetId,
  UserId,
  aggregationMatchId
} from '../util/mongo-object-id-helpers'
import {
  IPaginatedResponse,
  ISort,
  SORT_DIRECTION
} from '../util/pagination/pagination.interface'
import {
  PaginationService,
  PopulateField
} from '../util/pagination/pagination.service'
import { AssetUsageApiResponse } from './asset.models'
import { Asset, AssetDocument } from './asset.schema'
import { AssetSearch } from './asset.search'
import {
  CreateAssetDto,
  CreateMapDto,
  CreateMaterialDto,
  CreateTextureDto
} from './dto/create-asset.dto'
import { PaginatedSearchAssetDtoV2 } from './dto/paginated-search-asset.dto'
import {
  AddAssetPurchaseOptionDto,
  UpdateAssetDto
} from './dto/update-asset.dto'
import { UploadAssetFileDto } from './dto/upload-asset-file.dto'
import { MapAsset, MapDocument } from './map.schema'
import { Material, MaterialDocument } from './material.schema'
import { Texture, TextureDocument } from './texture.schema'
import { ASSET_MANAGER_UID } from '../mirror-server-config/asset-manager-uid'
import { UserService } from '../user/user.service'
import { AggregationPipelines } from '../util/aggregation-pipelines/aggregation-pipelines'
import { TAG_TYPES } from '../tag/models/tag-types.enum'
import { AddTagToAssetDto } from './dto/add-tag-to-asset.dto'
import { ThirdPartyTagEntity } from '../tag/models/tags.schema'
import { isArray } from 'lodash'
import { isEnum, isMongoId } from 'class-validator'
import { AssetAnalyzingService } from '../util/file-analyzing/asset-analyzing.service'

export type FileUploadServiceType = FileUploadService
@Injectable()
export class AssetService {
  constructor(
    @InjectModel(Asset.name) private assetModel: Model<AssetDocument>,
    // Material is a discriminator (subclass in Mongoose) of Asset
    @InjectModel(Material.name) private materialModel: Model<MaterialDocument>,
    // Texture is a discriminator (subclass in Mongoose) of Asset
    @InjectModel(Texture.name) private textureModel: Model<TextureDocument>,
    // MapAsset is a discriminator (subclass in Mongoose) of Asset
    @InjectModel(MapAsset.name) private mapAssetModel: Model<MapDocument>,
    @InjectModel(SpaceObject.name)
    private spaceObjectModel: Model<SpaceObjectDocument>,
    private readonly assetSearch: AssetSearch,
    @Inject(forwardRef(() => FileUploadService))
    private readonly fileUploadService: FileUploadService,
    private readonly paginationService: PaginationService,
    private readonly roleService: RoleService,
    @InjectModel(PurchaseOption.name)
    private purchaseModel: Model<PurchaseOptionDocument>,
    @Inject(forwardRef(() => UserService))
    private readonly userService: UserService,
    private readonly assetAnalyzingService: AssetAnalyzingService
  ) {}

  public readonly standardPopulateFields: PopulateField[] = [
    { localField: 'creator', from: 'users', unwind: true }, // TODO: filter out properties for user so that not all are passed back
    { localField: 'owner', from: 'users', unwind: true },
    { localField: 'customData', from: 'customdatas', unwind: true }
  ]
  /**
   * @deprecated use aggregation pipelines instead
   */
  private _getStandardPopulateFieldsAsArray(): string[] {
    return this.standardPopulateFields.map((f) => f.localField)
  }

  // business logic: default role for new Assets
  private readonly _defaultRoleForNewAssets = ROLE.OBSERVER

  public async getRecentInstancedAssets(
    userId: UserId,
    searchAssetDto?: PaginatedSearchAssetDtoV2
  ) {
    const userRecents = await this.userService.getUserRecents(userId)
    const assetsIds = userRecents?.assets?.instanced || []

    const pipelineQuery: PipelineStage[] =
      AggregationPipelines.getPipelineForGetByIdOrdered(assetsIds)

    if (!searchAssetDto?.includeSoftDeleted) {
      pipelineQuery.push({
        $match: {
          isSoftDeleted: { $exists: false }
        }
      })
    }

    return await this.assetModel.aggregate(pipelineQuery)
  }

  public async addInstancedAssetToRecents(assetId: AssetId, userId: UserId) {
    const userRecents = await this.userService.getUserRecents(userId)
    const assets = userRecents?.assets?.instanced || []

    const existingAssetIndex = assets.indexOf(assetId)

    if (existingAssetIndex >= 0) {
      assets.splice(existingAssetIndex, 1)
    } else if (assets.length === 10) {
      assets.pop()
    }

    assets.unshift(assetId)

    await this.userService.updateUserRecentInstancedAssets(userId, assets)
  }

  /**
   * START Section: Create methods for different schemas
   */

  public async createAsset(
    dto: CreateAssetDto & { ownerId: string }
  ): Promise<AssetDocument> {
    const created = new this.assetModel({
      owner: dto.ownerId,
      creator: dto.ownerId, // default to ownerId since that owner is creating it.
      ...dto
    })
    // create role for this asset
    const role = await this.roleService.create({
      defaultRole: dto.defaultRole ?? this._defaultRoleForNewAssets,
      creator: dto.ownerId
    })
    created.role = role
    await created.save()

    // 2023-06-23 12:24:45 this is janky to do a find() now, but is a temp fix for a GD client request where we need to return the populated role after creating an asset. This will be fixed when role is changed from a separate collection to an embedded subdocument
    return await this.assetModel.findById(created.id).populate('role').exec()
  }

  public async createAssetWithUpload(
    dto: CreateAssetDto & { ownerId: string },
    file: Express.Multer.File
  ): Promise<AssetDocument> {
    try {
      const created = new this.assetModel({
        owner: dto.ownerId,
        creator: dto.ownerId, // default to ownerId since that owner is creating it.
        ...dto
      })

      const { publicUrl: currentFile } =
        await this.uploadAssetFilePublicWithRolesCheck({
          assetId: created.id,
          userId: dto.ownerId,
          file
        })

      created.currentFile = currentFile
      // create role for this asset
      const role = await this.roleService.create({
        defaultRole: dto.defaultRole ?? this._defaultRoleForNewAssets,
        creator: dto.ownerId
      })
      created.role = role
      await created.save()
      // 2023-06-23 12:24:45 this is janky to do a find() now, but is a temp fix for a GD client request where we need to return the populated role after creating an asset. This will be fixed when role is changed from a separate collection to an embedded subdocument
      return this.assetModel.findById(created.id).populate('role').exec()
    } catch (error: any) {
      throw error
    }
  }

  public copyAssetToNewUserAdmin(
    assetId: AssetId,
    newUserId: UserId
  ): Promise<AssetDocument> {
    return this.assetModel
      .findByIdAndUpdate(assetId, { owner: newUserId }, { new: true })
      .exec()
  }

  public async copyAssetToNewUserWithRolesCheck(
    assetId: AssetId,
    recievingUserId: UserId
  ): Promise<AssetDocument> {
    // check the role
    // TODO: how should we handle where a space is duplicatable, but the asset permissions aren't there?
    const check = await this.roleService.checkUserRoleForEntity(
      recievingUserId,
      assetId,
      ROLE.OWNER,
      this.assetModel
    )
    if (check === true) {
      return this.copyAssetToNewUserAdmin(assetId, recievingUserId)
    } else {
      throw new NotFoundException()
    }
  }

  // restore assets for space objects and return array of object with old and new asset ids
  public async restoreAssetsForSpaceObjects(assets: AssetDocument[]) {
    const newAssetsIds = []
    const bulkOps = []

    for (const asset of assets) {
      const newAssetId = new ObjectId()

      // if asset has a creator, use that, otherwise use owner (for old assets that don't have creator)
      const objCreator = asset.get('creator')
        ? asset.get('creator')
        : asset.get('owner')

      // if asset has a role, use that, otherwise create a new default role
      const role = asset.get('role')
        ? asset.get('role')
        : await this.roleService.create({
            defaultRole: this._defaultRoleForNewAssets,
            creator: asset.get('owner')
          })

      newAssetsIds.push({
        [asset.get('_id').toString()]: newAssetId.toString()
      })

      const bulkOp = {
        insertOne: {
          document: {
            ...Object.fromEntries(asset.toObject()),
            creator: objCreator,
            tags: asset.get('tags').length > 0 ? asset.get('tags') : undefined,
            role: role,
            _id: newAssetId
          }
        }
      }

      bulkOps.push(bulkOp)
    }

    await this.assetModel.bulkWrite(bulkOps)
    return newAssetsIds
  }

  /**
   * @description creates a Material Asset (subclass of Asset in Mongoose using a discriminator)
   */
  public async createMaterial(
    dto: CreateMaterialDto & { ownerId: string }
  ): Promise<MaterialDocument> {
    const created = new this.materialModel({
      owner: dto.ownerId,
      creator: dto.ownerId, // default to ownerId since that owner is creating it.
      ...dto
    })
    // create role for this asset
    const role = await this.roleService.create({
      defaultRole: dto.defaultRole ?? this._defaultRoleForNewAssets,
      creator: dto.ownerId
    })
    created.role = role
    await created.save()
    // 2023-06-23 12:24:45 this is janky to do a find() now, but is a temp fix for a GD client request where we need to return the populated role after creating an asset. This will be fixed when role is changed from a separate collection to an embedded subdocument
    return this.materialModel.findById(created.id).populate('role').exec()
  }

  /**
   * @description creates a Material Asset (subclass of Asset in Mongoose using a discriminator)
   */
  public async createMaterialWithUpload(
    dto: CreateMaterialDto & { ownerId: string },
    file: Express.Multer.File
  ): Promise<MaterialDocument> {
    try {
      const created = new this.materialModel({
        owner: dto.ownerId,
        creator: dto.ownerId, // default to ownerId since that owner is creating it.
        ...dto
      })

      const { publicUrl: currentFile } =
        await this.uploadAssetFilePublicWithRolesCheck({
          assetId: created.id,
          userId: dto.ownerId,
          file
        })

      created['currentFile'] = currentFile // should be dot notation, but need to figure out a way to tell Typescript that this is a union of Asset and Material

      // create role for this asset
      const role = await this.roleService.create({
        defaultRole: dto.defaultRole ?? this._defaultRoleForNewAssets,
        creator: dto.ownerId
      })

      created.role = role
      await created.save()
      // 2023-06-23 12:24:45 this is janky to do a find() now, but is a temp fix for a GD client request where we need to return the populated role after creating an asset. This will be fixed when role is changed from a separate collection to an embedded subdocument
      return this.materialModel.findById(created.id).populate('role').exec()
    } catch (error: any) {
      throw error
    }
  }

  /**
   * @description creates a Texture Asset (subclass of Asset in Mongoose using a discriminator)
   */
  public async createTexture(
    dto: CreateTextureDto & { ownerId: string }
  ): Promise<TextureDocument> {
    const created = new this.textureModel({
      owner: dto.ownerId,
      creator: dto.ownerId, // default to ownerId since that owner is creating it.
      ...dto
    })

    // create role for this asset
    const role = await this.roleService.create({
      defaultRole: dto.defaultRole ?? this._defaultRoleForNewAssets,
      creator: dto.ownerId
    })
    created.role = role

    await created.save()
    // 2023-06-23 12:24:45 this is janky to do a find() now, but is a temp fix for a GD client request where we need to return the populated role after creating an asset. This will be fixed when role is changed from a separate collection to an embedded subdocument
    return this.textureModel.findById(created.id).populate('role').exec()
  }

  /**
   * @description creates a Texture Asset (subclass of Asset in Mongoose using a discriminator)
   */
  public async createTextureWithUpload(
    dto: CreateTextureDto & { ownerId: string },
    file: Express.Multer.File
  ): Promise<TextureDocument> {
    try {
      const created = new this.textureModel({
        owner: dto.ownerId,
        creator: dto.ownerId, // default to ownerId since that owner is creating it.
        ...dto
      })

      const { publicUrl: currentFile } =
        await this.uploadAssetFilePublicWithRolesCheck({
          assetId: created.id,
          userId: dto.ownerId,
          file
        })

      created['currentFile'] = currentFile // should be dot notation, but need to figure out a way to tell Typescript that this is a union of Asset and Texture

      // create role for this asset
      const role = await this.roleService.create({
        defaultRole: dto.defaultRole ?? this._defaultRoleForNewAssets,
        creator: dto.ownerId
      })
      created.role = role

      await created.save()
      // 2023-06-23 12:24:45 this is janky to do a find() now, but is a temp fix for a GD client request where we need to return the populated role after creating an asset. This will be fixed when role is changed from a separate collection to an embedded subdocument
      return this.textureModel.findById(created.id).populate('role').exec()
    } catch (error: any) {
      throw error
    }
  }

  /**
   * @description creates a Material Asset (subclass of Asset in Mongoose using a discriminator)
   */
  public async createMap(
    dto: CreateMapDto & { ownerId: string }
  ): Promise<MapDocument> {
    const created = new this.mapAssetModel({
      owner: dto.ownerId,
      creator: dto.ownerId, // default to ownerId since that owner is creating it.
      ...dto
    })
    // create role for this asset
    const role = await this.roleService.create({
      defaultRole: dto.defaultRole ?? this._defaultRoleForNewAssets,
      creator: dto.ownerId
    })
    created.role = role
    await created.save()
    // 2023-06-23 12:24:45 this is janky to do a find() now, but is a temp fix for a GD client request where we need to return the populated role after creating an asset. This will be fixed when role is changed from a separate collection to an embedded subdocument
    return this.mapAssetModel.findById(created.id).populate('role').exec()
  }

  /**
   * @description creates a Material Asset (subclass of Asset in Mongoose using a discriminator)
   */
  public async createMapWithUpload(
    dto: CreateMapDto & { ownerId: string },
    file: Express.Multer.File
  ): Promise<MapDocument> {
    try {
      const created = new this.mapAssetModel({
        owner: dto.ownerId,
        creator: dto.ownerId, // default to ownerId since that owner is creating it.
        ...dto
      })

      const { publicUrl: currentFile } =
        await this.uploadAssetFilePublicWithRolesCheck({
          assetId: created.id,
          userId: dto.ownerId,
          file
        })

      created['currentFile'] = currentFile // should be dot notation, but need to figure out a way to tell Typescript that this is a union of Asset and Material

      // create role for this asset
      const role = await this.roleService.create({
        defaultRole: dto.defaultRole ?? this._defaultRoleForNewAssets,
        creator: dto.ownerId
      })

      created.role = role
      await created.save()
      // 2023-06-23 12:24:45 this is janky to do a find() now, but is a temp fix for a GD client request where we need to return the populated role after creating an asset. This will be fixed when role is changed from a separate collection to an embedded subdocument
      return this.mapAssetModel.findById(created.id).populate('role').exec()
    } catch (error: any) {
      throw error
    }
  }
  /**
   * END Section: Create functions for different schemas
   */

  /**
   * @description This is used ONLY for public assets that the user has designated as public. These are specific to the user and are not Mirror Library assets
   * @date 2022-06-18 16:00
   */

  public findAllPublicAssetsForUserWithRolesCheck(
    requestingUserId: UserId,
    targetUserId: UserId
  ): Promise<AssetDocument[]> {
    const pipeline = [
      ...this.roleService.getRoleCheckAggregationPipeline(
        requestingUserId,
        ROLE.DISCOVER
      ),
      { $match: { isSoftDeleted: { $exists: false } } },
      // get assets where the targetUser is an owner
      ...this.roleService.userIsOwnerAggregationPipeline(targetUserId)
    ]
    return this.assetModel.aggregate(pipeline).exec()
  }

  public async findManyAdmin(
    assetIds: Array<string>
  ): Promise<AssetDocument[]> {
    return await this.assetModel.find().where('_id').in(assetIds)
  }

  /**
   * Find self-created assets
   * TODO add pagination
   */
  public findAllAssetsForUserIncludingPrivate(
    userId: string,
    searchDto?: PaginatedSearchAssetDtoV2,
    sort: ISort = { updatedAt: SORT_DIRECTION.DESC }, // default: sort by updatedAt descending
    populate = false
  ): Promise<AssetDocument[]> {
    const filter: FilterQuery<any> = searchDto.includeSoftDeleted
      ? {
          $and: [{ owner: new ObjectId(userId) }]
        }
      : {
          $and: [
            { owner: new ObjectId(userId) },
            { isSoftDeleted: { $exists: false } }
          ]
        }

    const andFilter = AssetService.getSearchFilter(searchDto)
    if (andFilter.length > 0) {
      filter.$and.push(...andFilter)
    }

    const cursor = this.assetModel.find(filter).limit(1000).sort(sort)

    if (populate) {
      cursor.populate(this._getStandardPopulateFieldsAsArray())
    }

    return cursor.exec()
  }

  /**
   * Find public Mirror Library assets
   */
  public findMirrorPublicLibraryAssets(
    searchDto?: PaginatedSearchAssetDtoV2,
    sort: ISort = { updatedAt: SORT_DIRECTION.DESC }, // default: sort by updatedAt descending
    populate = false
  ): Promise<AssetDocument[]> {
    const filter: FilterQuery<any> = searchDto.includeSoftDeleted
      ? {
          $and: [{ mirrorPublicLibrary: true }]
        }
      : {
          $and: [
            { mirrorPublicLibrary: true },
            { isSoftDeleted: { $exists: false } }
          ]
        }

    const andFilter = AssetService.getSearchFilter(searchDto)
    if (andFilter.length > 0) {
      filter.$and.push(...andFilter)
    }

    const cursor = this.assetModel.find(filter).limit(1000).sort(sort)

    if (populate) {
      cursor.populate(this._getStandardPopulateFieldsAsArray())
    }

    return cursor.exec()
  }

  public findPaginatedMirrorAssetsWithRolesCheck(
    userId: UserId,
    searchDto?: PaginatedSearchAssetDtoV2,
    populate: PopulateField[] = [] // don't abuse, this is slow
  ): Promise<IPaginatedResponse<AssetDocument>> {
    const { page, perPage, startItem, numberOfItems, includeSoftDeleted } =
      searchDto

    const filter: FilterQuery<any> = includeSoftDeleted
      ? {
          mirrorPublicLibrary: true
        }
      : { mirrorPublicLibrary: true, isSoftDeleted: { $exists: false } }

    const andFilter = AssetService.getSearchFilter(searchDto)
    if (andFilter.length > 0) {
      filter.$and = andFilter
    }

    const sort =
      searchDto.sortKey && searchDto.sortDirection !== undefined
        ? {
            [searchDto.sortKey]: searchDto.sortDirection
          }
        : undefined
    if (
      startItem !== null &&
      startItem !== undefined &&
      numberOfItems !== null &&
      numberOfItems !== undefined
    )
      return this.paginationService.getPaginatedQueryResponseByStartItemWithRolesCheck(
        userId,
        this.assetModel,
        filter,
        ROLE.DISCOVER,
        { startItem, numberOfItems },
        populate ? this.standardPopulateFields : [],
        sort
      )
    return this.paginationService.getPaginatedQueryResponseWithRolesCheck(
      userId,
      this.assetModel,
      filter,
      ROLE.DISCOVER,
      { page, perPage },
      populate,
      sort
    )
  }

  public findPaginatedMyAssetsWithRolesCheck(
    userId: string,
    searchDto?: PaginatedSearchAssetDtoV2,
    populate = false // don't use, this is slow
  ): Promise<IPaginatedResponse<AssetDocument>> {
    const { page, perPage, startItem, numberOfItems } = searchDto

    const filter: FilterQuery<any> = searchDto.includeSoftDeleted
      ? {}
      : { isSoftDeleted: { $exists: false } }

    const andFilter = AssetService.getSearchFilter(searchDto)
    if (andFilter.length > 0) {
      filter.$and = andFilter
    }

    const sort =
      searchDto.sortKey && searchDto.sortDirection !== undefined
        ? {
            [searchDto.sortKey]: searchDto.sortDirection
          }
        : undefined

    if (
      startItem !== null &&
      startItem !== undefined &&
      numberOfItems !== null &&
      numberOfItems !== undefined
    )
      return this.paginationService.getPaginatedQueryResponseByStartItemWithRolesCheck(
        userId,
        this.assetModel,
        filter,
        ROLE.OWNER,
        { startItem, numberOfItems },
        populate ? this.standardPopulateFields : [],
        sort
      )

    return this.paginationService.getPaginatedQueryResponseWithRolesCheck(
      userId,
      this.assetModel,
      filter,
      ROLE.OWNER,
      { page, perPage },
      populate ? this.standardPopulateFields : [],
      sort
    )
  }

  public findAllAccessibleAssetsOfUser(
    userId: string,
    searchDto?: PaginatedSearchAssetDtoV2,
    populate = false // don't use, this is slow
  ): Promise<IPaginatedResponse<AssetDocument>> {
    const { page, perPage, startItem, numberOfItems } = searchDto

    const filter: FilterQuery<any> = searchDto?.includeSoftDeleted
      ? {
          $or: [{ mirrorPublicLibrary: true }, { owner: new ObjectId(userId) }]
        }
      : {
          $or: [{ mirrorPublicLibrary: true }, { owner: new ObjectId(userId) }],
          isSoftDeleted: { $exists: false }
        }

    const andFilter = AssetService.getSearchFilter(searchDto)
    if (andFilter.length > 0) {
      filter.$and = andFilter
    }

    const sort =
      searchDto.sortKey && searchDto.sortDirection !== undefined
        ? {
            [searchDto.sortKey]: searchDto.sortDirection
          }
        : undefined
    if (
      startItem !== null &&
      startItem !== undefined &&
      numberOfItems !== null &&
      numberOfItems !== undefined
    )
      return this.paginationService.getPaginatedQueryResponseByStartItemWithRolesCheck(
        userId,
        this.assetModel,
        filter,
        ROLE.DISCOVER,
        { startItem, numberOfItems },
        populate ? this.standardPopulateFields : [],
        sort
      )
    return this.paginationService.getPaginatedQueryResponseWithRolesCheck(
      userId,
      this.assetModel,
      filter,
      ROLE.DISCOVER,
      { page, perPage },
      populate ? this.standardPopulateFields : [],
      sort
    )
  }

  /**
   * @description This is a helper method to get 1. Recently created/updated Assets and 2. The Assets of recently-created SpaceObjects
   * The intent is for a user to call this to get ITS OWN recent assets.
   * This should not be called for other users.
   * @date 2023-04-26 14:38
   */
  public async findRecentAssetsOfUserWithRolesCheck(
    userId: string,
    includeSoftDeleted = false,
    limit = 20,
    populate = false // don't use, this is slow
  ): Promise<AssetDocument[]> {
    // find recently updated spaceobjects owned by the user and get the asset IDs
    const spaceObjects: SpaceObjectDocument[] = (
      await this.paginationService.getPaginatedQueryResponseWithRolesCheck(
        userId,
        this.spaceObjectModel,
        {},
        ROLE.OWNER,
        { perPage: 500 } // don't use the above limit here since this is for SpaceObject, not Asset
      )
    ).data

    // get all the asset IDs from these SpaceObjects
    const spaceObjectAssetIds = spaceObjects
      .filter((spaceObject) => spaceObject.asset)
      .map((spaceObject) => spaceObject.asset.toString())

    const filter: FilterQuery<any> = {
      $or: [
        includeSoftDeleted
          ? { mirrorPublicLibrary: true }
          : { mirrorPublicLibrary: true, isSoftDeleted: { $exists: false } },
        // note that both are here since objectId vs string inconsistency currently
        { creator: userId }, // TODO this should really be owner, but we need to fix the pipeline order. If role isnt populated, we can't check for role.users[userId]
        { creator: new ObjectId(userId) }, // TODO this should really be owner, but we need to fix the pipeline order. If role isnt populated, we can't check for role.users[userId]
        { _id: { $in: spaceObjectAssetIds } }
      ]
    }

    const page = 1
    const perPage = limit
    const assetsPaginated =
      await this.paginationService.getPaginatedQueryResponseWithRolesCheck(
        userId,
        this.assetModel,
        filter,
        ROLE.DISCOVER, // note that DISCOVER is for any asset that can be used, but above, we check for ROLE.OWNER so that this user's assets show up
        { page, perPage },
        populate ? this.standardPopulateFields : []
      )

    return assetsPaginated.data
  }

  /**
   * @description Future note: this was implemented incorrectly. Static methods don't really have a use in NestJS since services are already singletons.
   * @date 2023-04-23 01:04
   */
  private static getSearchFilter(
    searchDto: PaginatedSearchAssetDtoV2
  ): Array<any> {
    const { search, field, type, tagType, tag, assetType, assetTypes } =
      searchDto

    const andFilter = []
    //override type with assetType if it exists (deprecating type to use assetType instead)
    let assetTypesAll: string[] = []
    if (assetType) {
      assetTypesAll.push(assetType.toUpperCase())
    } else if (type) {
      assetTypesAll.push(type.toUpperCase())
    }
    if (assetTypes) {
      assetTypesAll = assetTypesAll.concat(assetTypes)
    }
    if (assetTypesAll.length > 0) {
      andFilter.push({ assetType: { $in: assetTypesAll } })
    }

    if (field && search) {
      andFilter.push({
        $or: [
          { [field]: new RegExp(search, 'i') },
          { 'tags.search': new RegExp(search, 'i') }
        ]
      })
    }

    if (tag && tagType) {
      const tagSearchKey =
        tagType === TAG_TYPES.THIRD_PARTY
          ? `tags.${tagType}.name`
          : `tags.${tagType}`

      const tagFilter = { $or: tag.map((t) => ({ [tagSearchKey]: t })) }
      andFilter.push(tagFilter)
    }

    return andFilter
  }

  public findOneAdmin(id: AssetId): Promise<AssetDocument> {
    return this.assetModel
      .findById(id)
      .populate(this._getStandardPopulateFieldsAsArray())
      .exec()
  }

  public async findOneWithRolesCheck(
    userId: UserId,
    assetId: AssetId
  ): Promise<AssetDocument> {
    const pipeline = [
      { $match: { isSoftDeleted: { $exists: false } } },
      aggregationMatchId(assetId),
      ...this.roleService.getRoleCheckAggregationPipeline(userId, ROLE.DISCOVER)
    ]

    const [asset]: AssetDocument[] = await this.assetModel
      .aggregate(pipeline)
      .exec()

    if (asset) {
      return asset
    } else {
      throw new NotFoundException()
    }
  }

  public async findAssetUsageWithRolesCheck(
    userId: UserId,
    assetId: AssetId
  ): Promise<AssetUsageApiResponse> {
    const pipeline = [
      aggregationMatchId(assetId),
      ...this.roleService.getRoleCheckAggregationPipeline(userId, ROLE.DISCOVER)
    ]
    const data = await this.assetModel.aggregate(pipeline).exec()
    if (data && data[0]) {
      // find all space objects that use this asset
      const spaceKeys = await this.spaceObjectModel
        .find({
          asset: assetId
        })
        .distinct('space')
        .exec()

      return {
        numberOfSpacesAssetUsedIn: spaceKeys.length
      }
    } else {
      throw new NotFoundException()
    }
  }

  public updateOneAdmin(
    id: string,
    updateAssetDto: UpdateAssetDto
  ): Promise<AssetDocument> {
    return this.assetModel
      .findByIdAndUpdate(id, updateAssetDto, { new: true })
      .populate(this._getStandardPopulateFieldsAsArray())
      .exec()
  }

  public async updateOneWithRolesCheck(
    userId: string,
    assetId: AssetId,
    updateAssetDto: UpdateAssetDto
  ): Promise<AssetDocument | MapDocument | TextureDocument | MaterialDocument> {
    // check the role
    const roleCheck = await this.roleService.checkUserRoleForEntity(
      userId,
      assetId,
      ROLE.MANAGER, // business logic: manager role is needed to update an asset
      this.assetModel
    )

    const softDeletedCheck = await this.isAssetSoftDeleted(assetId)

    if (roleCheck && !softDeletedCheck) {
      // do === check here to avoid accidentally truthy since checkUserRoleForEntity returns a promise

      // Mongoose doesn't know about the discriminator classes and thus won't work with properties of the discriminator if the discriminator model isn't used.
      switch (updateAssetDto.__t) {
        case 'MapAsset':
          return this.mapAssetModel
            .findByIdAndUpdate(assetId, updateAssetDto, { new: true })
            .populate(this._getStandardPopulateFieldsAsArray())
            .exec()
        case 'Material':
          return this.materialModel
            .findByIdAndUpdate(assetId, updateAssetDto, { new: true })
            .populate(this._getStandardPopulateFieldsAsArray())
            .exec()
        case 'Texture':
          return this.textureModel
            .findByIdAndUpdate(assetId, updateAssetDto, { new: true })
            .populate(this._getStandardPopulateFieldsAsArray())
            .exec()

        default:
          return this.assetModel
            .findByIdAndUpdate(assetId, updateAssetDto, { new: true })
            .populate(this._getStandardPopulateFieldsAsArray())
            .exec()
      }
    } else {
      throw new NotFoundException()
    }
  }

  public removeOneAdmin(id: string): Promise<AssetDocument> {
    if (!Types.ObjectId.isValid(id)) {
      throw new BadRequestException('ID is not a valid Mongo ObjectID')
    }
    return this.assetModel
      .findOneAndDelete({ _id: id }, { new: true })
      .exec()
      .then((data) => {
        if (data) {
          return data
        } else {
          throw new NotFoundException()
        }
      })
  }

  public async removeOneWithRolesCheck(
    userId: UserId,
    assetId: AssetId
  ): Promise<AssetDocument> {
    if (!Types.ObjectId.isValid(assetId)) {
      throw new BadRequestException('ID is not a valid Mongo ObjectID')
    }

    // check the role
    const roleCheck = await this.roleService.checkUserRoleForEntity(
      userId,
      assetId,
      ROLE.MANAGER, // business logic: manager role is needed to delete an asset
      this.assetModel
    )

    if (!roleCheck) {
      throw new NotFoundException('Asset not found')
    }

    const isAssetCanBeDeleted = await this._isAssetCanBeDeleted(assetId)

    if (!isAssetCanBeDeleted) {
      throw new ConflictException(
        'The asset cannot be deleted as it is referenced by one or more space objects'
      )
    }

    return await this.assetModel.findOneAndUpdate(
      { _id: assetId },
      { isSoftDeleted: true, softDeletedAt: new Date() },
      { new: true }
    )
  }

  /** TODO add filter by public here
   * */
  public searchAssetsPublic(
    query: PaginatedSearchAssetDtoV2,
    populate = false
  ): Promise<AssetDocument[]> {
    const filter: FilterQuery<any> = query.includeSoftDeleted
      ? {
          $and: [{ mirrorPublicLibrary: true }]
        }
      : {
          $and: [
            { mirrorPublicLibrary: true },
            { isSoftDeleted: { $exists: false } }
          ]
        }

    const andFilter = AssetService.getSearchFilter(query)
    if (andFilter.length > 0) {
      filter.$and.push(...andFilter)
    }

    const cursor = this.assetModel.find(filter)

    if (populate) {
      cursor.populate(this._getStandardPopulateFieldsAsArray())
    }

    return cursor.exec()
  }

  public async uploadAssetFilePublicWithRolesCheck({
    userId,
    assetId,
    file
  }: UploadAssetFileDto) {
    // check the role
    const check = await this.roleService.checkUserRoleForEntity(
      userId,
      assetId,
      ROLE.MANAGER,
      this.assetModel
    )

    if (!check) {
      throw new NotFoundException('Asset not found')
    }

    const fileId = new Types.ObjectId()
    const path = `${userId}/assets/${assetId}/files/${fileId.toString()}`

    const isAssetEquipable = await this.assetAnalyzingService.isAssetEquipable(
      file
    )

    const fileUploadResult = await this.fileUploadService.uploadFilePublic({
      file,
      path
    })

    if (isAssetEquipable) {
      await this.assetModel.updateOne({ _id: assetId }, { isEquipable: true })
    }

    return fileUploadResult
  }

  public async uploadAssetFileWithRolesCheck({
    assetId,
    userId,
    file
  }: UploadAssetFileDto) {
    // check the role
    const check = await this.roleService.checkUserRoleForEntity(
      userId,
      assetId,
      ROLE.MANAGER,
      this.assetModel
    )

    if (!check) {
      throw new NotFoundException('Asset not found')
    }

    const fileId = new Types.ObjectId()
    const path = `${userId}/assets/${assetId}/files/${fileId.toString()}`

    const isAssetEquipable = await this.assetAnalyzingService.isAssetEquipable(
      file
    )

    const fileUploadResult = await this.fileUploadService.uploadFilePrivate({
      file,
      path
    })

    if (isAssetEquipable) {
      await this.assetModel.updateOne({ _id: assetId }, { isEquipable: true })
    }

    return fileUploadResult
  }

  public async uploadAssetThumbnailWithRolesCheck({
    assetId,
    userId,
    file
  }: UploadAssetFileDto) {
    // check the role
    let check = await this.roleService.checkUserRoleForEntity(
      userId,
      assetId,
      ROLE.MANAGER,
      this.assetModel
    )
    // !! Special exception for thumbnails: if the account is EngAssetManager, then allow
    if (userId === ASSET_MANAGER_UID) {
      check = true
    }
    if (check === true) {
      const path = `${userId}/assets/${assetId}/images/thumbnail`
      return this.fileUploadService.uploadThumbnail({ file, path })
    } else {
      throw new NotFoundException()
    }
  }

  public async getPaginatedQueryResponseByStartItemWithRolesCheck(
    userId: string,
    searchDto?: PaginatedSearchAssetDtoV2,
    populate = false // don't use, this is slowqueryParams: GetAssetDto
  ) {
    const { startItem, numberOfItems } = searchDto

    const filter: FilterQuery<any> = searchDto.includeSoftDeleted
      ? {}
      : { isSoftDeleted: { $exists: false } }

    const andFilter = AssetService.getSearchFilter(searchDto)
    if (andFilter.length > 0) {
      filter.$and = andFilter
    }

    return await this.paginationService.getPaginatedQueryResponseByStartItemWithRolesCheck(
      userId,
      this.assetModel,
      filter,
      ROLE.OWNER,
      { startItem, numberOfItems },
      populate ? this.standardPopulateFields : []
    )
  }

  public async addAssetPurchaseOption(
    userId: string,
    assetId: string,
    data: AddAssetPurchaseOptionDto
  ) {
    // check the role
    const check = await this.roleService.checkUserRoleForEntity(
      userId,
      assetId,
      ROLE.OWNER, // business logic: manager role is needed to delete an asset
      this.assetModel
    )

    if (check === true) {
      // Check the license type.
      if (data.licenseType === PURCHASE_OPTION_TYPE.MIRROR_REV_SHARE) {
        // Check MIRROR_REV_SHARE already exist or not
        const checkPurchaseOptionExist = await this.assetModel.findOne({
          _id: assetId,
          purchaseOptions: { $elemMatch: { licenseType: data.licenseType } }
        })
        // Throw bad request exception if exist
        if (checkPurchaseOptionExist) {
          throw new BadRequestException(
            'This asset is already set for RevShare'
          )
        }
      }
    } else {
      throw new NotFoundException()
    }

    const createdPurchaseOption = new this.purchaseModel(data)
    await createdPurchaseOption.save()
    return await this.assetModel.findByIdAndUpdate(
      assetId,
      { $push: { purchaseOptions: createdPurchaseOption } },
      { new: true }
    )
  }

  public async deleteAssetPurchaseOption(
    userId: string,
    assetId: string,
    purchaseOptionId: string
  ) {
    // check the role
    const check = await this.roleService.checkUserRoleForEntity(
      userId,
      assetId,
      ROLE.OWNER, // business logic: manager role is needed to delete an asset
      this.assetModel
    )

    if (check === true) {
      return await this.assetModel.findByIdAndUpdate(
        assetId,
        { $pull: { purchaseOptions: { _id: purchaseOptionId } } },
        { new: true }
      )
    } else {
      throw new NotFoundException()
    }
  }

  public async getAssetsByTag(
    searchDto: PaginatedSearchAssetDtoV2,
    userId: UserId = undefined
  ) {
    const { page, perPage, includeSoftDeleted } = searchDto
    const matchFilter: FilterQuery<Asset> = {}
    const andFilter = AssetService.getSearchFilter(searchDto)

    if (!includeSoftDeleted) {
      andFilter.push({ isSoftDeleted: { $exists: false } })
    }

    if (andFilter.length > 0) {
      matchFilter.$and = andFilter
    }

    const sort =
      searchDto.sortKey && searchDto.sortDirection !== undefined
        ? {
            [searchDto.sortKey]: searchDto.sortDirection
          }
        : undefined

    const paginatedAssetResult =
      await this.paginationService.getPaginatedQueryResponseWithRolesCheck(
        userId,
        this.assetModel,
        matchFilter,
        ROLE.OBSERVER,
        { page, perPage },
        [],
        sort
      )

    return paginatedAssetResult
  }

  public async addTagToAssetsWithRoleChecks(
    userId: UserId,
    addTagToAssetDto: AddTagToAssetDto
  ) {
    const { assetId, tagName, tagType, thirdPartySourceHomePageUrl } =
      addTagToAssetDto

    const ownerRoleCheck = await this.roleService.checkUserRoleForEntity(
      userId,
      assetId,
      ROLE.OWNER,
      this.assetModel
    )

    if (!ownerRoleCheck) {
      throw new NotFoundException('Asset not found')
    }

    if (thirdPartySourceHomePageUrl && tagType === TAG_TYPES.THIRD_PARTY) {
      const tags = await this.getAssetTagsByType(assetId, tagType)

      const newThirdPartyTag = new ThirdPartyTagEntity(
        tagName,
        thirdPartySourceHomePageUrl
      )

      return await this._updateAssetThirdPartyTags(
        assetId,
        tags as ThirdPartyTagEntity[],
        newThirdPartyTag
      )
    }

    const tags = (await this.getAssetTagsByType(assetId, tagType)) as string[]

    if (tags.length === 15) {
      throw new BadRequestException(`Asset already has 15 ${tagType} tags`)
    }

    if (tags.includes(tagName)) {
      throw new ConflictException(`Asset already has this ${tagType} tag`)
    }

    tags.push(tagName)
    await this._updateAssetTagsByType(assetId, tagType, tags)

    return tagName
  }

  public async deleteTagFromAssetWithRoleChecks(
    userId: UserId,
    assetId: AssetId,
    tagName: string,
    tagType: TAG_TYPES
  ) {
    if (!isMongoId(assetId)) {
      throw new BadRequestException('Id is not a valid Mongo ObjectId')
    }

    if (!isEnum(tagType, TAG_TYPES)) {
      throw new BadRequestException('Unknown tag type')
    }

    const ownerRoleCheck = await this.roleService.checkUserRoleForEntity(
      userId,
      assetId,
      ROLE.OWNER,
      this.assetModel
    )

    if (!ownerRoleCheck) {
      throw new NotFoundException('Asset not found')
    }

    const tagKey = `tags.${tagType}`
    const valueToMatch =
      tagType === TAG_TYPES.THIRD_PARTY ? { name: tagName } : tagName

    await this.assetModel
      .updateOne({ _id: assetId }, { $pull: { [tagKey]: valueToMatch } })
      .exec()

    return { assetId, tagType, tagName }
  }

  public async getAssetTagsByType(assetId: AssetId, tagType: TAG_TYPES) {
    const asset = await this.assetModel
      .findOne({ _id: assetId })
      .select('tags')
      .exec()

    if (!asset) {
      throw new NotFoundException('Asset not found')
    }

    return asset?.tags?.[tagType] || []
  }

  public async updateAssetTagsByTypeWithRoleChecks(
    userId: UserId,
    assetId: AssetId,
    tagType: TAG_TYPES,
    tags: string[] | ThirdPartyTagEntity[]
  ) {
    const ownerRoleCheck = await this.roleService.checkUserRoleForEntity(
      userId,
      assetId,
      ROLE.OWNER,
      this.assetModel
    )

    if (!ownerRoleCheck) {
      throw new NotFoundException('Asset not found')
    }

    return await this._updateAssetTagsByType(assetId, tagType, tags)
  }

  private async _updateAssetTagsByType(
    assetId: AssetId,
    tagType: TAG_TYPES,
    tags: string[] | ThirdPartyTagEntity[]
  ) {
    const searchKey = `tags.${tagType}`

    await this.assetModel
      .updateOne({ _id: assetId }, { $set: { [searchKey]: tags } })
      .exec()

    return tags
  }

  private async _updateAssetThirdPartyTags(
    assetId: AssetId,
    thirdPartyTags: ThirdPartyTagEntity[],
    newThirdPartyTag: ThirdPartyTagEntity
  ) {
    if (thirdPartyTags.length === 15) {
      throw new BadRequestException(
        `Space already has 15 ${TAG_TYPES.THIRD_PARTY} tags`
      )
    }

    const existingTag = thirdPartyTags.find(
      (tag) => tag.name === newThirdPartyTag.name
    )

    if (existingTag) {
      throw new ConflictException(`Space already has this thirdParty tag`)
    }

    thirdPartyTags.push(newThirdPartyTag)

    await this._updateAssetTagsByType(
      assetId,
      TAG_TYPES.THIRD_PARTY,
      thirdPartyTags
    )

    return newThirdPartyTag
  }

  /**
   * @description This is a helper method to determine if an asset can be deleted.
   * (Check if there are space objects using this asset in existing spaces.)
   *
   * @date 2023-11-21
   */
  private async _isAssetCanBeDeleted(assetId: AssetId) {
    const pipeline: PipelineStage[] = [
      { $match: { asset: new ObjectId(assetId) } },
      {
        $lookup: {
          from: 'spaces',
          localField: 'space',
          foreignField: '_id',
          as: 'spaceInfo'
        }
      },
      {
        $match: {
          spaceInfo: { $ne: [] }
        }
      },
      {
        $count: 'spaceObjectsCount'
      },
      {
        $project: {
          _id: 0,
          spaceObjectsCount: 1
        }
      }
    ]

    const [aggregationResult]: { spaceObjectsCount: number }[] =
      await this.spaceObjectModel.aggregate(pipeline).exec()

    return !aggregationResult?.spaceObjectsCount
  }

  /**
   * @description This method is used to undo soft delete of an asset.
   * (Remove isSoftDeleted and softDeletedAt fields from the asset document)
   *
   * @date 2023-11-23
   */
  public async undoAssetSoftDelete(userId: UserId, assetId: AssetId) {
    if (!isMongoId(assetId)) {
      throw new BadRequestException('AssetId is not a valid Mongo ObjectID')
    }

    const roleCheck = await this.roleService.checkUserRoleForEntity(
      userId,
      assetId,
      ROLE.MANAGER,
      this.assetModel
    )

    if (!roleCheck) {
      throw new NotFoundException('Asset not found')
    }

    await this.assetModel.updateOne(
      { _id: new ObjectId(assetId) },
      { $unset: { isSoftDeleted: 1, softDeletedAt: 1 } }
    )

    return assetId
  }

  public async isAssetSoftDeleted(assetId: AssetId) {
    const asset = await this.assetModel.aggregate([
      {
        $match: { _id: new ObjectId(assetId), isSoftDeleted: true }
      },
      {
        $project: {
          _id: 1
        }
      }
    ])

    return asset.length > 0
  }
}

export type AssetServiceType = AssetService // this is used to solve circular dependency issue with swc https://github.com/swc-project/swc/issues/5047#issuecomment-1302444311
