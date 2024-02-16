/*
https://docs.nestjs.com/controllers#controllers
*/

import {
  Body,
  Controller,
  Get,
  Patch,
  UseGuards,
  UsePipes,
  ValidationPipe
} from '@nestjs/common'
import { MirrorServerConfigService } from './mirror-server-config.service'
import { GodotServerGuard } from '../godot-server/godot-server.guard'

@Controller('mirror-server-config')
@UsePipes(new ValidationPipe({ whitelist: true }))
@UseGuards(GodotServerGuard)
export class MirrorServerConfigController {
  constructor(
    private readonly mirrorServerConfigService: MirrorServerConfigService
  ) {}

  @Get()
  async getConfig() {
    return await this.mirrorServerConfigService.getConfig()
  }

  @Patch()
  async setGdServerVersion(@Body('gdServerVersion') gdServerVersion: string) {
    return await this.mirrorServerConfigService.setGdServerVersion(
      gdServerVersion
    )
  }
}
