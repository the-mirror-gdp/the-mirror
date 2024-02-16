import { Observable } from 'rxjs'
import {
  Injectable,
  CanActivate,
  ExecutionContext,
  Logger
} from '@nestjs/common'

/**
 * @description Simply uses a secret bearer key for admin tool management, such as batch uploads
 * @date 2023-09-02 17:48
 */
@Injectable()
export class AdminUtilGuard implements CanActivate {
  constructor(private readonly logger: Logger) {}

  canActivate(
    context: ExecutionContext
  ): boolean | Promise<boolean> | Observable<boolean> {
    const request = context.switchToHttp().getRequest()
    const check =
      request.headers?.authorization ==
      `Bearer ${process.env.ADMIN_UTIL_SECRET}`
    if (!check) {
      this.logger.log(
        'Bearer secret Authorization check failed',
        AdminUtilGuard.name
      )
    }
    return check
  }
}
