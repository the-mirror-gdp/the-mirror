import {
  BadRequestException,
  ConflictException,
  forwardRef,
  Inject,
  Injectable,
  Logger,
  NotFoundException
} from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { ObjectId } from 'mongodb'
import mongoose, { Document, FilterQuery, Model } from 'mongoose'
import { RedisPubSubService } from '../redis/redis-pub-sub.service'
import { CHANNELS } from '../redis/redis.channels'
import { ROLE } from '../roles/models/role.enum'
import { IRoleConsumer } from '../roles/role-consumer.interface'
import { RoleService } from '../roles/role.service'
import { SpaceService, SpaceServiceType } from '../space/space.service'
import { SpaceObjectId } from '../util/mongo-object-id-helpers'
import { PaginationInterface } from '../util/pagination/pagination.interface'
import { PaginationService } from '../util/pagination/pagination.service'
import { ISchemaWithRole } from './../roles/role-consumer.interface'
import { SpaceId, UserId } from './../util/mongo-object-id-helpers'
import { CreateSpaceObjectDto } from './dto/create-space-object.dto'
import { UpdateBatchSpaceObjectDto } from './dto/update-batch-space-object.dto'
import { UpdateSpaceObjectDto } from './dto/update-space-object.dto'
import { SpaceObject, SpaceObjectDocument } from './space-object.schema'
import { AssetService } from '../asset/asset.service'
import { TAG_TYPES } from '../tag/models/tag-types.enum'
import { AddTagToSpaceObjectDto } from './dto/add-tag-to-space-object.dto'
import { ThirdPartyTagEntity } from '../tag/models/tags.schema'
import { PaginatedSearchSpaceObjectDto } from './dto/paginated-search-space-object.dto'
import { find, isArray } from 'lodash'
import { SpaceObjectSearch } from './space-object.search'
import { isEnum, isMongoId } from 'class-validator'
import { UpdateSpaceObjectTagsDto } from './dto/update-space-object-tags.dto'
import { AssetDocument } from '../asset/asset.schema'

type SpaceObjectDocumentWithPopulatedSpaceRole = SpaceObjectDocument
@Injectable()
export class SpaceObjectService implements IRoleConsumer {
  constructor(
    @InjectModel(SpaceObject.name)
    private spaceObjectModel: Model<SpaceObjectDocument>,
    private readonly redisPubSubService: RedisPubSubService,
    private readonly paginationService: PaginationService,
    private readonly roleService: RoleService,
    @Inject(forwardRef(() => SpaceService))
    private readonly spaceService: SpaceServiceType, // circular dependency fix. The suffixed -Type type is used to solve circular dependency issue with swc https://github.com/swc-project/swc/issues/5047#issuecomment-1302444311
    private readonly logger: Logger,
    private readonly assetService: AssetService,
    private readonly spaceObjectSearch: SpaceObjectSearch
  ) {}

  private _standardPopulateFields = [
    { path: 'creator', select: ['displayName', 'email'] },
    {
      path: 'space',
      select: ['name'],
      // include role for SpaceObjectDocumentWithPopulatedSpaceRole so we can check the role of the parent Space
      populate: [
        {
          path: 'role',
          select: ['defaultRole', 'users', 'userGroups']
        }
      ]
    },
    { path: 'customData', select: ['name'] }
  ]

  /**
   * START Section: CREATE SpaceObjects ------------------------------------------------------
   */
  //2023-07-07 15:53:30 should this be deleted in favor of createAndNotifyAdmin?
  public createOneAdmin(
    createSpaceObjectDto: CreateSpaceObjectDto & { creatorUserId?: UserId }
  ): Promise<SpaceObjectDocument> {
    const data = {
      space: createSpaceObjectDto.spaceId,
      ...createSpaceObjectDto
    }
    if (createSpaceObjectDto.creatorUserId) {
      data['creator'] = createSpaceObjectDto.creatorUserId
    }
    const created = new this.spaceObjectModel(data)
    return created.save()
  }

