import {
  Controller,
  Get,
  InternalServerErrorException,
  Param,
  Post,
  UnauthorizedException,
  UsePipes,
  ValidationPipe
} from '@nestjs/common'
import { NODE_ENV } from './util/node-env.enum'
import { ApiParam } from '@nestjs/swagger'
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

  @Post('util/intentional-error-3823937293729373923732949581/:delay') // random string to "hide" the route on dev/staging
  @ApiParam({ name: 'delay', required: false })
  async throwIntentionalError(@Param('delay') delay = 2000) {
    if (Number.isNaN(Number(delay))) {
      delay = 2000
    }
    await new Promise((resolve) => setTimeout(resolve, Number(delay)))
    if (process.env.NODE_ENV !== NODE_ENV.PRODUCTION) {
      throw new InternalServerErrorException('TEST internal server error')
    }
    return new UnauthorizedException() // will only return this on prod
  }

  @Post('util/non-responsive-endpoint-9436339442720594681156236885') // random string to "hide" the route
  async nonResponsiveEndpoint() {
    if (process.env.NODE_ENV !== NODE_ENV.PRODUCTION) {
      const delay = 3601000
      await new Promise((resolve) => setTimeout(resolve, delay))
      return
    }
    return new UnauthorizedException() // will only return this on prod
  }
}
