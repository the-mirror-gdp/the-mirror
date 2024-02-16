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
import { CreateMaterialInstanceDto } from './dto/create-material-instance.dto'
import { UpdateMaterialInstanceDto } from './dto/update-material-instance.dto'
import { MaterialInstanceService } from './material-instance.service'
import { FirebaseTokenAuthGuard } from '../../auth/auth.guard'
import { ApiCreatedResponse, ApiParam } from '@nestjs/swagger'
import { ApiResponseProperty } from '@nestjs/swagger/dist/decorators/api-property.decorator'
import { MaterialInstance } from './material-instance.schema'
import { MaterialInstanceId, SpaceId } from '../../util/mongo-object-id-helpers'

class MaterialInstanceResponse extends MaterialInstance {
  @ApiResponseProperty()
  _id: string
}

@FirebaseTokenAuthGuard()
@UsePipes(new ValidationPipe({ whitelist: false })) // temporary until we define the shape of the material-instance
@Controller('space/material-instance')
export class MaterialInstanceController {
  constructor(
    private readonly materialInstanceService: MaterialInstanceService
  ) {}

  @Post()
  @ApiCreatedResponse({
    type: MaterialInstanceResponse
  })
  public async create(
    @Body() createMaterialInstanceDto: CreateMaterialInstanceDto
  ) {
    return await this.materialInstanceService.create(createMaterialInstanceDto)
  }

  @Get(':spaceId/:materialInstanceId')
  @ApiParam({ name: 'spaceId', type: 'string', required: true })
  @ApiParam({ name: 'materialInstanceId', type: 'string', required: true })
  public async findOne(
    @Param('spaceId') spaceId: SpaceId,
    @Param('materialInstanceId') materialInstanceId: MaterialInstanceId
  ) {
    return await this.materialInstanceService.findOne(
      spaceId,
      materialInstanceId
    )
  }

  @Patch(':spaceId/:materialInstanceId')
  @ApiParam({ name: 'spaceId', type: 'string', required: true })
  @ApiParam({ name: 'materialInstanceId', type: 'string', required: true })
  public async update(
    @Param('spaceId') spaceId: SpaceId,
    @Param('materialInstanceId') materialInstanceId: MaterialInstanceId,
    @Body() updateMaterialInstanceDto: UpdateMaterialInstanceDto
  ) {
    return await this.materialInstanceService.update(
      spaceId,
      materialInstanceId,
      updateMaterialInstanceDto
    )
  }

  @Delete(':spaceId/:materialInstanceId')
  @ApiParam({ name: 'spaceId', type: 'string', required: true })
  @ApiParam({ name: 'materialInstanceId', type: 'string', required: true })
  public async delete(
    @Param('spaceId') spaceId: SpaceId,
    @Param('materialInstanceId') materialInstanceId: MaterialInstanceId
  ) {
    return await this.materialInstanceService.delete(
      spaceId,
      materialInstanceId
    )
  }
}
