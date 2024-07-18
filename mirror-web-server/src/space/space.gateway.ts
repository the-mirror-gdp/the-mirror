import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway
} from '@nestjs/websockets'
import { SpaceService } from './space.service'
import { UpdateSpaceDto } from './dto/update-space.dto'
import { Logger, UseFilters, UseGuards, UseInterceptors } from '@nestjs/common'
import { GodotSocketInterceptor } from '../godot-server/godot-socket.interceptor'
import { GodotSocketExceptionFilter } from '../godot-server/godot-socket-exception.filter'
import {
  SpaceId,
  SpaceVersionId,
  UserId
} from '../util/mongo-object-id-helpers'
import {
  AdminTokenWS,
  UserTokenWS
} from '../godot-server/get-user-ws.decorator'
import { WsAuthGuard } from '../godot-server/ws-auth.guard'

enum ZoneSpaceWsMessage {
  GET_ONE = 'zone_get_space',
  UPDATE = 'zone_update_space',
  UPDATE_SPACE_VARIABLES = 'zone_update_space_variables',
  PUBLISH = 'zone_publish_space',
  GET_SPACE_VERSION = 'zone_get_space_version',
  GET_ASSETS = 'zone_get_space_assets'
}

@WebSocketGateway()
@UseGuards(WsAuthGuard)
@UseInterceptors(GodotSocketInterceptor)
@UseFilters(GodotSocketExceptionFilter)
export class SpaceGateway {
  constructor(
    private readonly spaceService: SpaceService,
    private readonly logger: Logger
  ) {}

  @SubscribeMessage(ZoneSpaceWsMessage.GET_ASSETS)
  public getAssetPerSpaceWithRolesCheck(
    @AdminTokenWS() isAdmin: boolean,
    @UserTokenWS('user_id') userId: UserId,
    @MessageBody('id') id: string
  ) {
    if (userId) {
      return this.spaceService.getAssetsListPerSpaceWithRolesCheck(userId, id)
    }
    if (isAdmin) {
      return this.spaceService.getAssetsListPerSpaceAdmin(id)
    }
    return
  }

  @SubscribeMessage(ZoneSpaceWsMessage.GET_ONE)
  public findOne(
    @AdminTokenWS() isAdmin: boolean,
    @UserTokenWS('user_id') userId: UserId,
    @MessageBody('id') id: string
  ) {
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

    if (userId) {
      return this.spaceService.findOneWithRolesCheck(userId, id)
    }
    if (isAdmin) {
      return this.spaceService.findOneAdmin(id)
    }

    return
  }

  @SubscribeMessage(ZoneSpaceWsMessage.UPDATE)
  public update(
    @AdminTokenWS() isAdmin: boolean,
    @UserTokenWS('user_id') userId: UserId,
    @MessageBody('id') id: string,
    @MessageBody('dto') updateSpaceDto: UpdateSpaceDto
  ) {
    if (userId) {
      return this.spaceService.updateOneWithRolesCheck(
        userId,
        id,
        updateSpaceDto
      )
    }

    if (isAdmin) {
      return this.spaceService.updateOneAdmin(id, updateSpaceDto)
    }
    return
  }

  @SubscribeMessage(ZoneSpaceWsMessage.UPDATE_SPACE_VARIABLES)
  public updateSpaceVariables(
    @AdminTokenWS() isAdmin: boolean,
    @UserTokenWS('user_id') userId: UserId,
    @MessageBody('id') spaceId: SpaceId,
    @MessageBody('dto') updateSpaceDto: UpdateSpaceDto
  ) {
    if (userId) {
      return this.spaceService.updateSpaceVariablesWithRolesCheck(
        userId,
        spaceId,
        updateSpaceDto
      )
    }
    if (isAdmin) {
      return this.spaceService.updateSpaceVariablesForOneAdmin(
        spaceId,
        updateSpaceDto
      )
    }
    return
  }

  @SubscribeMessage(ZoneSpaceWsMessage.PUBLISH)
  public publish(
    @AdminTokenWS() isAdmin: boolean,
    @UserTokenWS('user_id') userId: UserId,
    @MessageBody('id') id: string
  ) {
    if (userId) {
      return this.spaceService.publishSpaceByIdWithRolesCheck(userId, id, false)
    }
    if (isAdmin) {
      return this.spaceService.publishSpaceByIdAdmin(id, false)
    }
    return
  }

  @SubscribeMessage(ZoneSpaceWsMessage.GET_SPACE_VERSION)
  public getSpaceVersionById(
    @AdminTokenWS() isAdmin: boolean,
    @MessageBody('spaceVersionId') spaceVersionId: SpaceVersionId
  ) {
    if (isAdmin) {
      return this.spaceService.findSpaceVersionsByIdAdmin(spaceVersionId)
    }
    return
  }
}
