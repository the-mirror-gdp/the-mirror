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
import { ApiCreatedResponse, ApiParam } from '@nestjs/swagger'
import { ApiResponseProperty } from '@nestjs/swagger/dist/decorators/api-property.decorator'
import { FirebaseTokenAuthGuard } from '../auth/auth.guard'
import { CreateFavoriteDto } from './dto/create-favorite.dto'
import { UpdateFavoriteDto } from './dto/update-favorite.dto'
import { Favorite } from './favorite.schema'
import { FavoriteService } from './favorite.service'

class CreateFavoriteResponse extends Favorite {
  @ApiResponseProperty()
  _id: string
}

@Controller('favorite')
@FirebaseTokenAuthGuard()
@UsePipes(new ValidationPipe({ whitelist: true }))
export class FavoriteController {
  constructor(private readonly favoriteService: FavoriteService) {}

  @Post()
  @ApiCreatedResponse({
    type: CreateFavoriteResponse
  })
  public async create(@Body() createFavoriteDto: CreateFavoriteDto) {
    return await this.favoriteService.create(createFavoriteDto)
  }

  @Get()
  public async findAllForUser(userId: string) {
    return await this.favoriteService.findAllForUser(userId)
  }

  @Get(':id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async findOne(@Param('id') id: string) {
    return await this.favoriteService.findOne(id)
  }

  @Patch(':id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async update(
    @Param('id') id: string,
    @Body() updateFavoriteDto: UpdateFavoriteDto
  ) {
    return await this.favoriteService.update(id, updateFavoriteDto)
  }

  @Delete(':id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async remove(@Param('id') id: string) {
    return await this.favoriteService.remove(id)
  }
}
