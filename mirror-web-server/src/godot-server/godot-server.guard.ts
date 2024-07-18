import { Observable } from 'rxjs'
import {
  Injectable,
  CanActivate,
  ExecutionContext,
  Logger
} from '@nestjs/common'

/**
 * @description Only use for controllers, not websockets
 */
@Injectable()
export class GodotServerGuard implements CanActivate {
  constructor(private readonly logger: Logger) {}

  canActivate(
    context: ExecutionContext
  ): boolean | Promise<boolean> | Observable<boolean> {
    const request = context.switchToHttp().getRequest()
    const check =
      request.headers?.authorization == `Bearer ${process.env.WSS_SECRET}`
    if (!check) {
      this.logger.log(
        'Bearer secret Authorization check failed',
        GodotServerGuard.name
      )
    }
    return check
  }
}
