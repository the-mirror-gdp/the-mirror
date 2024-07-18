import { isNil } from 'lodash'
import {
  Logger,
  Optional,
  UseFilters,
  UseGuards,
  UseInterceptors
} from '@nestjs/common'
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway
} from '@nestjs/websockets'
import { GodotSocketExceptionFilter } from '../godot-server/godot-socket-exception.filter'
import { GodotSocketInterceptor } from '../godot-server/godot-socket.interceptor'
import { SpaceManagerExternalService } from './space-manager-external.service'
import { ZoneService } from './zone.service'
import { UserId } from '../util/mongo-object-id-helpers'
import { AdminTokenWS } from '../godot-server/get-user-ws.decorator'
import { WsAuthGuard } from '../godot-server/ws-auth.guard'

enum ZoneMessage {
  UPDATE_STATUS = 'zone_update_status'
}

@WebSocketGateway()
@UseGuards(WsAuthGuard)
@UseInterceptors(GodotSocketInterceptor)
@UseFilters(GodotSocketExceptionFilter)
export class ZoneGateway {
  constructor(
    private readonly zoneService: ZoneService,
    private readonly vmScalerService: SpaceManagerExternalService,
    private readonly logger: Logger
  ) {}

  private readonly secondsEmptyUntilShutdown = 600
  private readonly minimumUuidLength = 16

  @SubscribeMessage(ZoneMessage.UPDATE_STATUS)
  public async updateStatus(
    @AdminTokenWS() isAdmin: boolean,
    @MessageBody('uuid') zoneUUID: string,
    @MessageBody('players') playerCount: number,
    @MessageBody('secondsEmpty') secondsEmpty: number,
    @MessageBody('version') _version: string,
    @Optional()
    @MessageBody('usersPresent')
    usersPresent?: UserId[]
  ) {
    try {
      if (isAdmin) {
        const updateObj = {
          ZoneMessage: ZoneMessage.UPDATE_STATUS,
          'uuid (zoneUUID)': zoneUUID,
          players: playerCount,
          secondsEmpty: secondsEmpty,
          version: _version,
          usersPresent
        }
        this.logger.log(
          `${JSON.stringify(updateObj, null, 2)}`,
          ZoneGateway.name
        )

        // require a certain length to determine if uuid. Return empty as no further action is required (likely it is "localhost" or empty).
        if (zoneUUID.length < this.minimumUuidLength) {
          return {}
        }

        // if usersPresent, then update the zone document
        if (!isNil(usersPresent) && usersPresent.length > 0) {
          await this.zoneService.updateUsersPresentForOneByZoneUUIDAdmin(
            zoneUUID,
            usersPresent
          )
        }

        // shut down the empty server after the time elapsed
        if (
          playerCount == 0 &&
          secondsEmpty >= this.secondsEmptyUntilShutdown &&
          zoneUUID.length > this.minimumUuidLength
        ) {
          try {
            await this.shutDownZoneInstance(zoneUUID)
          } catch (error) {
            this.logger.error(error, ZoneGateway.name)
          }
          return { action: 'shutdown' }
        }
        return {}
      }
      return
    } catch (error) {
      this.logger.error(error, ZoneGateway.name)
      return {}
    }
  }

  private async shutDownZoneInstance(zoneUUID: string) {
    // tell the zone scaler to shut this server instance down.
    try {
      await this.vmScalerService.deleteContainer(zoneUUID)
    } catch (error) {
      this.logger.error('Failed to delete external container uuid: ', zoneUUID)
    }
    // there is no coordinating zone, take no further action
    const zone = await this.zoneService.findFirstByUUIDAdmin(zoneUUID)
    if (!zone) {
      return {}
    }
    // delete the Zone document
    try {
      await this.zoneService.removeOneAdmin(zone.id)
    } catch (error) {
      this.logger.error('Failed to remove zone ', zone.id)
    }
  }
}
