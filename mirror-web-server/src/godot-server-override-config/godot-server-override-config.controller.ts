import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  UsePipes,
  ValidationPipe,
  NotFoundException,
  Logger
} from '@nestjs/common'
import { CreateGodotServerOverrideConfigDto } from './dto/create-godot-server-override-config.dto'
import { godotServerOverrideControllerPath } from './godot-server-override-config.path'
import {
  FormattedGodotServerOverrideConfigString,
  GodotServerOverrideConfigService
} from './godot-server-override-config.service'
import { ApiParam } from '@nestjs/swagger'

@UsePipes(new ValidationPipe({ whitelist: true }))
@Controller(godotServerOverrideControllerPath)
export class GodotServerOverrideConfigController {
  constructor(
    private readonly logger: Logger,
    private readonly serverOverrideConfigService: GodotServerOverrideConfigService
  ) {}

  @Get(':spaceId')
  @ApiParam({ name: 'spaceId', type: 'string', required: true })
  public async findOne(
    @Param('spaceId') spaceId: string
  ): Promise<FormattedGodotServerOverrideConfigString> {
    // safety: if no id, then return nothing
    if (!spaceId) {
      throw new NotFoundException('No space ID provided')
    }
    // // use a try catch so there will always be a default so that godot server loading won't run into issues
    try {
      return await this.serverOverrideConfigService.findOneFormatted(spaceId)
    } catch (error) {
      // 2023-04-05 17:59:53 should this be error instead of warn?
      this.logger.warn(error, GodotServerOverrideConfigController.name) //TODO - add better logging
      return this.serverOverrideConfigService.getDefaultFormattedStringForServerLogs(
        spaceId
      )
    }
  }

  @Get()
  @ApiParam({ name: 'spaceId', type: 'string', required: true })
  public async findOneAlias(
    @Param('spaceId') spaceId: string
  ): Promise<FormattedGodotServerOverrideConfigString> {
    // safety: if no id, then return nothing
    if (!spaceId) {
      throw new NotFoundException('No space ID provided')
    }
    // // use a try catch so there will always be a default so that godot server loading won't run into issues
    try {
      return await this.serverOverrideConfigService.findOneFormatted(spaceId)
    } catch (error) {
      // 2023-04-05 17:59:53 should this be error instead of warn?
      this.logger.warn(
        error?.message,
        error,
        GodotServerOverrideConfigController.name
      ) //TODO - add better logging
      return this.serverOverrideConfigService.getDefaultFormattedStringForServerLogs(
        spaceId
      )
    }
  }

  @Post()
  public async create(
    @Body() createServerOverrideConfigDto: CreateGodotServerOverrideConfigDto
  ) {
    return await this.serverOverrideConfigService.create(
      createServerOverrideConfigDto
    )
  }
}
