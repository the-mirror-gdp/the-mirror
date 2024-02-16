import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler
} from '@nestjs/common'
import { Observable } from 'rxjs'

/**
 * Usage: On a controller route, @SetRequestTimeout(ms)
 */

@Injectable()
export class TimeoutInterceptor implements NestInterceptor {
  constructor(private readonly reflector: Reflector) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const response = context.switchToHttp().getResponse()
    const timeout =
      this.reflector.get<number>('request-timeout', context.getHandler()) ||
      60000
    response.setTimeout(timeout)

    return next.handle()
  }
}

import { applyDecorators, SetMetadata, UseInterceptors } from '@nestjs/common'
import { Reflector } from '@nestjs/core'

const SetTimeout = (timeout: number) => SetMetadata('request-timeout', timeout)

export function SetRequestTimeout(timeout = 600000) {
  return applyDecorators(
    SetTimeout(timeout),
    UseInterceptors(TimeoutInterceptor)
  )
}