  public createAndNotifyAdmin(
    createSpaceObjectDto: CreateSpaceObjectDto & { creatorUserId: UserId }
  ): Promise<SpaceObjectDocument> {
    const created = new this.spaceObjectModel({
      space: createSpaceObjectDto.spaceId,
      creator: createSpaceObjectDto.creatorUserId,
      ...createSpaceObjectDto
    })
    return created.save().then((spaceObject) => {
      this.writeSpaceTopicAdmin(
        spaceObject.space._id,
        'space_object_create',
        spaceObject.id
      )
      return spaceObject
    })
  }

  /**
   * @description This notifies too
   * @date 2023-04-21 00:17
   */
  async createOneWithRolesCheck(
    userId: UserId,
    createSpaceObjectDto: CreateSpaceObjectDto
  ): Promise<Partial<Document<any, any, any>>> {
    const roleCheck = await this.canCreateWithRolesCheck(
      userId,
      createSpaceObjectDto.spaceId
    )

    const assetSoftDeletedCheck = await this.assetService.isAssetSoftDeleted(
      createSpaceObjectDto.asset
    )

    if (assetSoftDeletedCheck) {
      throw new BadRequestException('This asset was soft deleted')
    }

    if (roleCheck) {
      await this.assetService.addInstancedAssetToRecents(
        createSpaceObjectDto.asset,
        userId
      )

      return this.createAndNotifyAdmin({
        creatorUserId: userId,
        ...createSpaceObjectDto
      })
    } else {
      this.logger.log(
        `createOneWithRolesCheck, ForbiddenException, user: ${userId}`,
        SpaceService.name
      )
      throw new NotFoundException('Not found or insufficient permissions')
    }
  }

  /**
   * @description This is where the business logic resides for what role level constitutes "create" access
   */
  public async canCreateWithRolesCheck(userId: UserId, spaceId: SpaceId) {
    const space = await this.spaceService.getSpace(spaceId)
    // a Space MUST have a .role property
    const role: ROLE = this.roleService.getMaxRoleForUserForEntity(
      userId,
      space
    )

    if (role >= ROLE.CONTRIBUTOR) {
      return true
    } else {
      return false
    }
  }

  /** Create new space-objects from existing objects and set them to a space.
   * This does not remove any existing space-objects that are already on the
   * target Space */
  public async copySpaceObjectsToSpaceAdmin(
    fromSpaceId: SpaceId,
    toSpaceId: SpaceId
  ): Promise<any> {
    // TODO type this return. Typescript is being weird currently with "The inferred type of 'removeMany' cannot be named without a reference to 'mongoose/node_modules/mongodb'. This is likely not portable. A type annotation is necessary" 2023-03-16 15:03:15
    const spaceObjects = await this.findAllBySpaceIdAdmin(fromSpaceId)

    /** Create space-object copies as insertOne writes
     * TODO - fix any types and preserve codegen compatibility */
    const insertCopies = spaceObjects.map((obj) => {
      obj._id = new ObjectId()
      obj.space = toSpaceId as any // typed any due to mongo type constraints
      obj.isNew = true
      return { insertOne: { document: obj } }
    })

    /** Create batches of 1000 for bulkWrite limit */
    const batches = this.batchArray(insertCopies, 1000)
    return Promise.all(
      batches.map((batch) => this.spaceObjectModel.bulkWrite(batch))
    )
  }

  /** Create new space-objects from existing objects and set them to a space.
   * This does not remove any existing space-objects that are already on the
   * target Space */
  public async copySpaceObjectsToSpaceWithRolesCheck(
    userId: UserId,
    fromSpaceId: SpaceId,
    toSpaceId: SpaceId
  ): Promise<any> {
    // ensure the user can perform the action for both spaces
    const check1 = await this.canCopyAllSpaceObjectsInSpaceWithRolesCheck(
      userId,
      fromSpaceId
    )
    const check2 = await this.canCopyAllSpaceObjectsInSpaceWithRolesCheck(
      userId,
      toSpaceId
    )
    if (check1 && check2) {
      // Just using admin copy for now. This may need to be refined later 2023-04-20 23:42:22
      return this.copySpaceObjectsToSpaceAdmin(fromSpaceId, toSpaceId)
    } else {
      this.logger.log(
        `copySpaceObjectsToSpaceWithRolesCheck failed for user: ${userId}`,
        SpaceObjectService.name
      )
      throw new NotFoundException('Not found or insufficient permissions')
    }
  }

