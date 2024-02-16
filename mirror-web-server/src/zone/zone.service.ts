import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
  forwardRef
} from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { Cron, CronExpression } from '@nestjs/schedule'
import { isMongoId, validateOrReject } from 'class-validator'
import { subSeconds } from 'date-fns'
import { BulkWriteResult, ObjectId } from 'mongodb'
import { Model, PipelineStage } from 'mongoose'
import { MirrorServerConfigService } from '../mirror-server-config/mirror-server-config.service'
import { SpaceService, SpaceServiceType } from '../space/space.service'
import {
  MongoZoneId,
  SpaceId,
  SpaceVersionId,
  UserId,
  ZoneId
} from '../util/mongo-object-id-helpers'
import { CreateZoneDto } from './dto/create-zone.dto'
import { UpdateZoneDto } from './dto/update-zone.dto'
import {
  SpaceManagerExternalService,
  CreateContainerDto
} from './space-manager-external.service'
import { Zone, ZoneDocument, ZONE_MODE } from './zone.schema'
import {
  getPopulateUsersInZoneBySpaceIdAggregationPipeline,
  getPopulateUsersInZoneBySpaceIdNoUsersPresentPopulateAggregationPipeline
} from './aggregation-pipelines/populate-users-in-zone-for-space.pipeline'
import { IZonePopulatedUsers } from './abstractions/populated-users.interface'
import { CreatePlayServerDto } from './dto/create-play-server.dto'
import { generateUniqueName } from '../util/generate-unique-name'
import { UserService } from '../user/user.service'

/**
 * @description This is to help reduce errors when using the ZoneUUID instead of the MongoObjectId
 */
export type ZoneUUID = string

@Injectable()
export class ZoneService {
  constructor(
    @InjectModel(Zone.name) private zoneModel: Model<ZoneDocument>,
    private readonly spaceManagerExternalService: SpaceManagerExternalService,
    @Inject(forwardRef(() => SpaceService))
    private readonly spaceService: SpaceServiceType,
    private readonly mirrorServerConfigService: MirrorServerConfigService,
    private readonly userService: UserService
  ) {}

  private _standardPopulateFields = [
    {
      path: 'usersPresent',
      select: ['email', 'displayName']
    }
  ]

  /**
   * @description This checks what zones haven't been refreshed in the past z minutes/seconds and then refreshes them with the latest VM data from the scaler.
   * This runs every y seconds (adjustable) but only queries x amount of zones. This is to prevent overloading the scaler or hitting the database too hard unnecessarily.
   * Also, TODO, when multiple containers are spun up, we need to accommodate the use case of multiple NestJS servers all running this method
   * @date 2023-06-09 00:52
   */
  // Disabled for now with not using the scaler
  // @Cron(CronExpression.EVERY_10_SECONDS)
  async refreshZones() {
    // get the latest VM data for all
    // Future TODO: this should be paginated and only query a certain amount of zones at a time, but probably isn't needed until we're at 10k+ Zones. See discussion: https://themirrormegaverse.slack.com/archives/C02T1LA6HSS/p1686331294465859?thread_ts=1686287531.423789&cid=C02T1LA6HSS
    // get zones that haven't been refreshed recently
    const zones = await this.findUnrefreshedZones()
    // get the latest VM data from the scaler
    const containers =
      await this.spaceManagerExternalService.getAllZoneContainers()
    // update those zones in the database

    const batchToUpdate = await Promise.all(
      containers?.map(async (container) => {
        // add the zone with the container info
        const dto = new CreateZoneDto()
        dto.zoneMode = container.space_mode
        dto.space = container.space_id
        dto.spaceVersion = container.space_version
        dto.gdServerVersion = container.gd_server_version
        dto.state = container.state
        dto.ipAddress = container.ip_address
        dto.port = container.port
        dto.uuid = container.uuid
        dto.url = container.url
        dto.containerLastRefreshed = new Date()

        // validate before insert: "skip" if there's invalid data
        try {
          await validateOrReject(dto)
        } catch (errors) {
          console.log('Skipping invalid data for Zone Container sync: ', errors)
          return {} // return an empty object; we'll filter it out after
        }
        // data is valid, so add it to the update array
        return dto
      })
    )
    // filter out empty objects
    const filteredBatch = batchToUpdate.filter(
      (obj) => Object.keys(obj).length > 0
    )
    await this.updateManyAdmin(filteredBatch)

    // get all zones that weren't updated (i.e. they weren't found in the VM data)
    const zonesNotUpdated = zones.filter(
      (zone) => !containers.find((vm) => vm.uuid === zone.uuid)
    )
    const zoneIdsNotUpdated = zonesNotUpdated.map((zone) => zone.id)
    // remove these zones from the database
    await this.removeManyAdmin(zoneIdsNotUpdated)
  }

