import { Logger, UseFilters, UseGuards, UseInterceptors } from '@nestjs/common'
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway
} from '@nestjs/websockets'
import { GodotSocketExceptionFilter } from '../godot-server/godot-socket-exception.filter'
import { GodotSocketInterceptor } from '../godot-server/godot-socket.interceptor'
import { UpdateEnvironmentDto } from './dto/update-environment.dto'
import { EnvironmentService } from './environment.service'
import {
  AdminTokenWS,
  UserTokenWS
} from '../godot-server/get-user-ws.decorator'
import { UserId } from '../util/mongo-object-id-helpers'
import { WsAuthGuard } from '../godot-server/ws-auth.guard'

enum ZoneEnvironmentMessage {
  GET_ONE = 'zone_get_environment',
  UPDATE_ONE = 'zone_update_environment'
}

@WebSocketGateway()
@UseGuards(WsAuthGuard)
@UseInterceptors(GodotSocketInterceptor)
@UseFilters(GodotSocketExceptionFilter)
export class EnvironmentGateway {
  constructor(
    private readonly environmentService: EnvironmentService,
    private readonly logger: Logger
  ) {}

  @SubscribeMessage(ZoneEnvironmentMessage.GET_ONE)
  public findOneEnvironment(
    @UserTokenWS('user_id') userId: UserId,
    @AdminTokenWS() isAdmin: boolean,
    @MessageBody('id') id: string
  ) {
    this.logger.log(
      `${JSON.stringify(
        {
          ZoneTerrainMessage: ZoneEnvironmentMessage.GET_ONE,
          id: id
        },
        null,
        2
      )}`,
      EnvironmentGateway.name
    )
    if (isAdmin) {
      return this.environmentService.findOne(id)
    }
    if (userId) {
      return this.environmentService.findOneWithRolesCheck(id, userId)
    }
    return
  }

  @SubscribeMessage(ZoneEnvironmentMessage.UPDATE_ONE)
  public updateOne(
    @UserTokenWS('user_id') userId: UserId,
    @AdminTokenWS() isAdmin: boolean,
    @MessageBody('id') id: string,
    @MessageBody('dto') updateEnvironmentDto: UpdateEnvironmentDto
  ) {
    this.logger.log(
      `${JSON.stringify(
        {
          ZoneTerrainMessage: ZoneEnvironmentMessage.UPDATE_ONE,
          id: id,
          updateEnvironmentDto: updateEnvironmentDto
        },
        null,
        2
      )}`,
      EnvironmentGateway.name
    )
    if (isAdmin) {
      return this.environmentService.update(id, updateEnvironmentDto)
    }
    if (userId) {
      return this.environmentService.updateWithRolesCheck(
        id,
        updateEnvironmentDto,
        userId
      )
    }
    return
  }
}
