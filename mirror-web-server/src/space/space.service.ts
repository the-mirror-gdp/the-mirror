import { Environment } from './../environment/environment.schema'
import {
  UserId,
  SpaceId,
  SpaceVersionId
} from './../util/mongo-object-id-helpers'
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  forwardRef,
  HttpException,
  Inject,
  Injectable,
  InternalServerErrorException,
  Logger,
  NotFoundException
} from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { isArray, isNil, omit } from 'lodash'
import { ObjectId } from 'mongodb'
import {
  FilterQuery,
  Model,
  PipelineStage,
  SortOrder,
  Types,
  isValidObjectId
} from 'mongoose'
import { AssetService } from '../asset/asset.service'
import { CustomDataService } from '../custom-data/custom-data.service'
import { EnvironmentService } from '../environment/environment.service'
import { ROLE } from '../roles/models/role.enum'
import { IRoleConsumer } from '../roles/role-consumer.interface'
import { RoleService } from '../roles/role.service'
import {
  SpaceObjectService,
  SpaceObjectServiceType
} from '../space-object/space-object.service'
import { TerrainService } from '../terrain/terrain.service'
import { FileUploadService } from '../util/file-upload/file-upload.service'
import { getPublicPropertiesForMongooseQuery } from '../util/getPublicDataClassProperties'
import { CreateSpaceDto } from './dto/create-space.dto'
import { UpdateSpaceDto } from './dto/update-space.dto'
import { UploadSpaceFilesDto } from './dto/upload-space-files.dto'
import { SpaceVersion, SpaceVersionDocument } from './space-version.schema'
import { Space, SpaceDocument, SpacePublicData } from './space.schema'
import { SpaceSearch } from './space.search'
import {
  IPaginatedResponse,
  IPaginationPipeline,
  SORT_DIRECTION
} from '../util/pagination/pagination.interface'
import {
  PaginationService,
  PopulateField
} from '../util/pagination/pagination.service'
import { PaginatedSearchSpaceDto } from './dto/paginated-search-space.dto'
import { SpaceVariablesDataService } from '../space-variable/space-variables-data.service'
import { Role, RoleDocument } from '../roles/models/role.schema'
import { CustomData } from '../custom-data/models/custom-data.schema'
import { SpaceVariablesData } from '../space-variable/models/space-variables-data.schema'
import { Tag } from '../tag/models/tag.schema'
import { User } from '../user/user.schema'
import { MirrorServerConfigService } from '../mirror-server-config/mirror-server-config.service'
import { Cron } from '@nestjs/schedule'
import {
  SpaceObject,
  SpaceObjectDocument
} from '../space-object/space-object.schema'
import { ZoneService } from '../zone/zone.service'
import { UserService } from '../user/user.service'
import { AggregationPipelines } from '../util/aggregation-pipelines/aggregation-pipelines'

import { AddTagToSpaceDto } from './dto/add-tag-to-space.dto'
import { BUILD_PERMISSIONS } from '../option-sets/build-permissions'
import { TAG_TYPES } from '../tag/models/tag-types.enum'
import { ThirdPartyTagEntity } from '../tag/models/tags.schema'
import { IZonePopulatedUsers } from '../zone/abstractions/populated-users.interface'
import { isMongoId, isEnum } from 'class-validator'
import { SPACE_EVENTS } from './events/space.events'
import { CHANNELS } from '../redis/redis.channels'
import { RedisPubSubService } from '../redis/redis-pub-sub.service'
import { getUserStatsAndUsersPresentAggregationPipeline } from './aggregation-pipelines/get-user-stats-and-user-present-population.pipeline'
import { getPopularSpacesAggregationPipeline } from './aggregation-pipelines/get-popular-spaces.pipeline'
import { PAGINATION_STRATEGY } from '../util/pagination/pagination-strategy.enum'
import {
  PaginationData,
  PaginationDataByStartItem
} from '../util/pagination/pagination-data'
import { MirrorDBService } from '../mirror-db/mirror-db.service'
import { ScriptEntityService } from '../script-entity/script-entity.service'
import { RemixSpaceDto } from './dto/remix-space-dto'

/**
 * @description This mirrors _standardPopulateFields and should be kept up to date with it. However, this "populate a lot of things" approach is deprecated
 * @deprecated better to only minimally populate things and use the exact type for that, such as SpaceWithPopulatedRole
 * @date 2023-06-26 14:40
 */
export type SpaceWithStandardPopulatedProperties = SpaceDocument &
  SpaceWithPopulatedCustomData &
  SpaceWithPopulatedSpaceVariables &
  SpaceWithPopulatedEnvironment &
  SpaceWithPopulatedTagsV2 &
  SpaceWithPopulatedCreator & {
    publicBuildPermissions: BUILD_PERMISSIONS
  } & SpaceWithPopulatedUserActionsStats &
  SpaceWithPopulatedUsersPresent

export type SpaceWithPopulatedRole = SpaceDocument & {
  role: Role
}

export type SpaceWithPopulatedCustomData = SpaceDocument & {
  customData: CustomData
}

export type SpaceWithPopulatedSpaceVariables = SpaceDocument & {
  spaceVariablesData: SpaceVariablesData
}

export type SpaceWithPopulatedEnvironment = SpaceDocument & {
  environment: Environment
}

export type SpaceWithPopulatedTagsV2 = SpaceDocument & {
  tagsV2: Tag[]
}

export type SpaceWithPopulatedCreator = SpaceDocument & {
  creator: User
}

export type SpaceWithPopulatedUserActionsStats = SpaceDocument & {
  AVG_RATING: number
  COUNT_LIKE: number
  COUNT_FOLLOW: number
  COUNT_SAVES: number
  COUNT_RATING: number
}

export type SpaceWithPopulatedUsersPresent = SpaceDocument & IZonePopulatedUsers

@Injectable()
export class SpaceService implements IRoleConsumer {
  constructor(
    private readonly logger: Logger,
    @InjectModel(Space.name) private spaceModel: Model<SpaceDocument>,
    @InjectModel(SpaceVersion.name)
    private spaceVersionModel: Model<SpaceVersionDocument>,
    public readonly spaceSearch: SpaceSearch,
    private readonly fileUploadService: FileUploadService,
    @Inject(forwardRef(() => SpaceObjectService))
    private readonly spaceObjectService: SpaceObjectServiceType, // circular dependency fix. The suffixed -Type type is used to solve circular dependency issue with swc https://github.com/swc-project/swc/issues/5047#issuecomment-1302444311
    private readonly terrainService: TerrainService,
    private readonly assetService: AssetService,
    private readonly environmentService: EnvironmentService,
    private readonly roleService: RoleService,
    private readonly customDataService: CustomDataService,
    private readonly spaceVariablesDataService: SpaceVariablesDataService,
    private readonly paginationService: PaginationService,
    @InjectModel(Role.name)
    private roleModel: Model<RoleDocument>,
    private readonly mirrorServerConfigService: MirrorServerConfigService,
    @InjectModel(SpaceObject.name)
    private spaceObjectModel: Model<SpaceObjectDocument>,
    @Inject(forwardRef(() => ZoneService))
    private readonly zoneService: ZoneService,
    private readonly userService: UserService,
    private readonly redisPubSubService: RedisPubSubService,
    private readonly mirrorDBService: MirrorDBService,
    private readonly scriptEntityService: ScriptEntityService
  ) {
    this._subscribeToSpaceSchemaChanges()
  }
  /**
   * @deprecated This "populate a lot of things" approach is deprecated for reducing the amount of lookups across collections
   * @date 2023-06-26 14:41
   */
  private _standardPopulateFields = [
    { localField: 'creator', from: 'users', unwind: true },
    { localField: 'environment', from: 'environments', unwind: true },
    { localField: 'customData', from: 'customdatas', unwind: true },
    {
      localField: 'spaceVariablesData',
      from: 'spacevariablesdatas',
      unwind: true
    }
  ]
  private _getStandardPopulateFieldsAsArray(): string[] {
    return this._standardPopulateFields.map((f) => f.localField)
  }