  public async createContainerAndZone(
    dto: CreateContainerDto & { ownerId: string }
  ): Promise<ZoneDocument> {
    // first, create the container
    const container = await this.spaceManagerExternalService.createContainer({
      spaceId: dto.spaceId,
      zoneMode: dto.zoneMode,
      spaceVersionId: dto.spaceVersionId,
      name: dto.name,
      gdServerVersion: (
        await this.mirrorServerConfigService.getConfig()
      ).gdServerVersion
    })
    // add the zone with the container info
    const zoneData: CreateZoneDto = {
      zoneMode: dto.zoneMode,
      space: dto.spaceId,
      spaceVersion: dto.spaceVersionId,
      gdServerVersion: container.gd_server_version,
      owner: dto.ownerId,
      state: container.state,
      ipAddress: container.ip_address,
      port: container.port,
      uuid: container.uuid,
      url: container.url,
      name: dto.name
    }
    const created = new this.zoneModel(zoneData)
    return created.save()
  }

  public findAllBySpaceIdAdmin(spaceId: string): Promise<ZoneDocument[]> {
    return this.zoneModel
      .find()
      .where({
        space: spaceId
      })
      .populate(this._standardPopulateFields)
      .exec()
  }

  public findBuildSpaceBySpaceIdAdmin(spaceId: string): Promise<ZoneDocument> {
    return this.zoneModel
      .findOne({
        space: spaceId,
        zoneMode: ZONE_MODE.BUILD
      })
      .exec()
  }

  public findFirstByUUIDAdmin(uuid: string): Promise<ZoneDocument> {
    return this.zoneModel.findOne({ uuid: uuid }).exec()
  }

  public findAllByUserIdAdmin(userId: string): Promise<ZoneDocument[]> {
    return this.zoneModel
      .find()
      .where({
        owner: userId
      })
      .populate(this._standardPopulateFields)
      .exec()
  }

  public findAllActiveAdmin(): Promise<ZoneDocument[]> {
    return this.zoneModel
      .find()
      .where({
        uuid: { $nin: [null, ''] }
      })
      .populate(this._standardPopulateFields)
      .exec()
  }

  public findUnrefreshedZones(
    secondsSinceRefresh = 1 // secondsSinceRefresh default was 60 on Jan 3 2024, but we reduced it to 1 second since we believe it was huge delays with joining.
  ): Promise<ZoneDocument[]> {
    const secondsAgo = subSeconds(new Date(), secondsSinceRefresh)
    return (
      this.zoneModel
        .find()
        .where({
          $or: [
            { containerLastRefreshed: { $lte: secondsAgo } },
            { containerLastRefreshed: { $exists: false } }
          ]
        })
        // TODO: this may need to be limited in the future, but it isn't an issue until we're at 10000+ zones
        .populate(this._standardPopulateFields)
        .exec()
    )
  }

  public async findOneAdmin(zoneId: ZoneId): Promise<ZoneDocument> {
    const data = await this.zoneModel
      .findById(zoneId)
      .populate(this._standardPopulateFields)
      .exec()

    if (!data) {
      throw new NotFoundException()
    }
    return data
  }

