import { BaseWsExceptionFilter, WsException } from '@nestjs/websockets'
import { ArgumentsHost, Catch } from '@nestjs/common'

interface GodotWsErrorResponse {
  eventId: string
  status: number
  error: string
}

/** Catches WsExceptions and sends error response with error message, status and eventId */
@Catch(WsException)
export class GodotSocketExceptionFilter extends BaseWsExceptionFilter {
  public catch(exception: WsException, host: ArgumentsHost) {
    const client = host.switchToWs().getClient() as WebSocket
    const { eventId } = host.switchToWs().getData()
    const error = exception.message

    const godotErrorResponse: GodotWsErrorResponse = {
      eventId,
      status: 404,
      error
    }
    client.send(JSON.stringify(godotErrorResponse))
  }
}
