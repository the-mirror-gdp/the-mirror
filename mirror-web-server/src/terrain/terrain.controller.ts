import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UsePipes,
  ValidationPipe
} from '@nestjs/common'
import { ROLE } from '../roles/models/role.enum'
import { Roles } from '../roles/roles.decorator'
import { Terrain } from './terrain.schema'
import { TerrainService } from './terrain.service'
import { UserToken } from '../auth/get-user.decorator'
import { CreateTerrainDto } from './dto/create-terrain.dto'
import { UpdateTerrainDto } from './dto/update-terrain.dto'
import { FirebaseTokenAuthGuard } from '../auth/auth.guard'
import { ApiCreatedResponse, ApiOkResponse, ApiParam } from '@nestjs/swagger'
import { ApiResponseProperty } from '@nestjs/swagger/dist/decorators/api-property.decorator'

class TerrainApiResponse extends Terrain {
  @ApiResponseProperty()
  _id: string
}

@Controller('terrain')
@FirebaseTokenAuthGuard()
@UsePipes(new ValidationPipe({ whitelist: true }))
export class TerrainController {
  constructor(private readonly terrainService: TerrainService) {}

  @Get()
  @ApiOkResponse({ type: [TerrainApiResponse] })
  public async findAllForUser(@UserToken('user_id') userId: string) {
    return await this.terrainService.findAllForUser(userId)
  }

  @Get('public')
  @ApiOkResponse({ type: [TerrainApiResponse] })
  public async findAllPublic() {
    return await this.terrainService.findAllPublic()
  }

  @Get(':id')
  @ApiOkResponse({ type: TerrainApiResponse })
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async findOne(@Param('id') id: string) {
    return await this.terrainService.findOne(id)
  }

  @Post()
  @ApiCreatedResponse({
    type: TerrainApiResponse
  })
  public async create(
    @UserToken('user_id') userId: string,
    @Body() createTerrainDto: CreateTerrainDto
  ) {
    const createTerrainData = Object.assign({}, createTerrainDto, {
      owner: userId // the owner is the requesting user by default
    })
    return await this.terrainService.create(createTerrainData)
  }

  @Patch(':id')
  @ApiOkResponse({ type: TerrainApiResponse })
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async update(
    @Param('id') id: string,
    @Body() updateTerrainDto: UpdateTerrainDto
  ) {
    return await this.terrainService.update(id, updateTerrainDto)
  }

  @Delete(':id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  @ApiOkResponse({ type: TerrainApiResponse })
  public async remove(@Param('id') id: string) {
    return await this.terrainService.remove(id)
  }
}