  /**
* @description 
1. Is there any existing zone? If so, return it (Build mode only has ONE zone)
2. If not, create a new zone and return it
* @date 2023-06-12 15:16
*/
  public async handleJoinBuildServerWithRolesCheck(
    userId: UserId,
    spaceId: SpaceId
  ): Promise<ZoneDocument> {
    // find the space requested
    const space = await this.spaceService.findOneWithRolesCheck(userId, spaceId)

    // will be a 404 if the user doesn't have permissions
    // throw a Not Found if the space isn't found
    if (!space) {
      throw new NotFoundException('Not found or insufficient permissions')
    }

    // find the zone for the Build space
    // use the admin method since the permission to play a game/zone is determiend by Space permissions
    let zone = await this.findBuildSpaceBySpaceIdAdmin(spaceId)

    if (zone) {
      await this.isZoneAlreadyFull(zone._id)
    } else {
      zone = await this.createContainerAndZone({
        zoneMode: ZONE_MODE.BUILD,
        spaceId,
        ownerId: userId,
        gdServerVersion: (
          await this.mirrorServerConfigService.getConfig()
        ).gdServerVersion,
        name: space.name
      })
    }

    await this.spaceService.addSpaceToUserRecents(spaceId, userId)
    await this.userService.updateUserLastActiveTimestamp(userId)

    return zone
  }

  /**
   * @description Create a new Play server (zone) for the spaceVersion
   * @date 2023-06-12 15:16
   */
  public async createPlayServerWithSpaceVersion(
    userId: UserId,
    spaceVersionId: string,
    zoneName?: string
  ): Promise<ZoneDocument> {
    if (!isMongoId(spaceVersionId)) {
      throw new BadRequestException('SpaceVersion id is not valid MongoId')
    }

    const spaceVersion =
      await this.spaceService.getSpaceVersionBySpaceVersionIdAdmin(
        spaceVersionId
      )

    // find the space so we can role check it since role data is stored on Space.role and not on SpaceVersion
    const space = await this.spaceService.findOneWithRolesCheck(
      userId,
      spaceVersion.spaceId
    )
    // will be a 404 if the user doesn't have permissions
    // throw a Not Found if the space isn't found
    if (!space) {
      throw new NotFoundException('Not found or insufficient permissions')
    }

    // find the zone for the Build space
    return await this.createContainerAndZone({
      zoneMode: ZONE_MODE.PLAY,
      spaceId: space._id,
      spaceVersionId,
      ownerId: userId,
      name: zoneName || generateUniqueName(),
      gdServerVersion: (
        await this.mirrorServerConfigService.getConfig()
      ).gdServerVersion
    })
  }

  /**
   * @description Create a new Play server (zone) for the space
   * @date 2023-06-12 15:16
   */
  public async createPlayServerWithSpace(
    userId: UserId,
    spaceId: string,
    zoneName?: string
  ): Promise<ZoneDocument> {
    if (!isMongoId(spaceId)) {
      throw new BadRequestException('Space id is not valid MongoId')
    }

    const space = await this.spaceService.findOneWithRolesCheck(userId, spaceId)

    if (!space.activeSpaceVersion) {
      throw new BadRequestException(
        "Space doesn't have an active space version"
      )
    }

    return await this.createContainerAndZone({
      zoneMode: ZONE_MODE.PLAY,
      spaceId,
      spaceVersionId: space.activeSpaceVersion.toString(),
      ownerId: userId,
      name: zoneName || generateUniqueName(),
      gdServerVersion: (
        await this.mirrorServerConfigService.getConfig()
      ).gdServerVersion
    })
  }

