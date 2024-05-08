import {
  SpaceId,
  SpaceObjectId,
  UserId
} from './../util/mongo-object-id-helpers'
import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UsePipes,
  ValidationPipe,
  BadRequestException,
  Query
} from '@nestjs/common'
import { SpaceObjectService } from './space-object.service'
import { CreateSpaceObjectDto } from './dto/create-space-object.dto'
import { UpdateSpaceObjectDto } from './dto/update-space-object.dto'
import { FirebaseTokenAuthGuard } from '../auth/auth.guard'
import { SpaceObject, SpaceObjectPublicData } from './space-object.schema'
import {
  ApiCreatedResponse,
  ApiOkResponse,
  ApiParam,
  ApiQuery
} from '@nestjs/swagger'
import {
  ApiProperty,
  ApiResponseProperty
} from '@nestjs/swagger/dist/decorators/api-property.decorator'
import { UserToken } from '../auth/get-user.decorator'
import { TAG_TYPES } from '../tag/models/tag-types.enum'
import { AddTagToSpaceObjectDto } from './dto/add-tag-to-space-object.dto'
import { PaginatedSearchSpaceObjectDto } from './dto/paginated-search-space-object.dto'
import {
  PaginatedResponse,
  PaginationInterface
} from '../util/pagination/pagination.interface'
import { UpdateSpaceObjectTagsDto } from './dto/update-space-object-tags.dto'

class CreateSpaceObjectResponse extends SpaceObject {
  @ApiResponseProperty()
  _id: string
}

export class SpaceObjectPublicDataPaginatedResponse
  extends PaginatedResponse
  implements PaginationInterface
{
  @ApiProperty({ type: [SpaceObjectPublicData] })
  data: SpaceObjectPublicData[]
}

@Controller('space-object')
@FirebaseTokenAuthGuard()
@UsePipes(new ValidationPipe({ whitelist: true }))
export class SpaceObjectController {
  constructor(private readonly spaceObjectService: SpaceObjectService) {}

  /**
   * @deprecated /space-object/space is misleading and doesn't match the pattern of other controllers, so deprecating it. POST /space-object is the preferable route.
   */
  @Post('space')
  @ApiCreatedResponse({
    type: CreateSpaceObjectResponse
  })
  public async create(
    @UserToken('user_id') userId: UserId,
    @Body() createSpaceObjectDto: CreateSpaceObjectDto
  ) {
    return await this.spaceObjectService.createOneWithRolesCheck(
      userId,
      createSpaceObjectDto
    )
  }

  @Post() // /space-object/space is misleading and doesn't match the pattern of other controllers, so deprecating it. POST /space-object is the preferable route.
  @FirebaseTokenAuthGuard()
  @ApiCreatedResponse({
    type: CreateSpaceObjectResponse
  })
  public async createAlias(
    @UserToken('user_id') userId: UserId,
    @Body() createSpaceObjectDto: CreateSpaceObjectDto
  ) {
    return await this.spaceObjectService.createOneWithRolesCheck(
      userId,
      createSpaceObjectDto
    )
  }

  @Post('copy')
  public async copy(
    @UserToken('user_id') userId: UserId,
    @Body() copyDto: { from: SpaceId; to: SpaceId }
  ) {
    return await this.spaceObjectService.copySpaceObjectsToSpaceWithRolesCheck(
      userId,
      copyDto.from,
      copyDto.to
    )
  }
  /**
   * @deprecated This method is deprecated and will be removed in future versions. Use `findAllBySpaceIdWithRolesCheck` instead.
   * @Get('space/:id')
   */
  @Get('space/:id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async findAllBySpaceId(@Param('id') spaceId: SpaceId) {
    if (!spaceId || spaceId == 'undefined') {
      throw new BadRequestException('Invalid spaceId')
    }
    return await this.spaceObjectService.findAllBySpaceIdAdmin(spaceId)
  }

  @Get('space-v2/:id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async findAllBySpaceIdWithRolesCheck(
    @Param('id') spaceId: SpaceId,
    userId: UserId
  ) {
    if (!spaceId || spaceId == 'undefined') {
      throw new BadRequestException('Invalid spaceId')
    }
    return await this.spaceObjectService.findAllBySpaceIdWithRolesCheck(
      spaceId,
      userId
    )
  }

  @Get('tag')
  @ApiOkResponse({ type: SpaceObject })
  public async getSpaceObjectsByTag(
    @Query() searchDto: PaginatedSearchSpaceObjectDto
  ) {
    return await this.spaceObjectService.getSpaceObjectsByTag(searchDto)
  }

  @Patch('tag')
  public async updateSpaceObjectTagsByTypeWithRoleChecks(
    @UserToken('user_id') userId: UserId,
    @Body() updateSpaceObjectTagsDto: UpdateSpaceObjectTagsDto
  ) {
    return await this.spaceObjectService.updateSpaceObjectTagsByTypeWithRoleChecks(
      userId,
      updateSpaceObjectTagsDto
    )
  }

  @Post('tag')
  public async addTagToSpaceObjectWithRoleChecks(
    @UserToken('user_id') userId: UserId,
    @Body() addTagToSpaceObjectDto: AddTagToSpaceObjectDto
  ) {
    return await this.spaceObjectService.addTagToSpaceObjectWithRoleChecks(
      userId,
      addTagToSpaceObjectDto
    )
  }

  @Delete('tag/:spaceObjectId/:tagType/:tagName')
  @ApiParam({ name: 'spaceObjectId', type: 'string', required: true })
  @ApiParam({ name: 'tagType', enum: TAG_TYPES, required: true })
  @ApiParam({ name: 'tagName', type: 'string', required: true })
  public async deleteTagFromSpaceObjectWithRoleChecks(
    @UserToken('user_id') userId: UserId,
    @Param('spaceObjectId') spaceObjectId: SpaceId,
    @Param('tagType') tagType: TAG_TYPES,
    @Param('tagName') tagName: string
  ) {
    return await this.spaceObjectService.deleteTagFromSpaceObjectWithRoleChecks(
      userId,
      spaceObjectId,
      tagName,
      tagType
    )
  }

  @Get('search')
  @ApiQuery({ required: false })
  public async searchSpaceObjectsPaginated(
    @Query() searchDto?: PaginatedSearchSpaceObjectDto
  ) {
    return await this.spaceObjectService.searchSpaceObjectsPaginated(searchDto)
  }

  @Get(':id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async findOne(
    @UserToken('user_id') userId: UserId,
    @Param('id') spaceObjectId: SpaceObjectId
  ) {
    if (!spaceObjectId || spaceObjectId == 'undefined') {
      throw new BadRequestException('Invalid spaceObjectId')
    }
    return await this.spaceObjectService.findOneWithRolesCheck(
      userId,
      spaceObjectId
    )
  }

  @Patch(':id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async update(
    @UserToken('user_id') userId: UserId,
    @Param('id') id: string,
    @Body() updateSpaceObjectDto: UpdateSpaceObjectDto
  ) {
    return await this.spaceObjectService.updateOneWithRolesCheck(
      userId,
      id,
      updateSpaceObjectDto
    )
  }

  @Delete(':id')
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async remove(
    @UserToken('user_id') userId: UserId,
    @Param('id') spaceObjectId: SpaceObjectId
  ) {
    if (!spaceObjectId || spaceObjectId == 'undefined') {
      throw new BadRequestException('Invalid spaceObjectId')
    }
    return await this.spaceObjectService.removeOneWithRolesCheck(
      userId,
      spaceObjectId
    )
  }
}
