import {
  Controller,
  Get,
  InternalServerErrorException,
  Post,
  UnauthorizedException,
  UsePipes,
  ValidationPipe
} from '@nestjs/common'
import { NODE_ENV } from './util/node-env.enum'
@UsePipes(new ValidationPipe({ whitelist: true }))
@Controller()
export class AppController {
  @Get()
  getHello(): string {
    const version: string = require('../package.json').version
    return `The Mirror v${version}`
  }

  @Get('util/version')
  getHealth(): string {
    const version = require('../package.json').version
    return version
  }

  @Post('util/intentional-error-3823937293729373923732949581') // random string to "hide" the route on dev/staging
  throwIntentionalError() {
    if (process.env.NODE_ENV !== NODE_ENV.PRODUCTION) {
      throw new InternalServerErrorException('TEST internal server error')
    }
    return new UnauthorizedException() // will only return this on prod
  }
}
