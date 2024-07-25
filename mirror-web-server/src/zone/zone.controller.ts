import {
  Body,
  Controller,
  Delete,
  ForbiddenException,
  Get,
  Logger,
  NotFoundException,
  Param,
  Patch,
  Post,
  PreconditionFailedException,
  Query,
  UseGuards,
  UsePipes,
  ValidationPipe
} from '@nestjs/common'
import { FirebaseTokenAuthGuard } from '../auth/auth.guard'
import { UserToken } from '../auth/get-user.decorator'
import { GodotServerGuard } from '../godot-server/godot-server.guard'
import { SpaceService } from '../space/space.service'
import { SpaceId, UserId, ZoneId } from '../util/mongo-object-id-helpers'
import { SpaceVersionId } from './../util/mongo-object-id-helpers'
import { UpdateZoneDto } from './dto/update-zone.dto'
import { SpaceManagerExternalService } from './space-manager-external.service'
import { ZoneDocument } from './zone.schema'
import { ZoneService } from './zone.service'
import { ApiParam } from '@nestjs/swagger'
import { CreatePlayServerDto } from './dto/create-play-server.dto'
import { PopulateZoneOwnerDto } from './dto/populate-zone-owner.dto'

@UsePipes(new ValidationPipe({ whitelist: true }))
@Controller('zone')
export class ZoneController {
  constructor(
    private readonly zoneService: ZoneService,
    private readonly spaceManagerExternalService: SpaceManagerExternalService,
    private readonly spaceService: SpaceService,
    private readonly logger: Logger
  ) {}

  /** @description Requests a zone server with a specific space id and launches the server if needed for BUILD MODE */
  @Get('join-build-server/:spaceId')
  @ApiParam({ name: 'spaceId', type: 'string', required: true })
  @FirebaseTokenAuthGuard()
  public async joinBuildServer(
    @UserToken('user_id') userId: UserId,
    @Param('spaceId') spaceId: string
  ): Promise<ZoneDocument> {
    return await this.zoneService.handleJoinBuildServerWithRolesCheck(
      userId,
      spaceId
    )
  }

  /**
   * @description gets Play servers for a spaceVersionId
   */
  @Get('list-play-servers/:spaceVersionId')
  @ApiParam({ name: 'spaceVersionId', type: 'string', required: true })
  @FirebaseTokenAuthGuard()
  public async getPlayServersForSpaceVersionId(
    @UserToken('user_id') userId: UserId,
    @Param('spaceVersionId') spaceVersionId: SpaceVersionId
  ): Promise<ZoneDocument[]> {
    return await this.zoneService.getPlayServers(userId, spaceVersionId)
  }

  /**
   * @description gets Play servers for a spaceId
   */
  @Get('list-play-servers/space/:spaceId')
  @ApiParam({ name: 'spaceId', type: 'string', required: true })
  @FirebaseTokenAuthGuard()
  public async getPlayServersForSpaceId(
    @UserToken('user_id') userId: UserId,
    @Param('spaceId') spaceId: SpaceId,
    @Query() populateZoneOwnerDto: PopulateZoneOwnerDto
  ): Promise<ZoneDocument[]> {
    return await this.zoneService.getPlayServersForSpaceId(
      userId,
      spaceId,
      populateZoneOwnerDto.populateOwner
    )
  }

  /**
   * @description joins a play server by spaceVersionId and returns the active session
   */
  @Get('join-play-server/zone/:zoneId')
  @ApiParam({ name: 'zoneId', type: 'string', required: true })
  @FirebaseTokenAuthGuard()
  public async joinPlayServerByZoneId(
    @UserToken('user_id') userId: UserId,
    @Param('zoneId') zoneId: ZoneId
  ) {
    return await this.zoneService.handleJoinPlayServer(userId, zoneId)
  }

  /**
   * @description joins a play server by spaceId, which looks up the activeSpaceVersion and finds the spaceVersion, then returns the zone. If a zone doesn't exist, it will create it
   */
  @Get('join-play-server/space/:spaceId')
  @ApiParam({ name: 'spaceId', type: 'string', required: true })
  @FirebaseTokenAuthGuard()
  public async joinPlayServerBySpaceId(
    @UserToken('user_id') userId: UserId,
    @Param('spaceId') spaceId: SpaceId,
    @Query('createZoneIfDoesntExist') createZoneIfDoesntExist = 'true'
  ): Promise<ZoneDocument> {
    return await this.zoneService.handleJoinPlayServerBySpaceId(
      userId,
      spaceId,
      createZoneIfDoesntExist === 'true' // converts string to boolean
    )
  }