  private _getDefaultRoleByPublicBuildPermissions(
    publicBuildPermissions: BUILD_PERMISSIONS
  ) {
    switch (publicBuildPermissions) {
      case BUILD_PERMISSIONS.PRIVATE:
        return ROLE.NO_ROLE
      case BUILD_PERMISSIONS.OBSERVER:
        return ROLE.OBSERVER
      case BUILD_PERMISSIONS.CONTRIBUTOR:
        return ROLE.CONTRIBUTOR
      case BUILD_PERMISSIONS.MANAGER:
        return ROLE.MANAGER
      default:
        return ROLE.NO_ROLE // default to no role
    }
  }

  /**
   * START Section: CREATE spaces
   */
  public async createOneWithRolesCheck(
    userId: string,
    createSpaceDto: CreateSpaceDto & {
      owner: string
      creator: string
    }
  ): Promise<SpaceDocument> {
    if (this.canCreateWithRolesCheck(userId)) {
      const createdSpace = new this.spaceModel(createSpaceDto)

      //add the creator to the previousUsers list
      createdSpace.previousUsers = [new ObjectId(createSpaceDto.creator)]

      // Create the environment
      try {
        const environment = await this.environmentService.create()
        createdSpace.environment = environment.id
      } catch (error: any) {
        throw new HttpException('Error generating world environment', 500)
      }

      // Create the customData
      try {
        const customData = await this.customDataService.createCustomData(
          userId,
          {
            data: {}
          }
        )
        createdSpace.customData = customData.id
      } catch (error: any) {
        throw new HttpException('Error creating customData', 500)
      }

      // Create the spaceVariablesData
      try {
        const spaceVariablesData =
          await this.spaceVariablesDataService.createSpaceVariablesDataDocument(
            {
              data: {}
            }
          )
        createdSpace.spaceVariablesData = spaceVariablesData.id
      } catch (error: any) {
        throw new HttpException('Error creating spaceVariablesData', 500)
      }

      // Create the role
      try {
        const role = await this.roleService.create({
          defaultRole: this._getDefaultRoleByPublicBuildPermissions(
            createSpaceDto.publicBuildPermissions
          ),
          creator: createSpaceDto.creator,
          users: {
            ...createSpaceDto.users,
            // set the creator as an owner
            [userId]: ROLE.OWNER
          },
          userGroups: {
            ...createSpaceDto.userGroups
          }
        })
        createdSpace.publicBuildPermissions =
          createSpaceDto.publicBuildPermissions || BUILD_PERMISSIONS.PRIVATE // default to private
        createdSpace.role = role

        createdSpace.maxUsers = createSpaceDto.maxUsers || 24
      } catch (error: any) {
        throw new HttpException('Error creating Roles document', 500)
      }

      const newMirrorDBRecord = await this.mirrorDBService.createNewMirrorDB(
        createdSpace._id
      )

      createdSpace.mirrorDBRecord = newMirrorDBRecord._id

      const savedSpace = await createdSpace.save()

      return savedSpace
    } else {
      this.logger.log(
        `createOneWithRolesCheck, ForbiddenException, user: ${userId}`,
        SpaceService.name
      )
      throw new ForbiddenException()
    }
  }

  /**
   * @description anyone can create, but this method is to add business logic in the future. All services that conform to IRoleConsumer implement this
   * @date 2023-03-30 22:22
   */
  public canCreateWithRolesCheck(userId: string) {
    return true
  }
  /**
   * END Section: CREATE spaces
   */

  /**
   * START Section: READ spaces
   */
  /**
   * TODO add pagination
   * @date 2023-04-05 15:32
   * @description userId is present in case the user IS authed, then that user's role should be taken into account, SO this finds both PUBLIC AND SPACES THAT THE USER has access to.
   * @deprecated a more up-to-date role check method should be used. (Is this route implemented?) 2023-06-10 22:21:44
   */
  public async findAllPublicForUserWithRolesCheck(
    ownerId: string,
    populate = false,
    requestingUserId?: string
  ): Promise<SpaceDocument[]> {
    const select = getPublicPropertiesForMongooseQuery(SpacePublicData)
    const sort = { updatedAt: 'desc' } as { [key: string]: SortOrder }
    const ownerKey = `role.users.${ownerId}`

    const query = {
      [ownerKey]: { $exists: true },
      'role.defaultRole': { $gte: ROLE.OBSERVER }
    }

    const data = await this.spaceModel
      .find(query)
      .populate(populate ? this._getStandardPopulateFieldsAsArray() : ['role'])
      .limit(100)
      .select(select)
      .sort(sort)
      .exec()
    // if authed, apply that user's roles
    if (requestingUserId) {
      // TODO: we need to strip out .role.users and .role.userGroups where the user isn't in that dict
      return data.filter((space: SpaceWithStandardPopulatedProperties) =>
        this.canFindWithRolesCheck(requestingUserId, space)
      )
    } else {
      //default to observer since no user
      return data.filter(
        (space: SpaceWithStandardPopulatedProperties) =>
          space.role.defaultRole >= ROLE.DISCOVER
      )
    }
  }

  public async findAllPublic(
    userId: string,
    populate = false
  ): Promise<SpaceDocument[]> {
    const select = getPublicPropertiesForMongooseQuery(SpacePublicData)
    const sort = { updatedAt: 'desc' } as { [key: string]: SortOrder }
    const data = await this.spaceModel
      .find({ public: true })
      .populate(populate ? this._getStandardPopulateFieldsAsArray() : ['role'])
      .limit(100)
      .select(select)
      .sort(sort)
      .exec()
    // if authed, apply that user's roles
    if (userId) {
      // TODO: we need to strip out .role.users and .role.userGroups where the user isn't in that dict
      return data.filter((space: SpaceWithStandardPopulatedProperties) =>
        this.canFindWithRolesCheck(userId, space)
      )
    } else {
      //default to observer since no user
      return data.filter(
        (space: SpaceWithStandardPopulatedProperties) =>
          space.role.defaultRole >= ROLE.DISCOVER
      )
    }
  }

  /**
   *
   * @deprecated use findForUserWithRolesCheckV2Paginated
   */
  public async findAllForUserWithRolesCheck(
    userId: string
  ): Promise<SpaceDocument[]> {
    const data = await this.spaceModel
      .find()
      .populate(this._getStandardPopulateFieldsAsArray())
      .limit(1000) // TODO add pagination. We're sorting by desc though, so this should cover most use cases right now
      .sort({ createdAt: 'desc' })
      .exec()

    // first, only show the ones that the user can read
    const spaces = data
      .filter((space: SpaceWithStandardPopulatedProperties) =>
        this.canFindWithRolesCheck(userId, space)
      )
      // where user IS an owner
      .filter((space: SpaceWithStandardPopulatedProperties) =>
        space.role.userIsOwner(userId)
      )
    return spaces
  }

