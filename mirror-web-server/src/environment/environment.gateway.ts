import { Logger, UseFilters, UseInterceptors } from '@nestjs/common'
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway
} from '@nestjs/websockets'
import { GodotSocketExceptionFilter } from '../godot-server/godot-socket-exception.filter'
import { GodotSocketInterceptor } from '../godot-server/godot-socket.interceptor'
import { UpdateEnvironmentDto } from './dto/update-environment.dto'
import { EnvironmentService } from './environment.service'

enum ZoneEnvironmentMessage {
  GET_ONE = 'zone_get_environment',
  UPDATE_ONE = 'zone_update_environment'
}

@WebSocketGateway()
@UseInterceptors(GodotSocketInterceptor)
@UseFilters(GodotSocketExceptionFilter)
export class EnvironmentGateway {
  constructor(
    private readonly environmentService: EnvironmentService,
    private readonly logger: Logger
  ) {}

  @SubscribeMessage(ZoneEnvironmentMessage.GET_ONE)
  public findOneEnvironment(@MessageBody('id') id: string) {
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
    return this.environmentService.findOne(id)
  }

  @SubscribeMessage(ZoneEnvironmentMessage.UPDATE_ONE)
  public updateOne(
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
    return this.environmentService.update(id, updateEnvironmentDto)
  }
}
