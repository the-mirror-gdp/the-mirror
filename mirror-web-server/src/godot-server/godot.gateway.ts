import { Logger } from '@nestjs/common'
import {
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  WebSocketGateway
} from '@nestjs/websockets'
import { Server, WebSocket } from 'ws'
import { WsAuthHelperService } from './ws-auth-helper.service'

@WebSocketGateway()
export class GodotGateway
  implements OnGatewayConnection, OnGatewayDisconnect, OnGatewayInit
{
  constructor(
    private readonly logger: Logger,
    private readonly wsAuthHelperService: WsAuthHelperService
  ) {}

  private channelSubs: Record<string, WebSocket[]> = {}

  /** on server init */
  public afterInit(server: Server) {
    this.logger.log('Socket is live', GodotGateway.name)
  }

  /** on connect event */
  public handleConnection(client: WebSocket, ...args: any[]) {
    this.wsAuthHelperService.handleConnectionHelper(client, args)
  }

  /** on disconnect event */
  public handleDisconnect(client: WebSocket) {
    this.logger.log('Handle Disconnect', GodotGateway.name)
    this.wsAuthHelperService.removeSubscriber(client)
    client.close()
  }
}