  /**
   *
   * @date 2023-12-06
   * @description Main "BUILD" tab route: method to retrieve all non-template spaces that have a default role greater than or equal to OBSERVER and where user is not an owner
   *
   */
  public async findDiscoverSpacesForUserWithRolesCheckPaginatedV2(
    userId: UserId,
    searchDto?: PaginatedSearchSpaceDto,
    matchFilter: FilterQuery<Space> = {},
    populate = false
  ) {
    const { page, perPage, startItem, numberOfItems } = searchDto

    const andFilter = this._getSearchFilter(searchDto)
    matchFilter.$and = andFilter

    matchFilter.$and.push({ isTMTemplate: { $exists: false } })
    matchFilter.$and.push({ activeSpaceVersion: { $exists: true } })
    if (userId) {
      matchFilter.$and.push({ [`role.users.${userId}`]: { $ne: ROLE.OWNER } })
    }

    const sort =
      searchDto.sortKey && searchDto.sortDirection !== undefined
        ? {
            [searchDto.sortKey]: searchDto.sortDirection
          }
        : undefined

    const paginationStrategy = this.paginationService.getPaginationStrategy(
      startItem,
      numberOfItems
    )

    let paginationConfig: IPaginationPipeline<
      PaginationData | PaginationDataByStartItem
    >
    if (searchDto.sortKey === 'popular' && searchDto.sortDirection) {
      const popularSearchResult = await getPopularSpacesAggregationPipeline(
        this.spaceModel,
        this.roleService.getRoleCheckAggregationPipeline(userId, ROLE.OBSERVER),
        { page, perPage, startItem, numberOfItems },
        paginationStrategy,
        false,
        searchDto.sortDirection,
        populate ? this._standardPopulateFields : [],
        matchFilter
      )
      return {
        data: popularSearchResult.paginatedResult,
        ...popularSearchResult.paginationData
      }
    } else {
      paginationConfig =
        await this.paginationService.getPaginationPipelineWithRolesCheck(
          userId,
          this.spaceModel,
          matchFilter,
          ROLE.OBSERVER,
          { page, perPage, startItem, numberOfItems },
          populate ? this._standardPopulateFields : [],
          sort,
          paginationStrategy
        )
    }

    const paginatedSpaces = await this.spaceModel
      .aggregate(paginationConfig.paginationPipeline)
      .exec()
    return { data: paginatedSpaces, ...paginationConfig.paginationData }
  }
  /**
   * @description Same as findAllForUserWithRolesCheck, but with pagination. Not modifying findAllForUserWithRolesCheck due to open/closed principle
   * @date 2023-04-23 00:57
   */
  public async findForUserWithRolesCheckV2Paginated(
    userId: UserId,
    searchDto?: PaginatedSearchSpaceDto,
    gteRoleLevel = ROLE.OWNER,
    matchFilter: FilterQuery<any> = {},
    populate = false, // don't use, it's slow,
    populateCreator?: boolean
  ): Promise<IPaginatedResponse<SpaceDocument>> {
    const populateFields: PopulateField[] = populateCreator
      ? [{ localField: 'creator', from: 'users', unwind: true }]
      : []

    // pages
    const { page, perPage, startItem, numberOfItems } = searchDto

    // and filter
    const andFilter = this._getSearchFilter(searchDto)
    if (andFilter.length > 0) {
      matchFilter.$and = andFilter
    }
    // sort
    const sort =
      searchDto.sortKey && searchDto.sortDirection !== undefined
        ? {
            [searchDto.sortKey]: searchDto.sortDirection
          }
        : undefined

    const paginationStrategy = this.paginationService.getPaginationStrategy(
      startItem,
      numberOfItems
    )

    let paginationConfig: IPaginationPipeline<
      PaginationData | PaginationDataByStartItem
    >

    if (searchDto.sortKey === 'popular' && searchDto.sortDirection) {
      const popularSearchResult = await getPopularSpacesAggregationPipeline(
        this.spaceModel,
        this.roleService.getRoleCheckAggregationPipeline(userId, gteRoleLevel),
        { page, perPage, startItem, numberOfItems },
        paginationStrategy,
        false,
        searchDto.sortDirection,
        populate ? this._standardPopulateFields : populateFields,
        matchFilter
      )
      return {
        data: popularSearchResult.paginatedResult,
        ...popularSearchResult.paginationData
      }
    } else {
      paginationConfig =
        await this.paginationService.getPaginationPipelineWithRolesCheck(
          userId,
          this.spaceModel,
          matchFilter,
          gteRoleLevel,
          { page, perPage, startItem, numberOfItems },
          populate ? this._standardPopulateFields : populateFields,
          sort,
          paginationStrategy
        )
    }

    const paginatedSpaces = await this.spaceModel
      .aggregate(paginationConfig.paginationPipeline)
      .exec()

    return { data: paginatedSpaces, ...paginationConfig.paginationData }
  }

  /**
   * @description The Spaces shown on the Discover tab. These are spaces where the User is NOT an owner
   * @deprecated use a v2/v3 route. This is only on the /discoverv1 route
   * @date 2023-04-11 15:10
   */
  public async findDiscoverSpacesForUser(
    userId: string
  ): Promise<SpaceDocument[]> {
    const data = await this.spaceModel
      .find()
      .populate(this._getStandardPopulateFieldsAsArray())
      .limit(1000) // TODO add pagination. We're sorting by desc though, so this should cover most use cases right now
      .sort({ createdAt: 'desc' })
      .exec()

    // first, only show the ones that the user can read
    const spaces = data
      .filter((space: SpaceWithStandardPopulatedProperties) =>
        this.canFindWithRolesCheck(userId, space)
      )
      // where user is NOT an owner
      .filter(
        (space: SpaceWithStandardPopulatedProperties) =>
          !space.role.userIsOwner(userId)
      )
    return spaces
  }

  /**
   * @description The first ~4-10 templates shown to a user when creating a Space
   * @date 2023-07-20 16:18
   */
  public async findSpaceTemplatesList(
    userId: string
  ): Promise<SpaceDocument[]> {
    const data = await this.spaceModel
      .find({
        isTMTemplate: true,
        'role.roleLevelRequiredToDuplicate': { $lte: ROLE.OBSERVER }
      })
      .sort({ name: 'asc' })
      .exec()

    // first, only show the ones that the user can read
    const spaces = data.filter((space: SpaceWithStandardPopulatedProperties) =>
      this.canFindWithRolesCheck(userId, space)
    )
    return spaces
  }

  public findOneAdmin(spaceId: SpaceId): Promise<SpaceDocument> {
    return this.spaceModel
      .findById(spaceId)
      .populate(this._getStandardPopulateFieldsAsArray())
      .exec()
  }

  public async findOneWithOutRolesCheck(
    spaceId: SpaceId,
    populateUserPresent = false,
    populateCreator = true // this isn't ideal to be true by default, but it was the past behavior and we want to follow open/closed principle 2024-05-03 10:46:05
  ): Promise<SpaceDocument & IZonePopulatedUsers> {
    const space = await this.getSpace(spaceId, populateCreator)
    const populatedSpaceUsers =
      await this.zoneService.populateZoneUsersBySpaceId(
        spaceId,
        populateUserPresent
      )
    return {
      ...space.toJSON(),
      ...populatedSpaceUsers
    } as unknown as SpaceDocument & IZonePopulatedUsers
  }

  public async findOneWithRolesCheck(
    userId: UserId,
    spaceId: SpaceId,
    populateUserPresent = false
  ): Promise<SpaceDocument & IZonePopulatedUsers> {
    // query at the beginning so we only have to query once. We pass the entity around for role checks
    const space = await this.getSpace(spaceId)

    // TODO: add ROLE per-property filtering. Not needed yet though during closed alpha 2023-03-16 17:10:56
    if (this.canFindWithRolesCheck(userId, space)) {
      const populatedSpaceUsers =
        await this.zoneService.populateZoneUsersBySpaceId(
          spaceId,
          populateUserPresent
        )

      return {
        ...space.toJSON(),
        ...populatedSpaceUsers
      } as unknown as SpaceDocument & IZonePopulatedUsers
    } else {
      this.logger.log(
        `findOneWithRolesCheck, canFindWithRolesCheck failed for user: ${userId}`,
        SpaceService.name
      )
      throw new NotFoundException()
    }
  }

  /**
   * @description This is where the business logic resides for what role level constitutes "read" access
   */
  public canFindWithRolesCheck(
    userId: string,
    entityWithPopulatedProperties: SpaceWithStandardPopulatedProperties
  ) {
    const role: ROLE = this.roleService.getMaxRoleForUserForEntity(
      userId,
      entityWithPopulatedProperties
    )

    if (role >= ROLE.DISCOVER) {
      return true
    } else {
      return false
    }
  }

  /**
   * @description Abstracted method so that consistent population is used for all find single space queries and also 404/not found is handled.
   * IMPORTANT: This should rarely be used. Generally, either the -admin or -withRolesCheck suffix is chosen by the consuming method.
   * @date 2023-03-30 00:28
   */
  async getSpace(
    spaceId: string,
    populateCreator = true // this isn't ideal to be true by default, but it was the past behavior and we want to follow open/closed principle 2024-05-03 10:46:05
  ): Promise<SpaceWithStandardPopulatedProperties> {
    const populateFieldsAsArray = this._getStandardPopulateFieldsAsArray()

    // remove the creator populate if populateCreator is false
    if (populateCreator === false) {
      const creatorIndex = populateFieldsAsArray.indexOf('creator')
      if (creatorIndex > -1) {
        populateFieldsAsArray.splice(creatorIndex, 1)
      }
    }

    // find the space
    const space = await this.spaceModel
      .findById<SpaceWithStandardPopulatedProperties>(spaceId)
      .populate(populateFieldsAsArray)
      .exec()
    if (!space) {
      this.logger.log(
        `getSpace, not found. space: ${spaceId}`,
        SpaceService.name
      )
      throw new NotFoundException()
    }
    if (!space.role) {
      debugger
      // this should never happen, but check it
      console.error(`getSpace, no role exists. space: ${spaceId}`)
      throw new InternalServerErrorException('No Role exists on Space')
    }
    return space
  }
  /**
   * END Section: READ
   */

