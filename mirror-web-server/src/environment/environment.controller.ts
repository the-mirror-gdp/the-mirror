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
import { EnvironmentService } from './environment.service'
import { UpdateEnvironmentDto } from './dto/update-environment.dto'
import { ApiCreatedResponse, ApiOkResponse, ApiParam } from '@nestjs/swagger'
import { EnvironmentApiResponse } from './environment.model'
import { FirebaseTokenAuthGuard } from '../auth/auth.guard'

@Controller('environment')
@FirebaseTokenAuthGuard()
@UsePipes(new ValidationPipe({ whitelist: false })) // TEMP disabled to allow for saving of sky data without structure
export class EnvironmentController {
  constructor(private readonly environmentService: EnvironmentService) {}

  /***********************
   AUTH REQUIRED ENDPOINTS
   **********************/

  @Post()
  @ApiCreatedResponse({ type: EnvironmentApiResponse })
  public create() {
    return this.environmentService.create()
  }

  @Get(':id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  @ApiOkResponse({ type: EnvironmentApiResponse })
  public findOne(@Param('id') id: string) {
    return this.environmentService.findOne(id)
  }

  @Patch(':id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  @ApiOkResponse({ type: EnvironmentApiResponse })
  public update(@Param('id') id: string, @Body() dto: UpdateEnvironmentDto) {
    return this.environmentService.update(id, dto)
  }

  @Delete(':id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  @ApiOkResponse({ type: EnvironmentApiResponse })
  public remove(@Param('id') id: string) {
    return this.environmentService.remove(id)
  }
}
