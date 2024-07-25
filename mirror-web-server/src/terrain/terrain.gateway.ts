import { Logger, UseFilters, UseGuards, UseInterceptors } from '@nestjs/common'
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway
} from '@nestjs/websockets'
import { GodotSocketExceptionFilter } from '../godot-server/godot-socket-exception.filter'
import { GodotSocketInterceptor } from '../godot-server/godot-socket.interceptor'
import { UpdateTerrainDto } from './dto/update-terrain.dto'
import { TerrainService } from './terrain.service'
import {
  AdminTokenWS,
  UserTokenWS
} from '../godot-server/get-user-ws.decorator'
import { UserId } from '../util/mongo-object-id-helpers'
import { WsAuthGuard } from '../godot-server/ws-auth.guard'

enum ZoneTerrainMessage {
  GET_ONE = 'zone_get_terrain',
  UPDATE_ONE = 'zone_update_terrain'
}

@WebSocketGateway()
@UseGuards(WsAuthGuard)
@UseInterceptors(GodotSocketInterceptor)
@UseFilters(GodotSocketExceptionFilter)
export class TerrainGateway {
  constructor(
    private readonly terrainService: TerrainService,
    private readonly logger: Logger
  ) {}

  @SubscribeMessage(ZoneTerrainMessage.GET_ONE)
  public findOneTerrain(
    @UserTokenWS('user_id') userId: UserId,
    @AdminTokenWS() isAdmin: boolean,
    @MessageBody('id') id: string
  ) {
    this.logger.log(
      `${JSON.stringify(
        {
          ZoneTerrainMessage: ZoneTerrainMessage.GET_ONE,
          id: id
        },
        null,
        2
      )}`,
      TerrainGateway.name
    )

    if (isAdmin) {
      return this.terrainService.findOne(id)
    }

    if (userId) {
      return this.terrainService.findOneWithRolesCheck(id, userId)
    }
    return
  }

  @SubscribeMessage(ZoneTerrainMessage.UPDATE_ONE)
  public updateOne(
    @UserTokenWS('user_id') userId: UserId,
    @AdminTokenWS() isAdmin: boolean,
    @MessageBody('id') id: string,
    @MessageBody('dto') updateTerrainDto: UpdateTerrainDto
  ) {
    this.logger.log(
      `${JSON.stringify(
        {
          ZoneTerrainMessage: ZoneTerrainMessage.UPDATE_ONE,
          id: id,
          updateTerrainDto: updateTerrainDto
        },
        null,
        2
      )}`,
      TerrainGateway.name
    )

    if (isAdmin) {
      return this.terrainService.update(id, updateTerrainDto)
    }

    if (userId) {
      return this.terrainService.updateWithRolesCheck(
        id,
        updateTerrainDto,
        userId
      )
    }
    return
  }
}