  /**
   * @description This is where the business logic resides for what role level constitutes "delete" access
   */
  public async canCopyAllSpaceObjectsInSpaceWithRolesCheck(
    userId: UserId,
    spaceId: SpaceId
  ) {
    const space = await this.spaceService.getSpace(spaceId)

    // a Space MUST have a .role property
    const role: ROLE = this.roleService.getMaxRoleForUserForEntity(
      userId,
      space
    )

    if (role >= ROLE.OWNER) {
      return true
    } else {
      return false
    }
  }

  /**
   * END Section: CREATE SpaceObjects ------------------------------------------------------
   */

  /**
   * START Section: READ SpaceObjects ------------------------------------------------------
   */
  /**
   * @description Admin means no role checks
   * @date 2023-03-16 16:43
   */
  public async findManyAdmin(
    ids: SpaceObjectId[],
    pagination: PaginationInterface
  ) {
    const options = { _id: { $in: ids } }
    return await this.paginationService.getPaginatedQueryResponse(
      this.spaceObjectModel,
      options,
      pagination
    )
  }

  public findAllBySpaceId(spaceId: string): Promise<SpaceObjectDocument[]> {
    return this.spaceObjectModel
      .find()
      .where({
        space: spaceId
      })
      .exec()
  }

  public findAllBySpaceIdAdmin(
    spaceId: SpaceId
  ): Promise<SpaceObjectDocument[]> {
    return this.spaceObjectModel
      .find()
      .where({
        space: spaceId
      })
      .exec()
  }

  public getAllBySpaceIdPaginatedAdmin(
    spaceId: SpaceId,
    pagination: PaginationInterface,
    options: { space: SpaceId; [key: string]: any } = { space: spaceId }
  ) {
    return this.paginationService.getPaginatedQueryResponse(
      this.spaceObjectModel,
      options,
      pagination
    )
  }

  public findOneAdmin(
    spaceObjectId: SpaceObjectId
  ): Promise<SpaceObjectDocument> {
    return this.spaceObjectModel.findById(spaceObjectId).exec()
  }

  public findOneAdminWithPopulatedParentSpaceObject(
    spaceObjectId: SpaceObjectId
  ): Promise<SpaceObjectDocument> {
    return this.spaceObjectModel
      .findById(spaceObjectId)
      .populate('parentSpaceObject')
      .exec()
  }
  public async findOneAdminWithPopulatedParentSpaceObjectRecursiveLookup(
    spaceObjectId: SpaceObjectId
  ): Promise<any> {
    const result = await this.spaceObjectModel
      .aggregate([
        {
          $match: {
            _id: new mongoose.Types.ObjectId(spaceObjectId)
          }
        },
        {
          $graphLookup: {
            from: 'spaceobjects', // the name of the SpaceObject collection in the MongoDB
            startWith: '$parentSpaceObject',
            connectFromField: 'parentSpaceObject',
            connectToField: '_id',
            as: 'parentSpaceObjects'
          }
        },
        {
          $addFields: {
            parentSpaceObject: { $arrayElemAt: ['$parentSpaceObjects', 0] }
          }
        }
      ])
      .exec()

    return result[0]
  }

  public async findOneAdminWithPopulatedChildSpaceObjectsRecursiveLookup(
    spaceObjectId: SpaceObjectId
  ): Promise<any> {
    const result = await this.spaceObjectModel
      .aggregate([
        {
          $match: {
            _id: new mongoose.Types.ObjectId(spaceObjectId)
          }
        },
        {
          $graphLookup: {
            from: 'spaceobjects', // the name of the SpaceObject collection in the MongoDB
            startWith: '$_id',
            connectFromField: '_id',
            connectToField: 'parentSpaceObject',
            as: 'childSpaceObjects'
          }
        }
      ])
      .exec()

    return result[0]
  }

