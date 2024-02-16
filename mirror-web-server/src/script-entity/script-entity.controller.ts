import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UsePipes,
  ValidationPipe
} from '@nestjs/common'
import { CreateScriptEntityDto } from './dto/create-script-entity.dto'
import { UpdateScriptEntityDto } from './dto/update-script-entity.dto'
import { ScriptEntityService } from './script-entity.service'
import { FirebaseTokenAuthGuard } from '../auth/auth.guard'

import { ApiCreatedResponse, ApiParam } from '@nestjs/swagger'
import { ScriptEntity } from './script-entity.schema'
import { ApiResponseProperty } from '@nestjs/swagger/dist/decorators/api-property.decorator'
import { UserToken } from '../auth/get-user.decorator'
import { UserId } from '../util/mongo-object-id-helpers'

class ScriptEntityResponse extends ScriptEntity {
  @ApiResponseProperty()
  _id: string
}

@FirebaseTokenAuthGuard()
@UsePipes(new ValidationPipe({ whitelist: false })) // temporary until we define the shape of the script entity
@Controller('script-entity')
export class ScriptEntityController {
  constructor(private readonly scriptEntityService: ScriptEntityService) {}

  @Get('recents')
  @FirebaseTokenAuthGuard()
  @ApiCreatedResponse({
    type: [ScriptEntityResponse]
  })
  public async getRecentScripts(@UserToken('user_id') userId: UserId) {
    return await this.scriptEntityService.getRecentScripts(userId)
  }

  @Post()
  @FirebaseTokenAuthGuard()
  @ApiCreatedResponse({
    type: ScriptEntityResponse
  })
  public async create(
    @Body() createScriptEntityDto: CreateScriptEntityDto,
    @UserToken('user_id') userId: UserId
  ) {
    return await this.scriptEntityService.create(userId, createScriptEntityDto)
  }

  @Get(':id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async findOne(@Param('id') id: string) {
    return await this.scriptEntityService.findOne(id)
  }

  @Patch(':id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async update(
    @Param('id') id: string,
    @Body() updateAssetDto: UpdateScriptEntityDto
  ) {
    return await this.scriptEntityService.update(id, updateAssetDto)
  }

  @Delete(':id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async delete(@Param('id') id: string) {
    return await this.scriptEntityService.delete(id)
  }
}