  /**
   * START Section: UPDATE spaces
   */

  public async updateOneWithRolesCheck(
    userId: string,
    spaceId: string,
    updateSpaceDto: UpdateSpaceDto
  ): Promise<SpaceDocument> {
    const space = await this.getSpace(spaceId)

    // update custom data first, if it's there
    if (this.canUpdateWithRolesCheck(userId, space)) {
      if (
        updateSpaceDto.patchCustomData ||
        updateSpaceDto.removeCustomDataKeys
      ) {
        await this.customDataService.updateCustomDataAdmin(
          space.customData.id,
          updateSpaceDto?.patchCustomData,
          updateSpaceDto?.removeCustomDataKeys
        )
      }

      // update spaceVariablesData, if it's there
      if (
        updateSpaceDto.patchSpaceVariablesData ||
        updateSpaceDto.removeSpaceVariablesDataKeys
      ) {
        await this.spaceVariablesDataService.updateSpaceVariablesDataAdmin(
          space?.spaceVariablesData?.id,
          updateSpaceDto?.patchSpaceVariablesData,
          updateSpaceDto?.removeSpaceVariablesDataKeys
        )
      }

      const updateData = omit(updateSpaceDto, 'customData')

      if (updateSpaceDto.publicBuildPermissions) {
        updateData['role.defaultRole'] =
          this._getDefaultRoleByPublicBuildPermissions(
            updateSpaceDto.publicBuildPermissions
          )

        updateData['publicBuildPermissions'] =
          updateSpaceDto.publicBuildPermissions
      }

      return this.spaceModel
        .findByIdAndUpdate(spaceId, updateData, {
          new: true
        })
        .populate([
          'creator',
          'environment',
          'customData',
          'spaceVariablesData'
        ])
        .exec()
    } else {
      this.logger.log(
        `updateOneWithRolesCheck failed for user: ${userId}`,
        SpaceService.name
      )
      throw new NotFoundException(
        'Not Found or you do not have permission to update this SpaceObject'
      )
    }
  }
  /**
   * @description This is where the business logic resides for what role level constitutes "update" access
   */
  public canUpdateWithRolesCheck(
    userId: string,
    entityWithPopulatedProperties: SpaceDocument
  ) {
    const role: ROLE = this.roleService.getMaxRoleForUserForEntity(
      userId,
      entityWithPopulatedProperties
    )
    if (role >= ROLE.MANAGER) {
      return true
    } else {
      return false
    }
  }

  /**
   * @description Only use this for admin level permissions. Otherwise, uses updateOneWithRolesCheck
   * @date 2023-03-30 00:25
   */
  public async updateOneAdmin(
    spaceId: SpaceId,
    updateSpaceDto: UpdateSpaceDto
  ): Promise<SpaceDocument> {
    const space = await this.getSpace(spaceId)

    // update custom data first, if it's there
    if (updateSpaceDto.patchCustomData || updateSpaceDto.removeCustomDataKeys) {
      await this.customDataService.updateCustomDataAdmin(
        space.customData.id,
        updateSpaceDto?.patchCustomData,
        updateSpaceDto?.removeCustomDataKeys
      )
    }

    // update spaceVariablesData, if it's there
    if (
      updateSpaceDto.patchSpaceVariablesData ||
      updateSpaceDto.removeSpaceVariablesDataKeys
    ) {
      await this.spaceVariablesDataService.updateSpaceVariablesDataAdmin(
        space?.spaceVariablesData?.id,
        updateSpaceDto?.patchSpaceVariablesData,
        updateSpaceDto?.removeSpaceVariablesDataKeys
      )
    }

    return this.spaceModel
      .findByIdAndUpdate(spaceId, updateSpaceDto, { new: true })
      .populate(['creator', 'environment', 'customData', 'spaceVariablesData'])
      .exec()
  }

  /**
   * @description This is an optimized/slimmed duplicate of updateOneAdmin for spaceVariables purposes
   * @date 2023-06-13 23:01
   */
  public async updateSpaceVariablesForOneAdmin(
    spaceId: SpaceId,
    updateSpaceDto: UpdateSpaceDto
  ): Promise<SpaceDocument> {
    const space = await this.getSpace(spaceId)

    // update custom data first, if it's there
    if (updateSpaceDto.patchCustomData || updateSpaceDto.removeCustomDataKeys) {
      await this.customDataService.updateCustomDataAdmin(
        space.customData.id,
        updateSpaceDto?.patchCustomData,
        updateSpaceDto?.removeCustomDataKeys
      )
    }

    // update spaceVariablesData, if it's there
    if (
      updateSpaceDto.patchSpaceVariablesData ||
      updateSpaceDto.removeSpaceVariablesDataKeys
    ) {
      await this.spaceVariablesDataService.updateSpaceVariablesDataAdmin(
        space?.spaceVariablesData?.id,
        updateSpaceDto?.patchSpaceVariablesData,
        updateSpaceDto?.removeSpaceVariablesDataKeys
      )
    }

    return this.spaceModel
      .findByIdAndUpdate(spaceId, updateSpaceDto, {
        new: true,
        projection: ['name']
      })
      .populate(['spaceVariablesData']) //<- difference here; less population
      .exec()
  }

  public async removeOneWithRolesCheck(
    userId: string,
    spaceId: string
  ): Promise<SpaceDocument> {
    const space = await this.getSpace(spaceId)

    if (this.canRemoveWithRolesCheck(userId, space)) {
      return this.spaceModel
        .findOneAndDelete({ _id: spaceId })
        .exec()
        .then((data) => {
          if (data) {
            return data
          } else {
            throw new NotFoundException()
          }
        }) as any as Promise<SpaceDocument>
    } else {
      this.logger.log(
        `canRemoveWithRolesCheck failed for user: ${userId}`,
        SpaceService.name
      )
      throw new NotFoundException('Not found or insufficient permissions')
    }
  }

