import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor
} from '@nestjs/common'
import { Logger } from '@nestjs/common'
import { catchError, map, Observable, throwError } from 'rxjs'
import { WsException } from '@nestjs/websockets'
import { PaginationInterface } from '../util/pagination/pagination.interface'

interface GodotWsSuccessResponse extends PaginationInterface {
  eventId: string
  status: number
  result: any
}

/**
 * Transforms every websocket response to GodotWsSuccessResponse type.
 * If response is paginated, this pulls nested data object to root level
 * 'result' property. If result is an array, add pagination props.
 */
@Injectable()
export class GodotSocketInterceptor implements NestInterceptor {
  constructor(private readonly logger: Logger) {}
  public intercept(
    context: ExecutionContext,
    next: CallHandler<GodotWsSuccessResponse>
  ): Observable<GodotWsSuccessResponse> {
    const { eventId } = context.switchToWs().getData()
    return next.handle().pipe(
      map((response: any) => {
        /** Pull data and pagination off, set data to result */
        const { data, ...pagination } = response
        const result = data ?? response

        return {
          eventId,
          status: 200,
          result,

          /** If result is an array, add pagination */
          ...(Array.isArray(result) && { ...pagination })
        }
      }),
      catchError((error) =>
        throwError(() => {
          this.logger.error(
            'WSError: ',
            error,
            'context: ',
            context,
            GodotSocketInterceptor.name
          )
          return new WsException(error.message)
        })
      )
    )
  }
}
