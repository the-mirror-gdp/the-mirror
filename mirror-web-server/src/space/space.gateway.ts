import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway
} from '@nestjs/websockets'
import { SpaceService } from './space.service'
import { UpdateSpaceDto } from './dto/update-space.dto'
import { Logger, UseFilters, UseInterceptors } from '@nestjs/common'
import { GodotSocketInterceptor } from '../godot-server/godot-socket.interceptor'
import { GodotSocketExceptionFilter } from '../godot-server/godot-socket-exception.filter'
import { SpaceId, SpaceVersionId } from '../util/mongo-object-id-helpers'

enum ZoneSpaceWsMessage {
  GET_ONE = 'zone_get_space',
  UPDATE = 'zone_update_space',
  UPDATE_SPACE_VARIABLES = 'zone_update_space_variables',
  PUBLISH = 'zone_publish_space',
  GET_SPACE_VERSION = 'zone_get_space_version',
  GET_ASSETS = 'zone_get_space_assets'
}

@WebSocketGateway()
@UseInterceptors(GodotSocketInterceptor)
@UseFilters(GodotSocketExceptionFilter)
export class SpaceGateway {
  constructor(
    private readonly spaceService: SpaceService,
    private readonly logger: Logger
  ) {}

  @SubscribeMessage(ZoneSpaceWsMessage.GET_ASSETS)
  public getAssetPerSpaceWithRolesCheck(
    @MessageBody('id') id: string,
    @MessageBody('userId') userId: string
  ) {
    return this.spaceService.getAssetsListPerSpaceWithRolesCheck(userId, id)
  }

  @SubscribeMessage(ZoneSpaceWsMessage.GET_ONE)
  public findOne(@MessageBody('id') id: string) {
    this.logger.log(
      `${JSON.stringify(
        {
          ZoneSpaceWsMessage: ZoneSpaceWsMessage.GET_ONE,
          id: id
        },
        null,
        2
      )}`,
      SpaceGateway.name
    )
    return this.spaceService.findOneAdmin(id)
  }

  @SubscribeMessage(ZoneSpaceWsMessage.UPDATE)
  public update(
    @MessageBody('id') id: string,
    @MessageBody('dto') updateSpaceDto: UpdateSpaceDto
  ) {
    return this.spaceService.updateOneAdmin(id, updateSpaceDto)
  }

  @SubscribeMessage(ZoneSpaceWsMessage.UPDATE_SPACE_VARIABLES)
  public updateSpaceVariables(
    @MessageBody('id') spaceId: SpaceId,
    @MessageBody('dto') updateSpaceDto: UpdateSpaceDto
  ) {
    return this.spaceService.updateSpaceVariablesForOneAdmin(
      spaceId,
      updateSpaceDto
    )
  }

  @SubscribeMessage(ZoneSpaceWsMessage.PUBLISH)
  public publish(@MessageBody('id') id: string) {
    return this.spaceService.publishSpaceByIdAdmin(id, false)
  }

  @SubscribeMessage(ZoneSpaceWsMessage.GET_SPACE_VERSION)
  public getSpaceVersionById(
    @MessageBody('spaceVersionId') spaceVersionId: SpaceVersionId
  ) {
    return this.spaceService.findSpaceVersionsByIdAdmin(spaceVersionId)
  }
}