  /**
   * @description This is where the business logic resides for what role level constitutes "delete" access
   */
  public canRemoveWithRolesCheck(
    userId: string,
    entityWithPopulatedProperties: SpaceDocument
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

  public removeOneAdmin(id: string): Promise<SpaceDocument> {
    if (!Types.ObjectId.isValid(id)) {
      throw new BadRequestException('ID is not a valid Mongo ObjectID')
    }
    return this.spaceModel
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

  public async searchForPublicSpacesWithRolesCheck(
    userId: string = undefined,
    searchQuery: string,
    populate = false // don't use, it's slow
  ): Promise<SpaceWithStandardPopulatedProperties[]> {
    // const select = getPublicPropertiesForMongooseQuery(SpacePublicData)

    if (!searchQuery) {
      const data = await this.spaceModel
        .find<SpaceWithStandardPopulatedProperties>()
        .populate(populate ? this._getStandardPopulateFieldsAsArray() : [])
        // .select(select) // TODO: add ROLE per-property filtering. Not needed yet though during closed alpha 2023-03-16 17:10:56
        .limit(25)
        .exec()
      // filter the ones that can be read with roles check
      if (userId) {
        return data.filter((space) => {
          return this.canFindWithRolesCheck(userId, space)
        })
      } else {
        //default to observer since no user
        return data.filter(
          (space: SpaceWithStandardPopulatedProperties) =>
            space.role.defaultRole >= ROLE.DISCOVER
        )
      }
    }

    const filter = {
      ...this.spaceSearch.getSearchFilter(searchQuery)
    }

    const data = await this.spaceModel
      .find<SpaceWithStandardPopulatedProperties>(filter)
      .populate(populate ? this._getStandardPopulateFieldsAsArray() : [])
      // .select(select)   // TODO: add ROLE per-property filtering. Not needed yet though during closed alpha 2023-03-16 17:10:56
      .exec()
    if (userId) {
      return data.filter((space: SpaceWithStandardPopulatedProperties) => {
        return this.canFindWithRolesCheck(userId, space)
      })
    } else {
      //default to observer since no user
      return data.filter(
        (space: SpaceWithStandardPopulatedProperties) =>
          space.role.defaultRole >= ROLE.DISCOVER
      )
    }
  }

  // is this dead code? 2023-04-05 16:50:38
  public search(query: any): Promise<SpaceDocument[]> {
    return this.spaceModel
      .find({
        // TODO allowlist these keys
        $or: Object.keys(query).map((key) => {
          return {
            [key]: new RegExp(query[key])
          }
        })
      })
      .populate(['creator', 'environment'])
      .exec()
  }

  public async updateSpaceImagesWithRolesCheck(
    userId: string,
    spaceId: string,
    images: { index: string; path: string }[]
  ): Promise<SpaceDocument> {
    const update = {
      $set: {
        ...images.reduce((result, { index, path }) => {
          result[`images.${index}`] = path
          return result
        }, {})
      }
    }
    const space = await this.getSpace(spaceId)
    if (this.canUpdateWithRolesCheck(userId, space)) {
      return this.spaceModel
        .findByIdAndUpdate(spaceId, update, { new: true })
        .populate(['creator', 'environment'])
        .exec()
    } else {
      console.log(`updateOneWithRolesCheck failed for user: ${userId}`)
      throw new NotFoundException('Not found or insufficient permissions')
    }
  }

  /** Saves an empty data array to the voxels file in GCS. */
  public async clearVoxels(spaceId: string) {
    try {
      const remoteRelativePath = `space/${spaceId}/terrain/voxels.dat`

      if (process.env.ASSET_STORAGE_DRIVER === 'LOCAL') {
        // Create a fake file object to pass to the local file upload method
        const file: Express.Multer.File = {
          fieldname: '',
          originalname: 'voxels.dat',
          encoding: '',
          mimetype: 'application/octet-stream',
          size: 0,
          destination: '',
          filename: '',
          path: '',
          buffer: Buffer.from(new Uint8Array()),
          stream: null // Add the 'stream' property
        }
        await this.fileUploadService.uploadFileLocal(file, remoteRelativePath)
        return {
          success: true,
          publicUrl: `${process.env.ASSET_STORAGE_URL}/${remoteRelativePath}`
        }
      }

      await this.fileUploadService.streamData(
        process.env.GCS_BUCKET_PUBLIC,
        remoteRelativePath,
        'application/octet-stream',
        Buffer.from(new Uint8Array()),
        'publicRead'
      )
      return {
        success: true,
        publicUrl: `${process.env.GCP_BASE_PUBLIC_URL}/${remoteRelativePath}`
      }
    } catch (e) {
      this.logger.error(e?.message, e, SpaceService.name)
      throw new InternalServerErrorException('Error uploading terrain data')
    }
  }

  /** Uploads files to GCS bucket and returns index and path for updating in mongo */
  public async uploadSpaceFilesPublicWithRolesCheck(
    userId: string,
    { spaceId, files }: UploadSpaceFilesDto
  ) {
    const space = await this.getSpace(spaceId)
    const role: ROLE = this.roleService.getMaxRoleForUserForEntity(
      userId,
      space
    )

    if (role >= ROLE.MANAGER) {
      try {
        const images = await Promise.all(
          files.map((file) => {
            const fileId = new ObjectId()
            const path = `space/${spaceId}/images/${fileId.toString()}`
            return this.fileUploadService.uploadFilePublic({ file, path })
          })
        )
        /** Need to save a reference of the fieldname to know which index to set */
        return images.map((image, i) => ({
          index: files[i].fieldname,
          path: image.publicUrl
        }))
      } catch (error: any) {
        throw error
      }
    } else {
      this.logger.log(
        `uploadSpaceFilesPublicWithRolesCheck failed for user: ${userId}`,
        SpaceService.name
      )
      throw new NotFoundException('Not found or insufficient permissions')
    }
  }

  /**
   * Publishes a Space.
   * @param spaceId string space MongoDB Id
   * @returns published payload.
   */
  public async publishSpaceByIdWithRolesCheck(
    userId: string,
    spaceId: string,
    updateSpaceWithActiveSpaceVersion = false,
    name?: string
  ) {
    /** Get original space or throw error if not found */
    const space = await this.getSpace(spaceId)
    const role: ROLE = this.roleService.getMaxRoleForUserForEntity(
      userId,
      space
    )

    if (role >= ROLE.OWNER) {
      // business logic: only Owner can publish
      return await this._publishSpace(
        space,
        updateSpaceWithActiveSpaceVersion,
        name
      )
    } else {
      this.logger.log(
        `publishSpaceByIdWithRolesCheck failed for user: ${userId}`
      )
      throw new NotFoundException('Not found or insufficient permissions')
    }
  }

  /**
   * Publishes a Space.
   * @param spaceId string space MongoDB Id
   * @returns published payload.
   */
  public async publishSpaceByIdAdmin(
    spaceId: string,
    updateSpaceWithActiveSpaceVersion = false,
    name?: string
  ) {
    const space = await this.getSpace(spaceId)
    return await this._publishSpace(
      space,
      updateSpaceWithActiveSpaceVersion,
      name
    )
  }

  /**
   * Publishes a Space.
   * This is private so that either the -admin or -wiithRolesCheck suffix is chosen by the consuming method.
   * @returns published payload.
   */
  private async _publishSpace(
    space: SpaceWithStandardPopulatedProperties,
    updateSpaceWithActiveSpaceVersion = false,
    name?: string
  ) {
    let env = null
    if (space.environment) {
      env = await this.environmentService.findOne(space.environment._id)
    }

    const spaceObjects = await this.spaceObjectService.findAllBySpaceIdAdmin(
      space._id
    )

    const assetIds = []

    for (let i = 0; i < spaceObjects.length; i++) {
      const spaceObj = spaceObjects[i]
      const assetId = String(spaceObj.asset._id)
      if (assetIds.indexOf(assetId) === -1) {
        assetIds.push(assetId)
      }
    }

    const assets = await this.assetService.findManyAdmin(assetIds)

    const scripts = await this.getAllSpaceScriptEntities(space._id)

    const mirorDBRecord =
      await this.mirrorDBService.getRecordFromMirrorDBBySpaceId(
        space._id.toString()
      )

    const spaceVersion = new this.spaceVersionModel({
      ///
      spaceId: space._id,
      name: name ?? undefined,
      space: space.toObject(),
      spaceVariables: space.spaceVariablesData.data,
      scripts,
      scriptInstances: space.scriptInstances,
      environment: env ? env.toObject() : {},
      assets: assets.map((a) => a.toObject()),
      spaceObjects: spaceObjects.map((s) => s.toObject()),
      mirrorVersion: (await this.mirrorServerConfigService.getConfig())
        .gdServerVersion,
      mirrorDBRecord: mirorDBRecord._id
    })

    const savedSpaceVersion = await spaceVersion.save()

    if (updateSpaceWithActiveSpaceVersion) {
      //update the Space's activeSpaceVersion
      await this.spaceModel
        .findByIdAndUpdate(space._id, {
          activeSpaceVersion: new ObjectId(savedSpaceVersion._id)
        })
        .exec()
    }

    await this.mirrorDBService.addSpaceVersionToMirrorDB(
      space._id,
      savedSpaceVersion._id
    )

    return savedSpaceVersion
  }

  public async restoreSpaceFromSpaceVersionWithRolesCheck(
    spaceVersionId: SpaceVersionId,
    userId: UserId
  ) {
    if (!isValidObjectId(spaceVersionId)) {
      throw new BadRequestException('Invalid spaceVersionId')
    }

    const spaceVersion = await this.spaceVersionModel.findById(spaceVersionId)

    if (!spaceVersion) {
      throw new NotFoundException('SpaceVersion not found')
    }

    const restoreSpace = Object.fromEntries(spaceVersion.space.toObject())

    /* 
      if the user is the creator of the space, then we give the role of OWNER, if not, then DISCOVER
      this is necessary because users roles are not saved in the space version
    */
    const role: ROLE =
      restoreSpace.role.creator.toString() === userId
        ? ROLE.OWNER
        : ROLE.DISCOVER

    if (role >= ROLE.OWNER) {
      const newRestoreSpaceId = new ObjectId()

      /** restore Environment  */
      const restordEnv = await this.environmentService.restoreEnvironment(
        restoreSpace.environment
      )

      restoreSpace.environment = restordEnv._id

      /** restore SpaceVariables  */
      const restoreSpaceVariables =
        await this.spaceVariablesDataService.restoreSpaceVariablesData(
          spaceVersion.spaceVariables as any
        )

      restoreSpace.spaceVariablesData = restoreSpaceVariables._id

      /** restore scripts and return array of old and new scriptIds  */
      const restoreScriptsIds =
        await this.scriptEntityService.restoreScriptEntities(
          spaceVersion.scripts
        )

      /** restore restore spaceObjects and change assets and scripts to restored  */
      await this.spaceObjectService.restoreSpaceObjectsWithAssetsAndScriptsForRestoreSpaceFromSpaceVersion(
        newRestoreSpaceId,
        spaceVersion.spaceObjects,
        spaceVersion.assets,
        restoreScriptsIds
      )

      restoreSpace._id = newRestoreSpaceId
      await this.spaceModel.create(restoreSpace)
      return restoreSpace
    } else {
      this.logger.log(
        `restoreSpaceFromSpaceVersionWithRolesCheck failed for user: ${userId}`
      )
      throw new NotFoundException('Not found or insufficient permissions')
    }
  }

  public async getAllSpaceScriptEntities(spaceId: SpaceId) {
    const pipeline: PipelineStage[] = [
      {
        $match: {
          space: new ObjectId(spaceId)
        }
      },
      {
        $unwind: '$scriptEvents'
      },
      {
        $addFields: {
          convertedScriptId: { $toObjectId: '$scriptEvents.script_id' }
        }
      },
      {
        $lookup: {
          from: 'scriptentities',
          localField: 'convertedScriptId',
          foreignField: '_id',
          as: 'scriptEntities'
        }
      },
      {
        $unwind: '$scriptEntities'
      },
      {
        $group: {
          _id: '$convertedScriptId',
          scriptEntity: { $first: '$scriptEntities' }
        }
      },
      {
        $group: {
          _id: '$space',
          scripts: { $push: '$scriptEntity' }
        }
      },
      {
        $project: {
          _id: 0,
          scripts: 1
        }
      }
    ]

    const [aggregationResult] = await this.spaceObjectModel
      .aggregate(pipeline)
      .exec()

    return aggregationResult?.scripts || []
  }

  /**
   * Gets all of the published space versions by id.
   * @param spaceId space mongodb id.
   * @returns Array of SpaceVersions.
   */
  public async getSpaceVersionsBySpaceId(
    spaceId: SpaceId
  ): Promise<SpaceVersionDocument[]> {
    return await this.spaceVersionModel
      .find()
      .where({ spaceId: spaceId })
      .sort({ createdAt: 'desc' })
      .exec()
  }

  /**
   * Gets all of the published space versions by id.
   * @param spaceId space mongodb id.
   * @returns Array of SpaceVersions.
   */
  public async getSpaceVersionBySpaceVersionIdAdmin(
    spaceVersionId: SpaceVersionId
  ): Promise<SpaceVersionDocument> {
    return await this.spaceVersionModel
      .findById(spaceVersionId)
      .sort({ createdAt: 'desc' })
      .exec()
  }

  /**
   * Gets the latest published space version by the id ADMIN.
   * Note that this is LATEST, not ACTIVE. Active should generally be used.
   * @param spaceId space mongodb id.
   * @returns SpaceVersion document or 404.
   */
  public async getLatestSpaceVersionBySpaceIdAdmin(
    spaceId: SpaceId
  ): Promise<SpaceVersionDocument> {
    return await this.spaceVersionModel
      .findOne({ spaceId: spaceId }, {}, { sort: { createdAt: -1 } })
      .exec()
  }

  /**
   * Gets the active spaceVersion for a Space
   */
  public async getActiveSpaceVersionForSpaceBySpaceIdAdmin(
    spaceId: SpaceId
  ): Promise<SpaceVersionDocument> {
    const space = await this.findOneAdmin(spaceId)
    if (!space.activeSpaceVersion) {
      throw new NotFoundException('No activeSpaceVersion set for this space')
    }
    return await this.spaceVersionModel
      .findOne(
        { _id: new ObjectId(space.activeSpaceVersion as unknown as string) },
        {},
        { sort: { createdAt: -1 } }
      )
      .exec()
  }

  public async findSpaceVersionsByIdAdmin(spaceVersionId: SpaceVersionId) {
    return await this.spaceVersionModel.findById(spaceVersionId).exec()
  }

  /**
   * Creates a copy of a space along with all the space objects
   * and terrain related to that space.
   * TODO - setup better exception handling and any types
   */
  public async copyFullSpaceWithRolesCheck(
    userId: string,
    spaceId: string,
    duplicateAssets = false,
    newName?: string,
    newDescription?: string,
    publicBuildPermissions?: BUILD_PERMISSIONS,
    maxUsers?: number
  ) {
    /** Get original space or throw error if not found */
    const space = await this.getSpace(spaceId)
    if (space.isTMTemplate) {
      space.isTMTemplate = undefined
    }
    const role: ROLE = this.roleService.getMaxRoleForUserForEntity(
      userId,
      space
    )
    // Can only copy Space if meets role.roleLevelRequiredToDuplicate
    if (
      !isNil(space.role.roleLevelRequiredToDuplicate) &&
      role >= space.role.roleLevelRequiredToDuplicate
    ) {
      /** Copy Terrain from space */
      const copiedTerrain = await this.terrainService.copyFromTerrain(
        space.terrain as any,
        userId
      )
      /** Copy Environment from space */
      const copiedEnv = await this.environmentService.copyFromEnvironment(
        space.environment as any
      )
      /** Copy SpaceVariables from space */
      const copiedSpaceVariables =
        await this.spaceVariablesDataService.copySpaceVariablesDataDoc(
          space.spaceVariablesData as any
        )
      /** Copy Space with copied Terrain and Environment references */
      const newRole = new this.roleModel({
        defaultRole: this._getDefaultRoleByPublicBuildPermissions(
          publicBuildPermissions
        ),
        users: {
          [userId]: ROLE.OWNER
        },
        creator: userId
      })
      // ids of scripts in scriptInstances and scriptIds from space
      const parentSpaceScriptIdsList = [
        ...new Set(
          space.scriptIds.concat(
            space.scriptInstances.map((instance) => instance.get('script_id'))
          )
        )
      ]
      const copiedSpace = await this.copyFromSpace({
        space,
        terrainId:
          copiedTerrain && copiedTerrain['_id']
            ? copiedTerrain['_id']
            : undefined,
        environmentId: copiedEnv._id,
        spaceVariablesDataId: copiedSpaceVariables._id,
        userId,
        role: newRole,
        newName,
        newDescription,
        maxUsers,
        publicBuildPermissions
      })
      //get ids of all new spaceObjects
      const newSpaceObjectsIds =
        await this.spaceObjectService.copySpaceObjectsToSpaceAdmin(
          spaceId,
          copiedSpace._id
        )
      //new ids of scripts in scriptInstances and scriptIds from copiedSpace
      const childSpaceScriptIdsList = [
        ...new Set(
          copiedSpace.scriptIds.concat(
            copiedSpace.scriptInstances.map((instance) =>
              instance.get('script_id')
            )
          )
        )
      ]
      const spaceobjIds =
        newSpaceObjectsIds.length != 0
          ? Object.values(newSpaceObjectsIds[0].insertedIds)
          : []
      // change all spaceObjects where scriptEvents scriptid is equal to scriptId from scriptIds and scriptInstances.script_id from space to avoid repeated copying
      await this.spaceObjectModel.aggregate([
        {
          $match: {
            _id: {
              $in: spaceobjIds
            },
            scriptEvents: {
              $elemMatch: {
                script_id: {
                  $in: parentSpaceScriptIdsList
                }
              }
            }
          }
        },
        {
          $addFields: {
            scriptEvents: {
              $map: {
                input: '$scriptEvents',
                as: 'event',
                in: {
                  $mergeObjects: [
                    '$$event',
                    {
                      script_id: {
                        $arrayElemAt: [
                          childSpaceScriptIdsList,
                          {
                            $indexOfArray: [
                              parentSpaceScriptIdsList,
                              '$$event.script_id'
                            ]
                          }
                        ]
                      }
                    }
                  ]
                }
              }
            }
          }
        },
        {
          $merge: {
            into: 'spaceobjects',
            whenMatched: 'merge',
            whenNotMatched: 'insert'
          }
        }
      ])
      // get all unique scripts in scpaceObjects scriptEvents
      const spaceObjectsWithScriptEventScriptsIds =
        await this.spaceObjectModel.aggregate([
          {
            $match: {
              _id: {
                $in: spaceobjIds
              },
              $and: [
                {
                  scriptEvents: {
                    $elemMatch: {
                      script_id: {
                        $nin: childSpaceScriptIdsList
                      }
                    }
                  }
                },
                {
                  scriptEvents: {
                    $not: {
                      $size: 0
                    }
                  }
                }
              ]
            }
          },
          {
            $project: {
              _id: 1,
              scriptEvents: 1
            }
          }
        ])
      // get bulkoptions for updating spaceObjects with new scriptIds
      const updatedSpaceObjects =
        await this.scriptEntityService.duplicateSpaceObjectScripts(
          spaceObjectsWithScriptEventScriptsIds
        )
      // update spaceObjects
      await this.spaceObjectModel.bulkWrite(updatedSpaceObjects)
      /** Duplicate Assets from the Space to the user. This is used when copying from templates **/
      if (duplicateAssets) {
        // get every Space object
        const spaceObjects =
          await this.spaceObjectService.findAllBySpaceIdAdmin(spaceId)
        // async loop to get every spaceObject.asset, duplicate it, and then assign that new asset to the spaceObject
        await Promise.all(
          spaceObjects.map(async (spaceObject) => {
            const asset = await this.assetService.findOneAdmin(
              spaceObject.asset._id
            )
            const newAsset =
              await this.assetService.copyAssetToNewUserWithRolesCheck(
                asset._id,
                userId
              )
            if (newAsset) {
              await this.spaceObjectService.updateOneAdmin(spaceObject._id, {
                asset: newAsset._id
              })
            }
          })
        )
      }
      /** Copy terrain voxel file in GCS to new copied space path */
      await this.terrainService.copyVoxelInGCS(spaceId, copiedSpace._id)

      return copiedSpace
    } else {
      this.logger.log(
        `copyFullSpaceWithRolesCheck failed for user: ${userId}`,
        SpaceService.name
      )
      throw new NotFoundException('Not found or insufficient permissions')
    }
  }

  /** Create space from existing space as private
   * TODO - fix any types and preserve codegen compatibility */
  private async copyFromSpace(dto: {
    space: SpaceDocument
    terrainId?: string
    environmentId: string
    spaceVariablesDataId: string
    userId: string
    role: Role
    newName?: string
    newDescription?: string
    maxUsers?: number
    publicBuildPermissions?: BUILD_PERMISSIONS
  }) {
    const {
      space,
      terrainId,
      environmentId,
      spaceVariablesDataId,
      userId,
      role,
      newName,
      newDescription,
      maxUsers,
      publicBuildPermissions
    } = dto
    space._id = new ObjectId()
    space.isNew = true
    space.role = role
    space.creator = userId as any
    space.createdAt = new Date()
    space.updatedAt = new Date()
    newName && (space.name = newName)
    newDescription && (space.description = newDescription)
    space.maxUsers = maxUsers || 24
    space.publicBuildPermissions =
      publicBuildPermissions || BUILD_PERMISSIONS.PRIVATE // default to private

    if (terrainId) space.terrain = terrainId as any
    space.environment = environmentId as any

    // new scriptIds and scriptInstances
    const newScripts =
      await this.scriptEntityService.duplicateScriptsAndScriptInstanceScripts(
        space.scriptIds,
        space.scriptInstances
      )

    space.scriptIds = newScripts.scriptIds
    space.scriptInstances = newScripts.scriptInstances
    space.spaceVariablesData = spaceVariablesDataId as any

    const newMirroDBRecord = await this.mirrorDBService.createNewMirrorDB(
      space._id
    )

    space.mirrorDBRecord = newMirroDBRecord._id

    return space.save()
  }

  public async remixSpaceWithRolesCheck(
    spaceId: string,
    userId: string,
    remixSpaceDto: RemixSpaceDto
  ) {
    const remixSpace = await this.copyFullSpaceWithRolesCheck(
      userId,
      spaceId,
      undefined,
      remixSpaceDto?.name,
      remixSpaceDto?.description,
      remixSpaceDto?.publicBuildPermissions,
      remixSpaceDto?.maxUsers
    )

    // add previous user to remixSpace
    remixSpace.previousUsers.push(new ObjectId(userId))

    return await remixSpace.save()
  }

  public async getPopularSpaces(userId: UserId, populateCreator?: boolean) {
    const populate: PopulateField[] = populateCreator
      ? [{ localField: 'creator', from: 'users', unwind: true }]
      : []

    const result = await getPopularSpacesAggregationPipeline(
      this.spaceModel,
      this.roleService.getRoleCheckAggregationPipeline(userId, ROLE.DISCOVER),
      { startItem: 0, numberOfItems: 10 },
      PAGINATION_STRATEGY.START_ITEM,
      true,
      SORT_DIRECTION.ASC,
      populate
    )

    return result.paginatedResult
  }

  public async getFavoriteSpaces(userId: UserId, populateCreator?: boolean) {
    const fiveStarRatedSpacesIds: { _id: ObjectId; forEntity: ObjectId }[] =
      await this.userService.getUserFiveStarRatedSpaces(userId)

    const spacesIds = fiveStarRatedSpacesIds.map((favoriteSpace) =>
      favoriteSpace.forEntity.toString()
    )

    const populate = populateCreator ? ['creator'] : []

    return await this.spaceModel
      .find({ _id: { $in: spacesIds } })
      .populate(populate)
  }

  public async getRecentSpaces(userId: UserId, populateCreator?: boolean) {
    const userRecents = await this.userService.getUserRecents(userId)
    const spacesIds = userRecents?.spaces || []

    const populate: PopulateField[] = populateCreator
      ? [{ localField: 'creator', unwind: true, from: 'users' }]
      : []

    const pipelineQuery: PipelineStage[] =
      AggregationPipelines.getPipelineForGetByIdOrdered(spacesIds, populate)

    return await this.spaceModel.aggregate(pipelineQuery)
  }

  public async addSpaceToUserRecents(spaceId: SpaceId, userId: UserId) {
    const userRecents = await this.userService.getUserRecents(userId)
    const spaces = userRecents?.spaces || []

    const existingSpaceIndex = spaces.indexOf(spaceId)

    if (existingSpaceIndex >= 0) {
      spaces.splice(existingSpaceIndex, 1)
    } else if (spaces.length === 10) {
      spaces.pop()
    }

    spaces.unshift(spaceId)

    await this.userService.updateUserRecentSpaces(userId, spaces)
  }

  public async addTagToSpaceWithRoleChecks(
    userId: UserId,
    addSearchTagToSpaceDto: AddTagToSpaceDto
  ) {
    const { spaceId, tagName, tagType, thirdPartySourceHomePageUrl } =
      addSearchTagToSpaceDto

    const ownerRoleCheck = await this.isUserOwnerOfSpace(userId, spaceId)

    if (!ownerRoleCheck) {
      throw new NotFoundException('Space not found')
    }

    if (thirdPartySourceHomePageUrl && tagType === TAG_TYPES.THIRD_PARTY) {
      const tags = await this.getSpaceTagsByType(spaceId, tagType)

      const newThirdPartyTag = new ThirdPartyTagEntity(
        tagName,
        thirdPartySourceHomePageUrl
      )

      return await this._updateSpaceThirdPartyTags(
        spaceId,
        tags as ThirdPartyTagEntity[],
        newThirdPartyTag
      )
    }

    const tags = (await this.getSpaceTagsByType(spaceId, tagType)) as string[]

    if (tags.length === 15) {
      throw new BadRequestException(`Space already has 15 ${tagType} tags`)
    }

    if (tags.includes(tagName)) {
      throw new ConflictException(`Space already has this ${tagType} tag`)
    }

    tags.push(tagName)
    await this._updateSpaceTagsByType(spaceId, tagType, tags)

    return tagName
  }

  public async getSpacesByTags(
    searchDto: PaginatedSearchSpaceDto,
    userId: UserId = undefined
  ) {
    const { page, perPage } = searchDto
    const sort =
      searchDto.sortKey && searchDto.sortDirection !== undefined
        ? {
            [searchDto.sortKey]: searchDto.sortDirection
          }
        : undefined

    const matchFilter: FilterQuery<Space> = {}

    const andFilter = this._getSearchFilter(searchDto)
    if (andFilter.length > 0) {
      matchFilter.$and = andFilter
    }

    const { paginationPipeline, paginationData } =
      await this.paginationService.getPaginationPipelineByPageWithRolesCheck(
        userId,
        this.spaceModel,
        matchFilter,
        ROLE.DISCOVER,
        { page, perPage },
        [],
        sort
      )

    const paginatedSpaces = await this.spaceModel
      .aggregate(paginationPipeline)
      .exec()

    return {
      data: paginatedSpaces,
      ...paginationData
    }
  }

  public async getSpaceTagsByType(spaceId: SpaceId, tagType: TAG_TYPES) {
    const space = await this.spaceModel
      .findOne({ _id: spaceId })
      .select('tags')
      .exec()

    if (!space) {
      throw new NotFoundException('Space not found')
    }

    return space?.tags?.[tagType] || []
  }

  public async deleteTagFromSpaceWithRoleChecks(
    userId: UserId,
    spaceId: SpaceId,
    tagName: string,
    tagType: TAG_TYPES
  ) {
    if (!isMongoId(spaceId)) {
      throw new BadRequestException('Id is not a valid Mongo ObjectId')
    }

    if (!isEnum(tagType, TAG_TYPES)) {
      throw new BadRequestException('Unknown tag type')
    }

    const ownerRoleCheck = await this.isUserOwnerOfSpace(userId, spaceId)

    if (!ownerRoleCheck) {
      throw new NotFoundException('Space not found')
    }

    const tagKey = `tags.${tagType}`
    const valueToMatch =
      tagType === TAG_TYPES.THIRD_PARTY ? { name: tagName } : tagName

    await this.spaceModel
      .updateOne({ _id: spaceId }, { $pull: { [tagKey]: valueToMatch } })
      .exec()

    return { spaceId, tagType, tagName }
  }

  public async updateSpaceTagsByTypeWithRoleChecks(
    userId: UserId,
    spaceId: SpaceId,
    tagType: TAG_TYPES,
    tags: string[] | ThirdPartyTagEntity[]
  ) {
    const ownerRoleCheck = await this.isUserOwnerOfSpace(userId, spaceId)

    if (!ownerRoleCheck) {
      throw new NotFoundException('Space not found')
    }

    return await this._updateSpaceTagsByType(spaceId, tagType, tags)
  }

  private async _updateSpaceTagsByType(
    spaceId: SpaceId,
    tagType: TAG_TYPES,
    tags: string[] | ThirdPartyTagEntity[]
  ) {
    const searchKey = `tags.${tagType}`

    await this.spaceModel
      .updateOne({ _id: spaceId }, { $set: { [searchKey]: tags } })
      .exec()

    return tags
  }

  private async _updateSpaceThirdPartyTags(
    spaceId: SpaceId,
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

    await this._updateSpaceTagsByType(
      spaceId,
      TAG_TYPES.THIRD_PARTY,
      thirdPartyTags
    )

    return newThirdPartyTag
  }

  public async isUserOwnerOfSpace(userId: UserId, spaceId: SpaceId) {
    return await this.roleService.checkUserRoleForEntity(
      userId,
      spaceId,
      ROLE.OWNER,
      this.spaceModel
    )
  }

  /**
   * START Section: Search  ------------------------------------------------------
   */

  private _getSearchFilter(searchDto: PaginatedSearchSpaceDto): Array<any> {
    const { search, field, tag, tagType } = searchDto
    const andFilter = []

    if (field && search) {
      andFilter.push({ [field]: new RegExp(search, 'i') })
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
  /**
   * END Section: Search  ------------------------------------------------------
   */

  /**
   * START Section: Owner permissions for role modification
   */
  async setUserRoleForOneWithOwnerCheck(
    requestingUserId: string,
    targetUserId: string,
    spaceId: string,
    role: ROLE
  ) {
    const space = await this.getSpace(spaceId)
    if (!space.role.userIsOwner(requestingUserId)) {
      throw new NotFoundException('Not found or insufficient permissions')
    }

    return await this.spaceModel
      .findByIdAndUpdate(
        spaceId,
        {
          $set: {
            [`role.users.${targetUserId}`]: role
          }
        },
        { new: true }
      )
      .exec()
  }

  async removeUserRoleForOneWithOwnerCheck(
    requestingUserId: string,
    targetUserId: string,
    spaceId: string
  ) {
    const space = await this.getSpace(spaceId)
    if (!space.role.userIsOwner(requestingUserId)) {
      throw new NotFoundException('Not found or insufficient permissions')
    }

    return await this.spaceModel
      .findByIdAndUpdate(spaceId, {
        $unset: {
          [`role.users.${targetUserId}`]: 1
        }
      })
      .exec()
  }

  public async kickUserByAdmin(user_id: UserId, space_id: SpaceId) {
    const space = await this.getSpace(space_id)
    if (!space) {
      throw new NotFoundException('Space not found')
    }
    return await this.spaceModel
      .findByIdAndUpdate(space_id, {
        $push: { kickRequests: user_id }
      })
      .exec()
  }

  private _subscribeToSpaceSchemaChanges(): void {
    // check if localhost. Mongo requires a replica set for this to work
    if (
      process.env.MONGODB_URL?.includes('127.0.0.1') &&
      process.env.NODE_ENV !== 'production'
    ) {
      console.warn('Not running changestream since on localhost')
      return
    }

    const changeStream = this.spaceModel.watch()
    changeStream.on('change', (change) => {
      if (
        (change.operationType === 'update' ||
          change.operationType === 'replace') &&
        !(
          Object.keys(change.updateDescription.updatedFields).length === 1 &&
          change.updateDescription.updatedFields['updatedAt']
        )
      ) {
        const spaceId = change.documentKey._id.toString()
        const eventData = change.updateDescription.updatedFields
        this._notifyAboutSpaceChanges(spaceId, eventData)
      }
    })
  }

  private _notifyAboutSpaceChanges(spaceId: SpaceId, eventData: unknown): void {
    this.redisPubSubService.publishMessage(
      `${CHANNELS.SPACE}:${spaceId}`,
      JSON.stringify({
        event: SPACE_EVENTS.SPACE_UPDATED,
        id: spaceId,
        eventData,
        eventId: 'sub'
      })
    )
  }

  public async refreshSpaceStats(spaceId: SpaceId) {
    const [refreshedStats] = await this.spaceModel
      .aggregate(
        this._getSpaceStatsAggregationPipeline({
          $match: { _id: new ObjectId(spaceId) }
        })
      )
      .exec()

    if (!refreshedStats) {
      throw new BadRequestException('Failed to update stats')
    }

    await this.spaceModel.findByIdAndUpdate(spaceId, refreshedStats)

    return refreshedStats
  }

  public async updateSpacesUserActionsStatsAndUserPresents() {
    const pipeline: PipelineStage[] = [
      ...this._getSpaceStatsAggregationPipeline(),
      {
        $merge: {
          into: 'spaces',
          on: '_id',
          whenMatched: 'merge',
          whenNotMatched: 'discard'
        }
      }
    ]

    await this.spaceModel.aggregate(pipeline).exec()
  }

  private _getSpaceStatsAggregationPipeline(
    matchCondition?: PipelineStage.Match
  ) {
    return [
      ...getUserStatsAndUsersPresentAggregationPipeline(
        matchCondition,
        [],
        true,
        true
      ),
      {
        $project: {
          _id: 1,
          AVG_RATING: 1,
          COUNT_LIKE: 1,
          COUNT_FOLLOW: 1,
          COUNT_SAVES: 1,
          COUNT_RATING: 1,
          usersCount: 1,
          servers: 1,
          usersPresent: 1
        }
      }
    ]
  }

  /*
   *
   * END Section: Owner permissions for role modification
   */

  /*
   *
   * Cron job to update Space's updatedAt  whenever a SpaceObject in that Space is updated.
   */

  @Cron('*/15 * * * * *')
  async refreshSpace() {
    const fifteenSecondsAgo = new Date(Date.now() - 15 * 1000) // Calculate the time 15 seconds ago

    const spaceObjects = await this.spaceObjectModel
      .find({
        updatedAt: {
          $gte: fifteenSecondsAgo
        }
      })
      .select('space updatedAt')

    await Promise.all(
      spaceObjects.map(
        async (spaceObject) =>
          await this.spaceModel.findByIdAndUpdate(spaceObject.space, {
            updatedAt: new Date()
          })
      )
    )
  }
}

export type SpaceServiceType = SpaceService // this is used to solve circular dependency issue with swc https://github.com/swc-project/swc/issues/5047#issuecomment-1302444311
