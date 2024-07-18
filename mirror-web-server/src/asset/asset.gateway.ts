import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway
} from '@nestjs/websockets'
import { AssetService } from './asset.service'
import { UpsertAssetDto } from './dto/upsert-asset.dto'
import { Logger, UseFilters, UseGuards, UseInterceptors } from '@nestjs/common'
import { GodotSocketInterceptor } from '../godot-server/godot-socket.interceptor'
import { GodotSocketExceptionFilter } from '../godot-server/godot-socket-exception.filter'
import {
  AdminTokenWS,
  UserTokenWS
} from '../godot-server/get-user-ws.decorator'
import { UserId } from '../util/mongo-object-id-helpers'
import { WsAuthGuard } from '../godot-server/ws-auth.guard'

enum ZoneAssetWsMessage {
  GET_ONE = 'zone_get_asset',
  UPDATE = 'zone_update_asset'
}

@WebSocketGateway()
@UseGuards(WsAuthGuard)
@UseInterceptors(GodotSocketInterceptor)
@UseFilters(GodotSocketExceptionFilter)
export class AssetGateway {
  public constructor(
    private readonly assetService: AssetService,
    private readonly logger: Logger
  ) {}

  @SubscribeMessage(ZoneAssetWsMessage.GET_ONE)
  public findOne(
    @UserTokenWS('user_id') userId: UserId,
    @AdminTokenWS() isAdmin: boolean,
    @MessageBody('id') id: string
  ) {
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

    if (userId) {
      return this.assetService.findOneWithRolesCheck(userId, id)
    }

    if (isAdmin) {
      return this.assetService.findOneAdmin(id)
    }
  }

  @SubscribeMessage(ZoneAssetWsMessage.UPDATE)
  public update(
    @UserTokenWS('user_id') userId: UserId,
    @AdminTokenWS() isAdmin: boolean,
    @MessageBody('id') id: string,
    @MessageBody('dto') updateAssetDto: UpsertAssetDto
  ) {
    if (userId) {
      return this.assetService.updateOneWithRolesCheck(
        userId,
        id,
        updateAssetDto
      )
    }
    if (isAdmin) {
      return this.assetService.updateOneAdmin(id, updateAssetDto)
    }
  }
}