  public async findOneWithRolesCheck(
    userId: UserId,
    spaceObjectId: SpaceObjectId
  ): Promise<SpaceObjectDocument> {
    // query at the beginning so we only have to query once. We pass the entity around for role checks
    const spaceObject = await this._getSpaceObject(spaceObjectId)

    // TODO: add ROLE per-property filtering. Not needed yet though during closed alpha 2023-03-16 17:10:56
    if (this.canFindWithRolesCheck(userId, spaceObject)) {
      return spaceObject
    } else {
      this.logger.log(
        `findOneWithRolesCheck, canFindWithRolesCheck failed for user: ${userId}`,
        SpaceObjectService.name
      )
      throw new NotFoundException('Not found or insufficient permissions')
    }
  }

  /**
   * @description This is where the business logic resides for what role level constitutes "read" access
   */
  public canFindWithRolesCheck(
    userId: string,
    spaceObjectWithPopulatedPropertiesWithPopulatedSpaceRole: SpaceObjectDocumentWithPopulatedSpaceRole
  ) {
    // default to NO_ROLE
    let roleFromSpaceObject: ROLE = ROLE.NO_ROLE
    // business logic: we don't force spaceObjects to have a role property
    if (spaceObjectWithPopulatedPropertiesWithPopulatedSpaceRole?.role) {
      roleFromSpaceObject = this.roleService.getMaxRoleForUserForEntity(
        userId,
        spaceObjectWithPopulatedPropertiesWithPopulatedSpaceRole as ISchemaWithRole // infer this here since we checked for .role above
      )
    }

    // a Space MUST have a .role property though.
    const roleFromSpace: ROLE = this.roleService.getMaxRoleForUserForEntity(
      userId,
      spaceObjectWithPopulatedPropertiesWithPopulatedSpaceRole.space
    )

    const role = Math.max(roleFromSpaceObject, roleFromSpace)

    if (role >= ROLE.OBSERVER) {
      return true
    } else {
      return false
    }
  }

  /**
   * @description Abstracted method so that consistent population is used for all find single space queries and also 404/not found is handled.
   * This is private so that either the -admin or -withRolesCheck suffix is chosen by the consuming method.
   * @date 2023-03-30 00:28
   */
  private async _getSpaceObject(
    spaceObjectId: SpaceObjectId
  ): Promise<SpaceObjectDocumentWithPopulatedSpaceRole> {
    const spaceObject = await this.spaceObjectModel
      .findById(spaceObjectId)
      .populate(this._standardPopulateFields)
      .exec()

    if (!spaceObject) {
      this.logger.log(
        `_getSpaceObject, not found. spaceObjectId: ${spaceObjectId}`,
        SpaceObjectService.name
      )
      throw new NotFoundException()
    }

    return spaceObject
  }

  /**
   * END Section: READ SpaceObjects ------------------------------------------------------
   */

  /**
   * START Section: UPDATE SpaceObjects ------------------------------------------------------
   */

  public updateOneAdmin(
    id: SpaceObjectId,
    updateSpaceObjectDto: UpdateSpaceObjectDto
  ): Promise<SpaceObjectDocument> {
    return this.spaceObjectModel
      .findByIdAndUpdate(id, updateSpaceObjectDto, { new: true })
      .exec()
  }

  public updateManyAdmin({ batch }: UpdateBatchSpaceObjectDto): Promise<any> {
    // TODO type this return. Typescript is being weird currently with "The inferred type of 'removeMany' cannot be named without a reference to 'mongoose/node_modules/mongodb'. This is likely not portable. A type annotation is necessary" 2023-03-16 15:03:10
    const updates = batch.map(({ id, ...updateProps }) => ({
      updateOne: {
        filter: { _id: id },
        update: updateProps
      }
    }))
    return this.spaceObjectModel.bulkWrite(updates)
  }

