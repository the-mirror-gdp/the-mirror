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
import {
  ApiCreatedResponse,
  ApiNoContentResponse,
  ApiOkResponse,
  ApiParam
} from '@nestjs/swagger'
import { ApiResponseProperty } from '@nestjs/swagger/dist/decorators/api-property.decorator'
import { FirebaseTokenAuthGuard } from '../auth/auth.guard'
import { Block } from './block.schema'
import { BlockService } from './block.service'
import { CreateBlockDto } from './dto/create-block.dto'
import { UpdateBlockDto } from './dto/update-block.dto'

class CreateBlockResponse extends Block {
  @ApiResponseProperty()
  _id: string
}

@FirebaseTokenAuthGuard()
@UsePipes(new ValidationPipe({ whitelist: false }))
@Controller('block')
export class BlockController {
  constructor(private readonly blockService: BlockService) {}

  @Post()
  @ApiCreatedResponse({
    type: CreateBlockResponse
  })
  public async create(@Body() createBlockDto: CreateBlockDto) {
    return await this.blockService.create(createBlockDto)
  }

  @Get(':id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async findOne(@Param('id') id: string) {
    return await this.blockService.findOne(id)
  }

  @Patch(':id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async update(
    @Param('id') id: string,
    @Body() updateAssetDto: UpdateBlockDto
  ) {
    return await this.blockService.update(id, updateAssetDto)
  }

  @Delete(':id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async remove(@Param('id') id: string) {
    return await this.blockService.remove(id)
  }
}
