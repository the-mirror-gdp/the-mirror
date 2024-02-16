import { Logger, UseFilters, UseInterceptors } from '@nestjs/common'
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway
} from '@nestjs/websockets'
import { GodotSocketExceptionFilter } from '../godot-server/godot-socket-exception.filter'
import { GodotSocketInterceptor } from '../godot-server/godot-socket.interceptor'
import { UpdateTerrainDto } from './dto/update-terrain.dto'
import { TerrainService } from './terrain.service'

enum ZoneTerrainMessage {
  GET_ONE = 'zone_get_terrain',
  UPDATE_ONE = 'zone_update_terrain'
}

@WebSocketGateway()
@UseInterceptors(GodotSocketInterceptor)
@UseFilters(GodotSocketExceptionFilter)
export class TerrainGateway {
  constructor(
    private readonly terrainService: TerrainService,
    private readonly logger: Logger
  ) {}

  @SubscribeMessage(ZoneTerrainMessage.GET_ONE)
  public findOneTerrain(@MessageBody('id') id: string) {
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
    return this.terrainService.findOne(id)
  }

  @SubscribeMessage(ZoneTerrainMessage.UPDATE_ONE)
  public updateOne(
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
    return this.terrainService.update(id, updateTerrainDto)
  }
}
