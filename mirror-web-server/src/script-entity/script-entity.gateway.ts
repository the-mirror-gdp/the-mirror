import { Logger, UseFilters, UseInterceptors } from '@nestjs/common'
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

enum ZoneScriptEntityMessage {
  CREATE_ONE = 'zone_create_script_entity',
  GET_ONE = 'zone_get_script_entity',
  UPDATE_ONE = 'zone_update_script_entity',
  DELETE_ONE = 'zone_delete_script_entity'
}

@WebSocketGateway()
@UseInterceptors(GodotSocketInterceptor)
@UseFilters(GodotSocketExceptionFilter)
export class ScriptEntityGateway {
  constructor(
    private readonly scriptEntityService: ScriptEntityService,
    private readonly logger: Logger
  ) {}

  @SubscribeMessage(ZoneScriptEntityMessage.CREATE_ONE)
  public createScriptEntity(
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
    return this.scriptEntityService.create(userId, createScriptEntityDto)
  }

  @SubscribeMessage(ZoneScriptEntityMessage.GET_ONE)
  public findOneScriptEntity(@MessageBody('id') id: string) {
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
    return this.scriptEntityService.findOne(id)
  }

  @SubscribeMessage(ZoneScriptEntityMessage.UPDATE_ONE)
  public updateOne(
    @MessageBody('id') id: string,
    @MessageBody('dto') updateScriptEntityDto: UpdateScriptEntityDto
  ) {
    // 2023-07-24 15:07:57 I'm changing this log format to not use JSON.stringify and deploying that to dev. The rest should follow suit if that fixes the logs
    this.logger.log(
      {
        ZoneSpaceObjectWsMessage: ZoneScriptEntityMessage.UPDATE_ONE,
        id,
        'dto (updateScriptEntityDto)': updateScriptEntityDto
      },
      ScriptEntityGateway.name
    )
    return this.scriptEntityService.update(id, updateScriptEntityDto)
  }

  @SubscribeMessage(ZoneScriptEntityMessage.DELETE_ONE)
  public deleteOne(@MessageBody('id') id: string) {
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
    return this.scriptEntityService.delete(id)
  }
}