  /**
   * @description Create a new Play server (zone) for the spaceVersion
   * @date 2023-06-12 15:16
   */
  public async getPlayServers(
    userId: UserId,
    spaceVersionId: SpaceVersionId
  ): Promise<ZoneDocument[]> {
    const spaceVersion =
      await this.spaceService.getSpaceVersionBySpaceVersionIdAdmin(
        spaceVersionId
      )

    // find the space so we can role check it since role data is stored on Space.role and not on SpaceVersion
    const space = await this.spaceService.findOneWithRolesCheck(
      userId,
      spaceVersion.spaceId
    )
    // will be a 404 if the user doesn't have permissions
    // throw a Not Found if the space isn't found
    if (!space) {
      throw new NotFoundException('Not found or insufficient permissions')
    }

    // find the zone for the Play space
    return await this.zoneModel
      .find({
        spaceVersion: spaceVersionId
      })
      .exec()
  }

  /**
   * @description Get a list of servers by spaceId
   * @date 2023-06-12 15:16
   */
  public async getPlayServersForSpaceId(
    userId: UserId,
    spaceId: SpaceId,
    populateZoneOwner?: boolean
  ): Promise<ZoneDocument[]> {
    // find the space so we can role check it since role data is stored on Space.role and not on SpaceVersion
    const space = await this.spaceService.findOneWithRolesCheck(userId, spaceId)
    // will be a 404 if the user doesn't have permissions
    // throw a Not Found if the space isn't found
    if (!space) {
      throw new NotFoundException('Not found or insufficient permissions')
    }
    // find the zone for the Play space with zoneMode = PLAY
    return await this.zoneModel
      .find({
        space: spaceId,
        zoneMode: ZONE_MODE.PLAY
      })
      .populate(populateZoneOwner ? 'owner' : '')
      .exec()
  }

  /**
   * @description The only use case should be to join a Play server with a valid ZoneId (retrieved from getting a list of Play servers)
   * @date 2023-06-12 15:16
   */
  public async handleJoinPlayServer(
    userId: UserId,
    zoneId: ZoneId
  ): Promise<ZoneDocument> {
    // find the zone for the Build space
    const zone = await this.findOneAdmin(zoneId)

    // ensure the user is not banned, so find the space first with roles check
    const space = await this.spaceService.findOneWithRolesCheck(
      userId,
      zone.space as unknown as string
    )
    // will be a 404 if the user doesn't have permissions
    // throw a Not Found if the space isn't found
    if (!space) {
      throw new NotFoundException('Not found or insufficient permissions')
    }

    // if zone, return it
    if (zone) {
      await this.isZoneAlreadyFull(zone._id)

      await this.spaceService.addSpaceToUserRecents(space._id, userId)
      await this.userService.updateUserLastActiveTimestamp(userId)

      return zone
    } else {
      // if no zone, then throw 404
      throw new NotFoundException('Play server zone not found')
    }
  }

  /**
   * @description The only use case should be to join a Play server with a valid ZoneId (retrieved from getting a list of Play servers)
   * @date 2023-06-12 15:16
   */
  public async handleJoinPlayServerBySpaceId(
    userId: UserId,
    spaceId: SpaceId,
    createZoneIfDoesntExist = true
  ): Promise<ZoneDocument> {
    // ensure the user is not banned, so find the space first with roles check
    const space = await this.spaceService.findOneWithRolesCheck(userId, spaceId)
    // will be a 404 if the user doesn't have permissions
    // throw a Not Found if the space isn't found
    if (!space) {
      throw new NotFoundException('Not found or insufficient permissions')
    }

    // get the spaceVersion
    const spaceVersion =
      await this.spaceService.getActiveSpaceVersionForSpaceBySpaceIdAdmin(
        spaceId
      )

    // find zones with that spaceVersion
    let zone = (await this.zoneModel
      .findOne({ spaceVersion: spaceVersion.id })
      .exec()) as ZoneDocument

    if (zone) {
      await this.isZoneAlreadyFull(zone._id)
    } else {
      if (!createZoneIfDoesntExist) {
        throw new NotFoundException('Zone not found')
      }

      zone = await this.createPlayServerWithSpaceVersion(
        userId,
        spaceVersion.id
      )
    }

    await this.spaceService.addSpaceToUserRecents(spaceId, userId)
    await this.userService.updateUserLastActiveTimestamp(userId)

    return zone
  }

