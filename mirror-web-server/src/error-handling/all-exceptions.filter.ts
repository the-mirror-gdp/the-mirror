import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus
} from '@nestjs/common'
import { InjectSentry, SentryService } from '@ntegral/nestjs-sentry'

@Catch()
export default class AllExceptionsFilter implements ExceptionFilter {
  constructor(@InjectSentry() private readonly sentryService: SentryService) {}

  catch(exception: Error, host: ArgumentsHost): void {
    const ctx = host.switchToHttp()
    const response = ctx.getResponse()
    const request = ctx.getRequest()

    if (
      exception?.message &&
      exception.message.toLowerCase().includes('internal server error')
    ) {
      this.sentryService.instance().captureException(exception)
    }

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR

    response.status(status).json({
      statusCode: status,
      message: exception.message,
      path: request.url
    })
  }
}
