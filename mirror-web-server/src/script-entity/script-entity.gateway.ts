import { Logger, UseFilters, UseGuards, UseInterceptors } from '@nestjs/common'
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway
} from '@nestjs/websockets'
import { GodotSocketExceptionFilter } from '../godot-server/godot-socket-exception.filter'
import { GodotSocketInterceptor } from '../godot-server/godot-socket.interceptor'
import { CreateScriptEntityDto } from './dto/create-script-entity.dto'
import { UpdateScriptEntityDto } from './dto/update-script-entity.dto'
import { ScriptEntityService } from './script-entity.service'
import { UserId } from '../util/mongo-object-id-helpers'
import {
  AdminTokenWS,
  UserTokenWS
} from '../godot-server/get-user-ws.decorator'
import { WsAuthGuard } from '../godot-server/ws-auth.guard'

enum ZoneScriptEntityMessage {
  CREATE_ONE = 'zone_create_script_entity',
  GET_ONE = 'zone_get_script_entity',
  UPDATE_ONE = 'zone_update_script_entity',
  DELETE_ONE = 'zone_delete_script_entity'
}

@WebSocketGateway()
@UseGuards(WsAuthGuard)
@UseInterceptors(GodotSocketInterceptor)
@UseFilters(GodotSocketExceptionFilter)
export class ScriptEntityGateway {
  constructor(
    private readonly scriptEntityService: ScriptEntityService,
    private readonly logger: Logger
  ) {}

  @SubscribeMessage(ZoneScriptEntityMessage.CREATE_ONE)
  public createScriptEntity(
    @AdminTokenWS() isAdmin: boolean,
    @UserTokenWS('user_id') userIdFromToken: UserId,
    @MessageBody('dto') createScriptEntityDto: CreateScriptEntityDto,
    @MessageBody('fromUser') userId: UserId
  ) {
    this.logger.log(
      `${JSON.stringify(
        {
          ZoneSpaceObjectWsMessage: ZoneScriptEntityMessage.CREATE_ONE,
          createScriptEntityDto
        },
        null,
        2
      )}`,
      ScriptEntityGateway.name
    )

    if (userIdFromToken) {
      return this.scriptEntityService.create(
        userIdFromToken,
        createScriptEntityDto
      )
    }

    if (isAdmin) {
      return this.scriptEntityService.create(userId, createScriptEntityDto)
    }
    return
  }

  @SubscribeMessage(ZoneScriptEntityMessage.GET_ONE)
  public findOneScriptEntity(
    @UserTokenWS('user_id') userId: UserId,
    @AdminTokenWS() isAdmin: boolean,
    @MessageBody('id') id: string
  ) {
    this.logger.log(
      `${JSON.stringify(
        {
          ZoneSpaceObjectWsMessage: ZoneScriptEntityMessage.GET_ONE,
          id
        },
        null,
        2
      )}`,
      ScriptEntityGateway.name
    )
    if (isAdmin) {
      return this.scriptEntityService.findOne(id)
    }
    if (userId) {
      return this.scriptEntityService.findOneWithRolesCheck(id, userId)
    }
    return
  }

  @SubscribeMessage(ZoneScriptEntityMessage.UPDATE_ONE)
  public updateOne(
    @UserTokenWS('user_id') userId: UserId,
    @AdminTokenWS() isAdmin: boolean,
    @MessageBody('id') id: string,
    @MessageBody('dto') updateScriptEntityDto: UpdateScriptEntityDto
  ) {
    this.logger.log(
      {
        ZoneSpaceObjectWsMessage: ZoneScriptEntityMessage.UPDATE_ONE,
        id,
        'dto (updateScriptEntityDto)': updateScriptEntityDto
      },
      ScriptEntityGateway.name
    )
    if (isAdmin) {
      // 2023-07-24 15:07:57 I'm changing this log format to not use JSON.stringify and deploying that to dev. The rest should follow suit if that fixes the logs
      return this.scriptEntityService.update(id, updateScriptEntityDto)
    }
    if (userId) {
      return this.scriptEntityService.updateWithRolesCheck(
        id,
        updateScriptEntityDto,
        userId
      )
    }
    return
  }

  @SubscribeMessage(ZoneScriptEntityMessage.DELETE_ONE)
  public deleteOne(
    @UserTokenWS('user_id') userId: UserId,
    @AdminTokenWS() isAdmin: boolean,
    @MessageBody('id') id: string
  ) {
    this.logger.log(
      `${JSON.stringify(
        {
          ZoneSpaceObjectWsMessage: ZoneScriptEntityMessage.DELETE_ONE,
          id
        },
        null,
        2
      )}`,
      ScriptEntityGateway.name
    )
    if (isAdmin) {
      return this.scriptEntityService.delete(id)
    }
    if (userId) {
      return this.scriptEntityService.deleteWithRolesCheck(id, userId)
    }
    return
  }
}