  /**
   * @description Note that this update also notifies
   * @date 2023-04-21 01:16
   */
  public updateOne(
    spaceObjectId: SpaceObjectId,
    updateSpaceObjectDto: UpdateSpaceObjectDto
  ): Promise<SpaceObjectDocument> {
    if (updateSpaceObjectDto.asset) {
      const isSoftDeletedCheck = this.assetService.isAssetSoftDeleted(
        updateSpaceObjectDto.asset
      )

      if (isSoftDeletedCheck) {
        throw new BadRequestException('This asset was soft deleted')
      }
    }

    return this.spaceObjectModel
      .findByIdAndUpdate(spaceObjectId, updateSpaceObjectDto, { new: true })
      .exec()
      .then((spaceObject) => {
        // also notify
        this.writeSpaceTopicAdmin(
          spaceObject.space._id,
          'space_object_update',
          spaceObject.id
        )
        return spaceObject
      })
  }

  public async updateOneWithRolesCheck(
    userId: UserId,
    spaceObjectId: SpaceObjectId,
    updateSpaceObjectDto: UpdateSpaceObjectDto
  ): Promise<Partial<Document<any, any, any>>> {
    const spaceObject = await this._getSpaceObject(spaceObjectId)
    if (this.canUpdateWithRolesCheck(userId, spaceObject)) {
      return this.updateOne(spaceObjectId, updateSpaceObjectDto)
    } else {
      this.logger.log(
        `updateOneAndNotifyWithRolesCheck failed for user: ${userId}`,
        SpaceObjectService.name
      )
      throw new NotFoundException('Not found or insufficient permissions')
    }
  }

  /**
   * @description This is where the business logic resides for what role level constitutes "update" access
   */
  public canUpdateWithRolesCheck(
    userId: string,
    spaceObjectWithPopulatedPropertiesWithPopulatedSpaceRole: SpaceObjectDocumentWithPopulatedSpaceRole
  ) {
    // default to NO_ROLE
    let roleFromSpaceObject: ROLE = ROLE.NO_ROLE
    // business logic: we don't force spaceObjects to have a role property
    if (spaceObjectWithPopulatedPropertiesWithPopulatedSpaceRole?.role) {
      roleFromSpaceObject = this.roleService.getMaxRoleForUserForEntity(
        userId,
        spaceObjectWithPopulatedPropertiesWithPopulatedSpaceRole as ISchemaWithRole // infer this here since we checked for .role above
      )
    }

    // a Space MUST have a .role property though.
    const roleFromSpace: ROLE = this.roleService.getMaxRoleForUserForEntity(
      userId,
      spaceObjectWithPopulatedPropertiesWithPopulatedSpaceRole.space
    )

    const role = Math.max(roleFromSpaceObject, roleFromSpace)

    if (role >= ROLE.MANAGER) {
      return true
    } else {
      return false
    }
  }

  /**
   * END Section: UPDATE SpaceObjects ------------------------------------------------------
   */

  /**
   * START Section: DELETE SpaceObjects ------------------------------------------------------
   */
  public removeManyAdmin(batch: string[]): Promise<any> {
    // TODO type this return. Typescript is being weird currently with "The inferred type of 'removeMany' cannot be named without a reference to 'mongoose/node_modules/mongodb'. This is likely not portable. A type annotation is necessary" 2023-03-16 15:03:06
    const deletes = batch.map((id) => ({
      deleteOne: { filter: { _id: id } }
    }))
    return this.spaceObjectModel.bulkWrite(deletes)
  }

  public removeOneAdmin(id: SpaceObjectId): Promise<SpaceObjectDocument> {
    return this.spaceObjectModel
      .findOneAndDelete({ _id: id }, { new: true })
      .exec()
  }

  public removeAndNotifyAdmin(
    spaceObjectId: SpaceObjectId
  ): Promise<SpaceObjectDocument> {
    return this.spaceObjectModel
      .findOneAndDelete({ _id: spaceObjectId }, { new: true })
      .exec()
      .then((spaceObject) => {
        this.writeSpaceTopicAdmin(
          spaceObject.space._id,
          'space_object_delete',
          spaceObject.id
        )
        return spaceObject
      })
  }

