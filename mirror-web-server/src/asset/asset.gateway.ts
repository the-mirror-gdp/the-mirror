import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway
} from '@nestjs/websockets'
import { AssetService } from './asset.service'
import { UpsertAssetDto } from './dto/upsert-asset.dto'
import { Logger, UseFilters, UseInterceptors } from '@nestjs/common'
import { GodotSocketInterceptor } from '../godot-server/godot-socket.interceptor'
import { GodotSocketExceptionFilter } from '../godot-server/godot-socket-exception.filter'

enum ZoneAssetWsMessage {
  GET_ONE = 'zone_get_asset',
  UPDATE = 'zone_update_asset'
}

@WebSocketGateway()
@UseInterceptors(GodotSocketInterceptor)
@UseFilters(GodotSocketExceptionFilter)
export class AssetGateway {
  public constructor(
    private readonly assetService: AssetService,
    private readonly logger: Logger
  ) {}

  @SubscribeMessage(ZoneAssetWsMessage.GET_ONE)
  public findOne(@MessageBody('id') id: string) {
    this.logger.log(
      `${JSON.stringify(
        {
          ZoneAssetWsMessage: ZoneAssetWsMessage.GET_ONE,
          id: id
        },
        null,
        2
      )}`,
      AssetGateway.name
    )
    return this.assetService.findOneAdmin(id)
  }

  @SubscribeMessage(ZoneAssetWsMessage.UPDATE)
  public update(
    @MessageBody('id') id: string,
    @MessageBody('dto') updateAssetDto: UpsertAssetDto
  ) {
    return this.assetService.updateOneAdmin(id, updateAssetDto)
  }
}
