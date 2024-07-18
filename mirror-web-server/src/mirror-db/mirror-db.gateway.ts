import { UseInterceptors, UseFilters, UseGuards } from '@nestjs/common'
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
  SpaceVersionId,
  UserId
} from '../util/mongo-object-id-helpers'
import { UpdateMirrorDBRecordDto } from './dto/update-mirror-db-record.dto'
import {
  AdminTokenWS,
  UserTokenWS
} from '../godot-server/get-user-ws.decorator'
import { WsAuthGuard } from '../godot-server/ws-auth.guard'

@WebSocketGateway()
@UseGuards(WsAuthGuard)
@UseInterceptors(GodotSocketInterceptor)
@UseFilters(GodotSocketExceptionFilter)
export class MirrorDBGateway {
  constructor(private readonly mirrorDBService: MirrorDBService) {}

  @SubscribeMessage(MIRROR_DB_WS_MESSAGE.GET_RECORD_BY_SPACE_ID)
  async getRecordFromMirrorDBBySpaceId(
    @UserTokenWS('user_id') userId: UserId,
    @AdminTokenWS() isAdmin: boolean,
    @MessageBody('id') spaceId: SpaceId
  ) {
    if (isAdmin) {
      return await this.mirrorDBService.getRecordFromMirrorDBBySpaceId(spaceId)
    }

    if (userId) {
      return await this.mirrorDBService.getRecordFromMirrorDBBySpaceIdWithRolesCheck(
        spaceId,
        userId
      )
    }
    return
  }

  @SubscribeMessage(MIRROR_DB_WS_MESSAGE.GET_RECORD_BY_SPACE_VERSION_ID)
  async getRecordFromMirrorDBBSpaceVersionId(
    @UserTokenWS('user_id') userId: UserId,
    @AdminTokenWS() isAdmin: boolean,
    @MessageBody('id') spaceVersionId: SpaceVersionId
  ) {
    if (isAdmin) {
      return await this.mirrorDBService.getRecordFromMirrorDBBySpaceVersionId(
        spaceVersionId
      )
    }

    if (userId) {
      return await this.mirrorDBService.getRecordFromMirrorDBBySpaceVersionIdWithRolesCheck(
        spaceVersionId,
        userId
      )
    }
    return
  }

  @SubscribeMessage(MIRROR_DB_WS_MESSAGE.GET_RECORD)
  async getRecordFromMirrorDBById(
    @UserTokenWS('user_id') userId: UserId,
    @AdminTokenWS() isAdmin: boolean,
    @MessageBody('id') id: MirrorDBRecordId
  ) {
    if (isAdmin) {
      return await this.mirrorDBService.getRecordFromMirrorDBById(id)
    }

    if (userId) {
      return await this.mirrorDBService.getRecordFromMirrorDBByIdWithRolesCheck(
        id,
        userId
      )
    }
    return
  }

  @SubscribeMessage(MIRROR_DB_WS_MESSAGE.UPDATE_RECORD)
  async updateRecordInMirrorDBById(
    @AdminTokenWS() isAdmin: boolean,
    @UserTokenWS('user_id') user_id: UserId,
    @MessageBody('id') id: MirrorDBRecordId,
    @MessageBody('dto') updateMirrorDBRecordDto: UpdateMirrorDBRecordDto
  ) {
    if (isAdmin) {
      return await this.mirrorDBService.updateRecordInMirrorDBByIdAdmin(
        id,
        updateMirrorDBRecordDto
      )
    }
    if (user_id) {
      return await this.mirrorDBService.updateRecordInMirrorDBByIdWithRoleChecks(
        id,
        updateMirrorDBRecordDto,
        user_id
      )
    }
    return
  }

  @SubscribeMessage(MIRROR_DB_WS_MESSAGE.DELETE_RECORD)
  async deleteRecordFromMirrorDBById(
    @UserTokenWS('user_id') userId: UserId,
    @AdminTokenWS() isAdmin: boolean,
    @MessageBody('id') id: MirrorDBRecordId
  ) {
    if (isAdmin) {
      return await this.mirrorDBService.deleteRecordFromMirrorDBById(id)
    }

    if (userId) {
      return await this.mirrorDBService.deleteRecordFromMirrorDBByIdWithRolesChecks(
        id,
        userId
      )
    }
    return
  }
}