  /**
   * @description joins a play server by spaceVersionId and returns the active session
   */
  @Post('create-play-server/:spaceVersionId')
  @ApiParam({ name: 'spaceVersionId', type: 'string', required: true })
  @FirebaseTokenAuthGuard()
  public async createPlayServerWithSpaceVersion(
    @Body() createPlayServerDto: CreatePlayServerDto,
    @Param('spaceVersionId') spaceVersionId: SpaceVersionId,
    @UserToken('user_id') userId: UserId
  ) {
    return await this.zoneService.createPlayServerWithSpaceVersion(
      userId,
      spaceVersionId,
      createPlayServerDto.zoneName
    )
  }

  @Post('create-play-server/space/:spaceId')
  @ApiParam({ name: 'spaceId', type: 'string', required: true })
  @FirebaseTokenAuthGuard()
  public async createPlayServerWithSpace(
    @Body() createPlayServerDto: CreatePlayServerDto,
    @Param('spaceId') spaceId: SpaceId,
    @UserToken('user_id') userId: UserId
  ) {
    return await this.zoneService.createPlayServerWithSpace(
      userId,
      spaceId,
      createPlayServerDto.zoneName
    )
  }

  /** @description Get all the Zone entities associated with a space id. */
  @Get('space/:spaceId')
  @ApiParam({ name: 'spaceId', type: 'string', required: true })
  @FirebaseTokenAuthGuard()
  public async findAllZonesBySpaceId(@Param('spaceId') spaceId: string) {
    return await this.zoneService.findAllBySpaceIdAdmin(spaceId)
  }

  /** @description Get all the Zone entities associated with a user id. */
  @Get('user/:userId')
  @ApiParam({ name: 'userId', type: 'string', required: true })
  @FirebaseTokenAuthGuard()
  public async findAllZonesByUserId(@Param('userId') userId: string) {
    return await this.zoneService.findAllByUserIdAdmin(userId)
  }

  /** @description Retrieves a zone entity. */
  @Get(':zoneId')
  @ApiParam({ name: 'zoneId', type: 'string', required: true })
  @FirebaseTokenAuthGuard()
  public async findOneZone(@Param('zoneId') zoneId: string) {
    return await this.zoneService.findOneAdmin(zoneId)
  }

  /** @description Update the user controlled values of a zone entity (Name, Description, Space) */
  @Patch(':zoneId')
  @ApiParam({ name: 'zoneId', type: 'string', required: true })
  @FirebaseTokenAuthGuard()
  public async updateOneZone(
    @UserToken('user_id') userId: string,
    @Param('zoneId') zoneId: string,
    @Body() updateZoneDto: UpdateZoneDto
  ) {
    const zone = await this.zoneService.findOneAdmin(zoneId)
    if (!zone) throw new NotFoundException()

    const zoneObj = zone.toObject()
    if (!zoneObj.owner || zoneObj.owner._id != userId)
      throw new ForbiddenException("Cannot update another user's Zone.")

    return await this.zoneService.updateOneAdmin(zoneId, updateZoneDto)
  }

  /** @description Stops all zone servers and updates their corresponding entities.
   * Queries for every active Zone Server, requests that they shut down, and updates corresponding Zone entities. */
  @Delete('admin/stop-all')
  @UseGuards(GodotServerGuard)
  public async stopAllActiveZones() {
    // find all active servers
    const zones = await this.zoneService.findAllActiveAdmin()
    const zoneIdsToDelete: ZoneId[] = []
    for (const zone of zones) {
      // shut down all the servers
      try {
        await this.spaceManagerExternalService.deleteContainer(zone.uuid)
        zoneIdsToDelete.push(zone.id)
      } catch (error) {
        this.logger.error(error, ZoneController.name)
      }
    }
    // update all servers to nullified state
    await this.zoneService.removeManyAdmin(zoneIdsToDelete)
    return { message: `${zoneIdsToDelete.length} Servers Shutdown` }
  }
}
