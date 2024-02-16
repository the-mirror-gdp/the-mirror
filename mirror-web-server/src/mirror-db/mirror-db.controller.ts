import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  UsePipes,
  ValidationPipe
} from '@nestjs/common'
import { ApiParam } from '@nestjs/swagger'
import { MirrorDBRecordId, UserId } from '../util/mongo-object-id-helpers'
import { MirrorDBService } from './mirror-db.service'
import { UpdateMirrorDBRecordDto } from './dto/update-mirror-db-record.dto'
import { FirebaseTokenAuthGuard } from '../auth/auth.guard'
import { UserToken } from '../auth/get-user.decorator'

@Controller('mirror-db')
@UsePipes(new ValidationPipe({ whitelist: true }))
@FirebaseTokenAuthGuard()
export class MirrorDBController {
  constructor(private readonly mirrorDBService: MirrorDBService) {}

  @Get(':id')
  @ApiParam({ name: 'id', type: String, required: true })
  public async getRecordFromMirrorDBById(@Param('id') id: MirrorDBRecordId) {
    return await this.mirrorDBService.getRecordFromMirrorDBById(id)
  }

  @Get('space/:spaceId')
  @ApiParam({ name: 'spaceId', type: String, required: true })
  public async getRecordFromMirrorDBBySpaceId(
    @Param('spaceId') spaceId: string
  ) {
    return await this.mirrorDBService.getRecordFromMirrorDBBySpaceId(spaceId)
  }

  @Get('space-version/:spaceVersionId')
  @ApiParam({ name: 'spaceVersionId', type: String, required: true })
  public async getRecordFromMirrorDBBySpaceVersionId(
    @Param('spaceVersionId') spaceVersionId: string
  ) {
    return await this.mirrorDBService.getRecordFromMirrorDBBySpaceVersionId(
      spaceVersionId
    )
  }

  @Patch(':id')
  @ApiParam({ name: 'id', type: String, required: true })
  public async updateRecordInMirrorDBById(
    @Param('id') id: MirrorDBRecordId,
    @Body() updateMirrorDBRecordDto: UpdateMirrorDBRecordDto,
    @UserToken('user_id') userId: UserId
  ) {
    return await this.mirrorDBService.updateRecordInMirrorDBByIdWithRoleChecks(
      id,
      updateMirrorDBRecordDto,
      userId
    )
  }

  @Delete(':id')
  @ApiParam({ name: 'id', type: String, required: true })
  public async deleteRecordFromMirrorDBById(@Param('id') id: MirrorDBRecordId) {
    return await this.mirrorDBService.deleteRecordFromMirrorDBById(id)
  }
}
