import { UseInterceptors, UseFilters } from '@nestjs/common'
import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody
} from '@nestjs/websockets'
import { GodotSocketExceptionFilter } from '../godot-server/godot-socket-exception.filter'
import { GodotSocketInterceptor } from '../godot-server/godot-socket.interceptor'
import { MirrorDBService } from './mirror-db.service'
import { MIRROR_DB_WS_MESSAGE } from './enums/mirror-db-ws-message.enum'
import {
  MirrorDBRecordId,
  SpaceId,
  SpaceVersionId
} from '../util/mongo-object-id-helpers'
import { UpdateMirrorDBRecordDto } from './dto/update-mirror-db-record.dto'

@WebSocketGateway()
@UseInterceptors(GodotSocketInterceptor)
@UseFilters(GodotSocketExceptionFilter)
export class MirrorDBGateway {
  constructor(private readonly mirrorDBService: MirrorDBService) {}

  @SubscribeMessage(MIRROR_DB_WS_MESSAGE.GET_RECORD_BY_SPACE_ID)
  async getRecordFromMirrorDBBySpaceId(@MessageBody('id') spaceId: SpaceId) {
    return await this.mirrorDBService.getRecordFromMirrorDBBySpaceId(spaceId)
  }

  @SubscribeMessage(MIRROR_DB_WS_MESSAGE.GET_RECORD_BY_SPACE_VERSION_ID)
  async getRecordFromMirrorDBBSpaceVersionId(
    @MessageBody('id') spaceVersionId: SpaceVersionId
  ) {
    return await this.mirrorDBService.getRecordFromMirrorDBBySpaceVersionId(
      spaceVersionId
    )
  }

  @SubscribeMessage(MIRROR_DB_WS_MESSAGE.GET_RECORD)
  async getRecordFromMirrorDBById(@MessageBody('id') id: MirrorDBRecordId) {
    return await this.mirrorDBService.getRecordFromMirrorDBById(id)
  }

  @SubscribeMessage(MIRROR_DB_WS_MESSAGE.UPDATE_RECORD)
  async updateRecordInMirrorDBById(
    @MessageBody('id') id: MirrorDBRecordId,
    @MessageBody('dto') updateMirrorDBRecordDto: UpdateMirrorDBRecordDto
  ) {
    return await this.mirrorDBService.updateRecordInMirrorDBByIdAdmin(
      id,
      updateMirrorDBRecordDto
    )
  }

  @SubscribeMessage(MIRROR_DB_WS_MESSAGE.DELETE_RECORD)
  async deleteRecordFromMirrorDBById(@MessageBody('id') id: MirrorDBRecordId) {
    return await this.mirrorDBService.deleteRecordFromMirrorDBById(id)
  }
}