  async removeOneWithRolesCheck(
    userId: UserId,
    spaceObjectId: SpaceObjectId
  ): Promise<Document<any, any, any>> {
    const spaceObject = await this._getSpaceObject(spaceObjectId)
    if (this.canRemoveWithRolesCheck(userId, spaceObject)) {
      return this.spaceObjectModel
        .findOneAndDelete({ _id: spaceObjectId }, { new: true })
        .exec()
        .then((spaceObject) => {
          // also notify
          this.writeSpaceTopicAdmin(
            spaceObject.space._id,
            'space_object_delete',
            spaceObject.id
          )
          return spaceObject
        })
    } else {
      this.logger.log(
        `removeOneWithRolesCheck failed for user: ${userId}`,
        SpaceObjectService.name
      )
      throw new NotFoundException('Not found or insufficient permissions')
    }
  }

  /**
   * @description This is where the business logic resides for what role level constitutes "delete" access
   */
  public canRemoveWithRolesCheck(
    userId: string,
    spaceObjectWithPopulatedPropertiesWithPopulatedSpaceRole: SpaceObjectDocumentWithPopulatedSpaceRole
  ) {
    // default to NO_ROLE
    let roleFromSpaceObject: ROLE = ROLE.NO_ROLE
    // business logic: we don't force spaceObjects to have a role property
    if (spaceObjectWithPopulatedPropertiesWithPopulatedSpaceRole?.role) {
      roleFromSpaceObject = this.roleService.getMaxRoleForUserForEntity(
        userId,
        spaceObjectWithPopulatedPropertiesWithPopulatedSpaceRole as ISchemaWithRole // infer this here since we checked for .role above
      )
    }

    // a Space MUST have a .role property though.
    const roleFromSpace: ROLE = this.roleService.getMaxRoleForUserForEntity(
      userId,
      spaceObjectWithPopulatedPropertiesWithPopulatedSpaceRole.space
    )

    const role = Math.max(roleFromSpaceObject, roleFromSpace)

    if (role >= ROLE.MANAGER) {
      return true
    } else {
      return false
    }
  }
  /**
   * END Section: DELETE SpaceObjects ------------------------------------------------------
   */

  private writeSpaceTopicAdmin(
    spaceId: SpaceId,
    evt: string,
    objId: string
  ): void {
    this.redisPubSubService.publishMessage(
      `${CHANNELS.SPACE}:${spaceId}`,
      JSON.stringify({
        event: evt,
        id: objId,
        eventId: 'sub'
      })
    )
  }

  private batchArray<T>(arr: T[], chunkSize: number) {
    const res = []
    for (let i = 0; i < arr.length; i += chunkSize) {
      const chunk = arr.slice(i, i + chunkSize)
      res.push(chunk)
    }
    return res
  }

  public async getSpaceObjectsByTag(searchDto: PaginatedSearchSpaceObjectDto) {
    const matchFilter: FilterQuery<SpaceObject> = {}

    const andFilter = this._getSearchFilter(searchDto)
    if (andFilter.length > 0) {
      matchFilter.$and = andFilter
    }

    const { page, perPage } = searchDto

    const sort =
      searchDto.sortKey && searchDto.sortDirection !== undefined
        ? {
            [searchDto.sortKey]: searchDto.sortDirection
          }
        : undefined

    const paginatedSpaceObjectResult =
      await this.paginationService.getPaginatedQueryResponseAdmin(
        this.spaceObjectModel,
        matchFilter,
        { page, perPage },
        [],
        sort
      )

    return paginatedSpaceObjectResult
  }