  public updateOneAdmin(
    id: string,
    updateZoneDto: UpdateZoneDto
  ): Promise<ZoneDocument> {
    return this.zoneModel
      .findByIdAndUpdate(
        id,
        {
          space: updateZoneDto.space,
          ...updateZoneDto
        },
        { new: true }
      )
      .exec()
  }

  public updateManyAdmin(
    batch: UpdateZoneDto[],
    upsert = true
  ): Promise<BulkWriteResult> {
    const updates = batch.map(({ uuid, ...updateProps }) => ({
      updateOne: {
        filter: { uuid },
        update: updateProps,
        upsert
      }
    }))
    // @ts-ignore. The error was a variation of: Type '"BulkWriteResult"' is not assignable to type '"BulkWriteResult"' with importing from Mongo vs Mongoose. Not worth debugging 2023-03-28 01:41:44
    return this.zoneModel.bulkWrite(updates)
  }

  public removeOneAdmin(id: string): Promise<ZoneDocument> {
    return this.zoneModel.findOneAndDelete({ _id: id }, { new: true }).exec()
  }

  public removeManyAdmin(ids: ZoneId[]): Promise<BulkWriteResult> {
    const deletions = ids.map((id) => ({
      deleteOne: {
        filter: { _id: id }
      }
    }))
    // @ts-ignore. The error was a variation of: Type '"BulkWriteResult"' is not assignable to type '"BulkWriteResult"' with importing from Mongo vs Mongoose. Not worth debugging
    return this.zoneModel.bulkWrite(deletions)
  }

  public updateUsersPresentForOneByMongoIdAdmin(
    mongoZoneId: MongoZoneId,
    usersPresent: UserId[]
  ) {
    return this.zoneModel
      .findByIdAndUpdate(
        mongoZoneId,
        {
          usersPresent
        },
        { new: true }
      )
      .exec()
  }

  public updateUsersPresentForOneByZoneUUIDAdmin(
    zoneUUID: ZoneUUID,
    usersPresent: UserId[]
  ) {
    return this.zoneModel
      .findOneAndUpdate(
        { uuid: zoneUUID },
        {
          usersPresent
        },
        { new: true }
      )
      .exec()
  }

  public getZonesWithMostUsersPresent() {
    return this.zoneModel.find({}).sort({ usersPresent: -1 }).limit(10).exec()
  }

  public async isZoneAlreadyFull(zoneId: ZoneId) {
    const maxUsersAndUserPresentsSize: {
      usersPresent: number
      maxUsers: number
    }[] = await this.zoneModel
      .aggregate([
        {
          $match: { _id: zoneId }
        },
        {
          $lookup: {
            from: 'spaces',
            localField: 'space',
            foreignField: '_id',
            as: 'spaceData'
          }
        },
        {
          $unwind: '$spaceData'
        },
        {
          $project: {
            _id: 0,
            usersPresent: { $size: '$usersPresent' },
            maxUsers: '$spaceData.maxUsers'
          }
        }
      ])
      .exec()

    const { maxUsers, usersPresent } = maxUsersAndUserPresentsSize[0]

    if (maxUsers === usersPresent) {
      throw new ForbiddenException(
        'The maximum number of users in the zone has been reached'
      )
    }
  }

  public async populateZoneUsersBySpaceId(
    spaceId: SpaceId,
    populateUsersPresent = false
  ): Promise<IZonePopulatedUsers> {
    const pipeline: PipelineStage[] = populateUsersPresent
      ? getPopulateUsersInZoneBySpaceIdAggregationPipeline({
          $match: { space: new ObjectId(spaceId) }
        })
      : getPopulateUsersInZoneBySpaceIdNoUsersPresentPopulateAggregationPipeline(
          { $match: { space: new ObjectId(spaceId) } }
        )

    const [aggregationResult] = await this.zoneModel.aggregate(pipeline)

    return (
      aggregationResult || {
        userCount: 0,
        servers: {}
      }
    )
  }
}
export type ZoneServiceType = ZoneService
