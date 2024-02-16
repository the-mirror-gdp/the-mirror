import {
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  WebSocketGateway
} from '@nestjs/websockets'
import { Server, WebSocket } from 'ws'
import { CHANNELS } from '../redis/redis.channels'
import { RedisPubSubService } from '../redis/redis-pub-sub.service'
import { Logger } from '@nestjs/common'

@WebSocketGateway()
export class GodotGateway
  implements OnGatewayConnection, OnGatewayDisconnect, OnGatewayInit
{
  constructor(
    private readonly logger: Logger,
    private readonly redisPubSubService: RedisPubSubService
  ) {}

  private channelSubs: Record<string, WebSocket[]> = {}

  /** on server init */
  public afterInit(server: Server) {
    this.logger.log('Socket is live', GodotGateway.name)
  }

  /** on connect event */
  public handleConnection(client: WebSocket, ...args: any[]) {
    // ensure max listeners is set high enough - nestjs bug (older version causes error)
    client.setMaxListeners(20)

    /** Crude authentication check until further defined */
    const [{ headers }] = args
    const token = headers?.authorization
    const spaceId = headers?.space
    if (!token || token !== process.env.WSS_SECRET) {
      const msg = 'Invalid WSS_SECRET for GodotGateway handleConnection'
      this.logger.error(msg, GodotGateway.name)
      client.close()
      return
    }

    this.logger.log(
      `handleConnection: ${JSON.stringify(
        {
          spaceId
        },
        null,
        2
      )}`,
      GodotGateway.name
    )
    this.setupSubscriber(client, spaceId)
  }

  setupSubscriber(client: WebSocket, spaceId: string) {
    if (!spaceId) {
      this.logger.log(
        `setupSubscriber: attempted by spaceId was falsey: ${JSON.stringify(
          {
            spaceId
          },
          null,
          2
        )}`,
        GodotGateway.name
      )
      return
    }
    const subChannel = `${CHANNELS.SPACE}:${spaceId}`
    client['subscriberChannel'] = subChannel
    if (!this.channelSubs[subChannel]) {
      this.channelSubs[subChannel] = new Array<WebSocket>()
    }
    this.channelSubs[subChannel].push(client)
    // setup the subscription listener if this is the first subscriber to the channel.
    if (this.channelSubs[subChannel].length == 1) {
      this.redisPubSubService.subscriber.subscribe(subChannel, (message) => {
        this.handleSubscriptionReceived(subChannel, message)
      })
    }
  }

  handleSubscriptionReceived(subChannel: string, message: string) {
    this.logger.log(
      `handleSubscriptionReceived: ${JSON.stringify(
        {
          subChannel,
          message
        },
        null,
        2
      )}`,
      GodotGateway.name
    )
    this.channelSubs[subChannel].forEach((client) => {
      client.send(message)
    })
  }

  removeSubscriber(client: WebSocket) {
    // remove the client from the channel subscriptions.
    const subchannel = client['subscriberChannel']
    if (!subchannel || !this.channelSubs[subchannel]) {
      this.logger.log(
        `setupSubscriber: attempted but subchannel was falsey: ${JSON.stringify(
          {
            client,
            subchannel
          },
          null,
          2
        )}`,
        GodotGateway.name
      )
      return
    }
    this.channelSubs[subchannel] = this.channelSubs[subchannel].filter(
      (c1) => c1 !== client
    )
    // unsubscribe from the subscription listener if this is the last subscriber to the channel.
    if (this.channelSubs[subchannel].length == 0) {
      this.redisPubSubService.subscriber.unsubscribe(subchannel)
    }
  }

  /** on disconnect event */
  public handleDisconnect(client: WebSocket) {
    this.logger.log('Handle Disconnect', GodotGateway.name)
    this.removeSubscriber(client)
    client.close()
  }
}