  public async addTagToSpaceObjectWithRoleChecks(
    userId: UserId,
    addTagToSpaceObjectDto: AddTagToSpaceObjectDto
  ) {
    const { spaceObjectId, tagName, tagType, thirdPartySourceHomePageUrl } =
      addTagToSpaceObjectDto

    const { space: spaceId } = await this.spaceObjectModel
      .findOne({ _id: spaceObjectId })
      .select('space')

    if (!spaceId) {
      throw new NotFoundException('Space Object not found')
    }

    const ownerRoleCheck = await this.spaceService.isUserOwnerOfSpace(
      userId,
      spaceId.toString()
    )

    if (!ownerRoleCheck) {
      throw new NotFoundException('Space Object not found')
    }

    if (thirdPartySourceHomePageUrl && tagType === TAG_TYPES.THIRD_PARTY) {
      const tags = await this.getSpaceObjectTagsByType(spaceObjectId, tagType)

      const newThirdPartyTag = new ThirdPartyTagEntity(
        tagName,
        thirdPartySourceHomePageUrl
      )

      return await this._updateSpaceObjectThirdPartyTags(
        spaceObjectId,
        tags as ThirdPartyTagEntity[],
        newThirdPartyTag
      )
    }

    const tags = (await this.getSpaceObjectTagsByType(
      spaceObjectId,
      tagType
    )) as string[]

    if (tags.length === 15) {
      throw new BadRequestException(
        `Space Object already has 15 ${tagType} tags`
      )
    }

    if (tags.includes(tagName)) {
      throw new ConflictException(
        `Space Object already has this ${tagType} tag`
      )
    }

    tags.push(tagName)
    await this._updateSpaceObjectTagsByType(spaceObjectId, tagType, tags)

    return tagName
  }

  public async deleteTagFromSpaceObjectWithRoleChecks(
    userId: UserId,
    spaceObjectId: SpaceObjectId,
    tagName: string,
    tagType: TAG_TYPES
  ) {
    if (!isMongoId(spaceObjectId)) {
      throw new BadRequestException('Id is not a valid Mongo ObjectId')
    }

    if (!isEnum(tagType, TAG_TYPES)) {
      throw new BadRequestException('Unknown tag type')
    }

    const { space: spaceId } = await this.spaceObjectModel
      .findOne({ _id: spaceObjectId })
      .select('space')

    if (!spaceId) {
      throw new NotFoundException('Space Object not found')
    }

    const ownerRoleCheck = await this.spaceService.isUserOwnerOfSpace(
      userId,
      spaceId.toString()
    )

    if (!ownerRoleCheck) {
      throw new NotFoundException('Space Object not found')
    }

    const tagKey = `tags.${tagType}`
    const valueToMatch =
      tagType === TAG_TYPES.THIRD_PARTY ? { name: tagName } : tagName

    await this.spaceObjectModel
      .updateOne({ _id: spaceObjectId }, { $pull: { [tagKey]: valueToMatch } })
      .exec()

    return { spaceObjectId, tagType, tagName }
  }

  public async getSpaceObjectTagsByType(
    spaceObjectId: SpaceObjectId,
    tagType: TAG_TYPES
  ) {
    const spaceObject = await this.spaceObjectModel
      .findOne({ _id: spaceObjectId })
      .select('tags')
      .exec()

    if (!spaceObject) {
      throw new NotFoundException('Space Object not found')
    }

    return spaceObject?.tags?.[tagType] || []
  }

  public async updateSpaceObjectTagsByTypeWithRoleChecks(
    userId: UserId,
    updateSpaceObjectTagsDto: UpdateSpaceObjectTagsDto
  ) {
    const { spaceObjectId, tagType, tags } = updateSpaceObjectTagsDto

    const { space: spaceId } = await this.spaceObjectModel
      .findOne({ _id: spaceObjectId })
      .select('space')

    if (!spaceId) {
      throw new NotFoundException('Space Object not found')
    }

    const ownerRoleCheck = await this.spaceService.isUserOwnerOfSpace(
      userId,
      spaceId.toString()
    )

    if (!ownerRoleCheck) {
      throw new NotFoundException('Space Object not found')
    }

    return await this._updateSpaceObjectTagsByType(spaceObjectId, tagType, tags)
  }

  private async _updateSpaceObjectTagsByType(
    spaceObjectId: SpaceObjectId,
    tagType: TAG_TYPES,
    tags: string[] | ThirdPartyTagEntity[]
  ) {
    const searchKey = `tags.${tagType}`

    await this.spaceObjectModel
      .updateOne({ _id: spaceObjectId }, { $set: { [searchKey]: tags } })
      .exec()

    return tags
  }

  private async _updateSpaceObjectThirdPartyTags(
    spaceObjectId: SpaceObjectId,
    thirdPartyTags: ThirdPartyTagEntity[],
    newThirdPartyTag: ThirdPartyTagEntity
  ) {
    if (thirdPartyTags.length === 15) {
      throw new BadRequestException(
        `Space object already has 15 ${TAG_TYPES.THIRD_PARTY} tags`
      )
    }

    const existingTag = thirdPartyTags.find(
      (tag) =>
        tag.name === newThirdPartyTag.name &&
        tag.thirdPartySourceHomePageUrl ===
          newThirdPartyTag.thirdPartySourceHomePageUrl
    )

    if (existingTag) {
      throw new ConflictException(
        `Space object already has this thirdParty tag`
      )
    }

    thirdPartyTags.push(newThirdPartyTag)

    await this._updateSpaceObjectTagsByType(
      spaceObjectId,
      TAG_TYPES.THIRD_PARTY,
      thirdPartyTags
    )

    return newThirdPartyTag
  }

  public searchSpaceObjectsPaginated(searchDto: PaginatedSearchSpaceObjectDto) {
    const { page, perPage } = searchDto
    const matchFilter: FilterQuery<SpaceObject> = {}

    const andFilter = this._getSearchFilter(searchDto)
    if (andFilter.length > 0) {
      matchFilter.$and = andFilter
    }

    const sort =
      searchDto.sortKey && searchDto.sortDirection !== undefined
        ? {
            [searchDto.sortKey]: searchDto.sortDirection
          }
        : undefined

    return this.paginationService.getPaginatedQueryResponseAdmin(
      this.spaceObjectModel,
      matchFilter,
      { page, perPage },
      [],
      sort
    )
  }

  private _getSearchFilter(
    searchDto: PaginatedSearchSpaceObjectDto
  ): Array<any> {
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

  async restoreSpaceObjectsWithAssetsAndScriptsForRestoreSpaceFromSpaceVersion(
    restoreSpaceId: ObjectId,
    spaceObjects: SpaceObjectDocument[],
    assets: AssetDocument[],
    newScriptIds
  ) {
    const newAssetsIds = await this.assetService.restoreAssetsForSpaceObjects(
      assets
    )

    /** Create space-object copies as insertOne writes */
    const insertCopies = spaceObjects.map((spaceObj) => {
      const obj = Object.fromEntries(spaceObj.toObject())
      obj._id = new ObjectId()
      obj.space = restoreSpaceId as any // typed any due to mongo type constraints
      obj.asset = newAssetsIds.find(
        (assetIds) => assetIds[obj.asset.toString()]
      )[obj.asset.toString()]
      obj.isNew = true

      if (obj.scriptEvents && obj.scriptEvents.length > 0) {
        obj.scriptEvents = obj.scriptEvents.map((scriptEvent) => {
          const newScriptId = newScriptIds.find(
            (scriptIds) => scriptIds[scriptEvent.script_id]
          )[scriptEvent.script_id]

          scriptEvent.script_id = new ObjectId(newScriptId)
          return scriptEvent
        })
      }
      return { insertOne: { document: obj } }
    })

    /** Create batches of 1000 for bulkWrite limit */
    const batches = this.batchArray(insertCopies, 1000)
    return Promise.all(
      batches.map((batch) => this.spaceObjectModel.bulkWrite(batch))
    )
  }

  /**
   * START Section: Roles and permissions
   */
  // TBD: not implemented yet but should be. This is ok to merge for now because Space permissions are umbrella for space-objects.
  setUserRoleForOneWithOwnerCheck(
    requestingUserId: string,
    targetUserId: string,
    spaceId: string,
    role: ROLE
  ) {
    throw new Error('Method not implemented.')
  }
  removeUserRoleForOneWithOwnerCheck(
    requestingUserId: string,
    targetUserId: string,
    spaceId: string
  ) {
    throw new Error('Method not implemented.')
  }
  /**
   * END Section: Roles and permissions
   */
}

export type SpaceObjectServiceType = SpaceObjectService // this is used to solve circular dependency issue with swc https://github.com/swc-project/swc/issues/5047#issuecomment-1302444311
